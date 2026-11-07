import json
from typing import Optional
import uuid
from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.core import database
from app.core.redis import get_redis_instance
from app.core.security import decode_token
from app.models.message import Message
from app.models.user import User
from app.ws.manager import ws_manager

router = APIRouter(tags=["Chat WebSockets"])


@router.websocket("/ws/{room_id}")
async def chat_websocket_endpoint(
    websocket: WebSocket,
    room_id: uuid.UUID,
    token: Optional[str] = Query(None)
):
    """
    WebSocket endpoint for realtime room chat:
    WS /api/v1/ws/{room_id}?token={jwt_token}

    Events supported:
    - Incoming / Outgoing:
        - {"type": "ping"} -> {"type": "pong"}
        - {"type": "online_count", "count": N}
        - {"type": "new_message", "content": "...", "reply_to_id": Optional[str]}
        - {"type": "user_typing", "is_typing": bool}
        - {"type": "delete_message", "message_id": str} -> {"type": "message_deleted", "message_id": str}
    """
    # 1. Validate JWT Token
    if not token:
        protocols = websocket.headers.get("sec-websocket-protocol", "")
        if protocols:
            token = protocols.split(",")[0].strip()

    if not token:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    try:
        payload = decode_token(token)
        if payload.get("type") != "access":
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return
        user_id = uuid.UUID(payload.get("sub"))
    except Exception:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    # Verify user exists in database
    async with database.AsyncSessionLocal() as session:
        user_stmt = select(User).where(User.id == user_id)
        user_res = await session.execute(user_stmt)
        user = user_res.scalars().first()

    if not user:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    room_str = str(room_id)

    # 2. Accept and register connection
    await ws_manager.connect(room_str, websocket, user_id=str(user.id))

    # Broadcast updated online count
    count = ws_manager.get_online_count(room_str)
    await ws_manager.broadcast_to_room(room_str, {
        "type": "online_count",
        "count": count
    })

    # 3. Main Message Loop
    try:
        while True:
            text = await websocket.receive_text()
            if not text:
                continue

            try:
                data = json.loads(text)
            except Exception:
                continue

            event_type = data.get("type")

            # A. Heartbeat (Ping / Pong)
            if event_type == "ping":
                await websocket.send_text(json.dumps({"type": "pong"}))

            # B. Typing Indicator
            elif event_type == "typing":
                is_typing = bool(data.get("is_typing", True))
                await ws_manager.broadcast_to_room(
                    room_str,
                    {
                        "type": "user_typing",
                        "user_id": str(user.id),
                        "username": user.username,
                        "cyber_tag": user.cyber_tag,
                        "is_typing": is_typing,
                    },
                    exclude=websocket,
                )

            # C. New Message
            elif event_type == "new_message":
                content = (data.get("content") or "").strip()
                if not content:
                    continue

                reply_to_str = data.get("reply_to_id")
                reply_to_id = None
                if reply_to_str:
                    try:
                        reply_to_id = uuid.UUID(reply_to_str)
                    except Exception:
                        pass

                async with database.AsyncSessionLocal() as session:
                    new_msg = Message(
                        room_id=room_id,
                        sender_id=user.id,
                        content=content,
                        reply_to_id=reply_to_id,
                    )
                    session.add(new_msg)
                    await session.commit()
                    await session.refresh(new_msg)

                    reply_info = None
                    if reply_to_id:
                        rep_stmt = (
                            select(Message)
                            .where(Message.id == reply_to_id)
                            .options(selectinload(Message.sender))
                        )
                        rep_res = await session.execute(rep_stmt)
                        rep_msg = rep_res.scalars().first()
                        if rep_msg and not rep_msg.is_deleted:
                            reply_info = {
                                "id": str(rep_msg.id),
                                "content": rep_msg.content,
                                "sender_username": rep_msg.sender.username,
                                "sender_cyber_tag": rep_msg.sender.cyber_tag,
                            }

                    message_payload = {
                        "id": str(new_msg.id),
                        "room_id": str(new_msg.room_id),
                        "sender_id": str(new_msg.sender_id),
                        "content": new_msg.content,
                        "reply_to_id": str(new_msg.reply_to_id) if new_msg.reply_to_id else None,
                        "reply_to": reply_info,
                        "sender": {
                            "id": str(user.id),
                            "username": user.username,
                            "cyber_tag": user.cyber_tag,
                            "honor_points": user.honor_points,
                            "avatar_url": user.avatar_url,
                        },
                        "is_deleted": False,
                        "created_at": new_msg.created_at.isoformat(),
                    }

                # Broadcast new message to all in room
                await ws_manager.broadcast_to_room(room_str, {
                    "type": "new_message",
                    "message": message_payload,
                })

            # D. Delete Message (Katana Slash)
            elif event_type == "delete_message":
                target_msg_id = data.get("message_id")
                if not target_msg_id:
                    continue

                try:
                    target_uuid = uuid.UUID(target_msg_id)
                except Exception:
                    continue

                async with database.AsyncSessionLocal() as session:
                    msg_stmt = select(Message).where(Message.id == target_uuid)
                    msg_res = await session.execute(msg_stmt)
                    target_msg = msg_res.scalars().first()

                    # Only the author is permitted to slash their message
                    if target_msg and target_msg.sender_id == user.id:
                        target_msg.is_deleted = True
                        await session.commit()

                        # Broadcast deletion to all members
                        await ws_manager.broadcast_to_room(room_str, {
                            "type": "message_deleted",
                            "message_id": str(target_msg.id),
                        })

            # E. Give Honor (+1 Honor Point in realtime)
            elif event_type == "give_honor":
                target_user_str = data.get("target_user_id")
                if not target_user_str:
                    continue
                try:
                    target_uuid = uuid.UUID(target_user_str)
                except Exception:
                    continue

                if target_uuid == user.id:
                    await websocket.send_text(json.dumps({
                        "type": "error",
                        "message": "Пользователь не может повысить репутацию самому себе."
                    }))
                    continue

                redis = await get_redis_instance()
                redis_key = f"honor:{user.id}:{target_uuid}"
                has_voted = await redis.get(redis_key)
                if has_voted:
                    await websocket.send_text(json.dumps({
                        "type": "error",
                        "message": "Репутация этому пользователю уже повышена за последние 24 часа."
                    }))
                    continue

                await redis.set(redis_key, "1", ex=86400)

                async with database.AsyncSessionLocal() as session:
                    tgt_stmt = select(User).where(User.id == target_uuid)
                    tgt_res = await session.execute(tgt_stmt)
                    tgt_user = tgt_res.scalars().first()
                    if not tgt_user:
                        continue

                    tgt_user.honor_points += 1
                    await session.commit()
                    await session.refresh(tgt_user)
                    new_honor = tgt_user.honor_points

                from app.schemas.user import get_samurai_rank
                await ws_manager.broadcast_to_room(room_str, {
                    "type": "honor_updated",
                    "target_user_id": str(target_uuid),
                    "honor_points": new_honor,
                    "rank": get_samurai_rank(new_honor),
                    "from_user_id": str(user.id),
                    "from_username": user.username,
                })

    except WebSocketDisconnect:
        pass
    finally:
        ws_manager.disconnect(room_str, websocket)
        remaining = ws_manager.get_online_count(room_str)
        await ws_manager.broadcast_to_room(room_str, {
            "type": "online_count",
            "count": remaining,
        })
