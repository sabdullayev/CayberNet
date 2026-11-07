from typing import List, Optional
import uuid
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import distinct, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_current_user, get_db
from app.models.message import Message
from app.models.room import Room, RoomType
from app.models.room_member import RoomMember
from app.models.user import User
from app.schemas.message import ChatMessageResponse, ReplyMessageInfo, SenderInfo
from app.schemas.room import (
    InterlocutorInfo,
    LastMessageInfo,
    RoomCreateChannelRequest,
    RoomCreateGroupRequest,
    RoomGlobalResponse,
    RoomItemResponse,
    RoomResponse,
)
from app.schemas.user import get_samurai_rank
from app.ws.manager import ws_manager

router = APIRouter(prefix="/rooms", tags=["Rooms"])


@router.get("/", response_model=List[RoomResponse], summary="Список комнат самурая (базовый)")
async def get_user_rooms(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Возвращает список всех комнат (глобальных и тех, в которых состоит пользователь)."""
    stmt = (
        select(Room)
        .outerjoin(RoomMember, Room.id == RoomMember.room_id)
        .where((Room.type == RoomType.GLOBAL) | (RoomMember.user_id == current_user.id))
        .distinct()
    )
    result = await db.execute(stmt)
    rooms = result.scalars().all()
    return [RoomResponse.model_validate(r) for r in rooms]


@router.get(
    "/global",
    response_model=RoomGlobalResponse,
    summary="Получить дефолтный Global Hub с количеством самураев онлайн"
)
async def get_global_room(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Возвращает данные о 'Таверне Нео-Токио' и текущем онлайне."""
    stmt = select(Room).where(Room.type == RoomType.GLOBAL)
    result = await db.execute(stmt)
    room = result.scalars().first()
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Глобальная комната не найдена."
        )

    online_count = ws_manager.get_online_count(str(room.id))

    return RoomGlobalResponse(
        id=room.id,
        name=room.name,
        type=room.type,
        created_at=room.created_at,
        online_count=online_count,
    )


@router.post(
    "/direct/{target_user_id}",
    response_model=RoomItemResponse,
    summary="Создать или открыть личный канал (Direct Room) с самураем"
)
async def get_or_create_direct_room(
    target_user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Ищет существующую комнату типа 'direct' между текущим юзером и target_user_id.
    Если её нет — создает новую комнату, добавляет обоих в RoomMember и возвращает
    её данные (включая профиль собеседника и последнее сообщение).
    """
    if target_user_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Пользователь не может открыть личный канал с самим собой."
        )

    # Check target user exists
    target_stmt = select(User).where(User.id == target_user_id)
    target_res = await db.execute(target_stmt)
    target_user = target_res.scalars().first()
    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Целевой пользователь не найден в базе данных."
        )

    # Search existing direct room where both users are members
    find_stmt = (
        select(Room)
        .join(RoomMember, Room.id == RoomMember.room_id)
        .where(Room.type == RoomType.DIRECT)
        .where(RoomMember.user_id.in_([current_user.id, target_user_id]))
        .group_by(Room.id)
        .having(func.count(distinct(RoomMember.user_id)) == 2)
    )
    find_res = await db.execute(find_stmt)
    room = find_res.scalars().first()

    if not room:
        # Create new direct room
        room = Room(
            name=f"Канал: {current_user.username} - {target_user.username}",
            type=RoomType.DIRECT
        )
        db.add(room)
        await db.flush()

        m1 = RoomMember(room_id=room.id, user_id=current_user.id)
        m2 = RoomMember(room_id=room.id, user_id=target_user.id)
        db.add_all([m1, m2])
        await db.commit()
        await db.refresh(room)

    # Fetch last message
    msg_stmt = (
        select(Message)
        .where(Message.room_id == room.id)
        .options(selectinload(Message.sender))
        .order_by(Message.created_at.desc())
        .limit(1)
    )
    msg_res = await db.execute(msg_stmt)
    last_msg = msg_res.scalars().first()

    last_msg_info = None
    if last_msg:
        last_msg_info = LastMessageInfo(
            id=last_msg.id,
            sender_id=last_msg.sender_id,
            content=last_msg.content,
            is_deleted=last_msg.is_deleted,
            created_at=last_msg.created_at,
            sender_username=last_msg.sender.username if last_msg.sender else None,
        )

    interlocutor_info = InterlocutorInfo(
        id=target_user.id,
        username=target_user.username,
        cyber_tag=target_user.cyber_tag,
        avatar_url=target_user.avatar_url,
        honor_points=target_user.honor_points,
        rank=get_samurai_rank(target_user.honor_points),
    )

    return RoomItemResponse(
        id=room.id,
        name=f"Канал: {target_user.username}",
        type=room.type,
        created_at=room.created_at,
        interlocutor=interlocutor_info,
        last_message=last_msg_info,
        online_count=ws_manager.get_online_count(str(room.id)),
    )


@router.post(
    "/group",
    response_model=RoomItemResponse,
    summary="Создать новую кибер-группу (Синдикат)"
)
async def create_group_room(
    request: RoomCreateGroupRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Создает группу (Синдикат), добавляет создателя и указанных участников."""
    room = Room(
        name=request.name.strip(),
        type=RoomType.GROUP
    )
    db.add(room)
    await db.flush()

    members = [RoomMember(room_id=room.id, user_id=current_user.id)]
    if request.member_ids:
        for mid in request.member_ids:
            if mid != current_user.id:
                # verify user exists
                u_check = await db.execute(select(User.id).where(User.id == mid))
                if u_check.scalar_one_or_none():
                    members.append(RoomMember(room_id=room.id, user_id=mid))

    db.add_all(members)
    await db.commit()
    await db.refresh(room)

    return RoomItemResponse(
        id=room.id,
        name=room.name,
        type=room.type,
        created_at=room.created_at,
        interlocutor=None,
        last_message=None,
        online_count=ws_manager.get_online_count(str(room.id)),
    )


@router.post(
    "/channel",
    response_model=RoomItemResponse,
    summary="Создать новый нейро-канал (Бродкаст)"
)
async def create_channel_room(
    request: RoomCreateChannelRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Создает публичный инфо-канал (Бродкаст)."""
    room = Room(
        name=request.name.strip(),
        type=RoomType.CHANNEL
    )
    db.add(room)
    await db.flush()

    db.add(RoomMember(room_id=room.id, user_id=current_user.id))
    await db.commit()
    await db.refresh(room)

    return RoomItemResponse(
        id=room.id,
        name=room.name,
        type=room.type,
        created_at=room.created_at,
        interlocutor=None,
        last_message=None,
        online_count=ws_manager.get_online_count(str(room.id)),
    )


@router.post(
    "/{room_id}/join",
    summary="Подключиться к группе или каналу"
)
async def join_room(
    room_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Вход самурая в группу или подписка на канал."""
    room_stmt = select(Room).where(Room.id == room_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalars().first()
    if not room:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Комната не найдена.")

    member_stmt = select(RoomMember).where(
        RoomMember.room_id == room_id,
        RoomMember.user_id == current_user.id
    )
    m_res = await db.execute(member_stmt)
    if not m_res.scalars().first():
        db.add(RoomMember(room_id=room.id, user_id=current_user.id))
        await db.commit()

    return {"message": "Подключение к узлу успешно", "room_id": str(room.id)}


@router.get(
    "/my",
    response_model=List[RoomItemResponse],
    summary="Список всех комнат текущего самурая (Global Hub, Direct, Группы, Каналы)"
)
async def get_my_rooms(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Возвращает список всех комнат текущего самурая:
    1. Global Hub ("Таверна Нео-Токио")
    2. Все Direct чаты
    3. Кибер-группы (Синдикаты)
    4. Нейро-каналы (Бродкасты)
    Отсортированы по времени последней активности.
    """
    # 1. Global Hub
    stmt_global = select(Room).where(Room.type == RoomType.GLOBAL)
    res_global = await db.execute(stmt_global)
    global_room = res_global.scalars().first()

    global_item: Optional[RoomItemResponse] = None
    if global_room:
        g_msg_stmt = (
            select(Message)
            .where(Message.room_id == global_room.id)
            .options(selectinload(Message.sender))
            .order_by(Message.created_at.desc())
            .limit(1)
        )
        g_res = await db.execute(g_msg_stmt)
        g_last = g_res.scalars().first()
        g_last_info = None
        if g_last:
            g_last_info = LastMessageInfo(
                id=g_last.id,
                sender_id=g_last.sender_id,
                content=g_last.content,
                is_deleted=g_last.is_deleted,
                created_at=g_last.created_at,
                sender_username=g_last.sender.username if g_last.sender else None,
            )

        global_item = RoomItemResponse(
            id=global_room.id,
            name=global_room.name,
            type=global_room.type,
            created_at=global_room.created_at,
            interlocutor=None,
            last_message=g_last_info,
            online_count=ws_manager.get_online_count(str(global_room.id)),
        )

    # 2. Direct rooms where current_user is a member
    stmt_direct = (
        select(Room)
        .join(RoomMember, Room.id == RoomMember.room_id)
        .where(Room.type == RoomType.DIRECT, RoomMember.user_id == current_user.id)
    )
    res_direct = await db.execute(stmt_direct)
    direct_rooms = res_direct.scalars().all()

    other_items = []
    for d_room in direct_rooms:
        # Find interlocutor
        other_stmt = (
            select(User)
            .join(RoomMember, User.id == RoomMember.user_id)
            .where(RoomMember.room_id == d_room.id, User.id != current_user.id)
        )
        other_res = await db.execute(other_stmt)
        other_user = other_res.scalars().first()
        if not other_user:
            continue

        # Last message
        d_msg_stmt = (
            select(Message)
            .where(Message.room_id == d_room.id)
            .options(selectinload(Message.sender))
            .order_by(Message.created_at.desc())
            .limit(1)
        )
        d_res = await db.execute(d_msg_stmt)
        d_last = d_res.scalars().first()

        d_last_info = None
        if d_last:
            d_last_info = LastMessageInfo(
                id=d_last.id,
                sender_id=d_last.sender_id,
                content=d_last.content,
                is_deleted=d_last.is_deleted,
                created_at=d_last.created_at,
                sender_username=d_last.sender.username if d_last.sender else None,
            )

        interlocutor = InterlocutorInfo(
            id=other_user.id,
            username=other_user.username,
            cyber_tag=other_user.cyber_tag,
            avatar_url=other_user.avatar_url,
            honor_points=other_user.honor_points,
            rank=get_samurai_rank(other_user.honor_points),
        )

        sort_time = d_last.created_at if d_last else d_room.created_at

        other_items.append((
            sort_time,
            RoomItemResponse(
                id=d_room.id,
                name=f"Канал: {other_user.username}",
                type=d_room.type,
                created_at=d_room.created_at,
                interlocutor=interlocutor,
                last_message=d_last_info,
                online_count=ws_manager.get_online_count(str(d_room.id)),
            )
        ))

    # 3. Groups and Channels where current_user is a member (or public channels)
    stmt_groups_channels = (
        select(Room)
        .outerjoin(RoomMember, Room.id == RoomMember.room_id)
        .where(
            (Room.type == RoomType.GROUP) & (RoomMember.user_id == current_user.id)
            | (Room.type == RoomType.CHANNEL)
        )
        .distinct()
    )
    res_gc = await db.execute(stmt_groups_channels)
    gc_rooms = res_gc.scalars().all()

    for gc_room in gc_rooms:
        gc_msg_stmt = (
            select(Message)
            .where(Message.room_id == gc_room.id)
            .options(selectinload(Message.sender))
            .order_by(Message.created_at.desc())
            .limit(1)
        )
        gc_msg_res = await db.execute(gc_msg_stmt)
        gc_last = gc_msg_res.scalars().first()

        gc_last_info = None
        if gc_last:
            gc_last_info = LastMessageInfo(
                id=gc_last.id,
                sender_id=gc_last.sender_id,
                content=gc_last.content,
                is_deleted=gc_last.is_deleted,
                created_at=gc_last.created_at,
                sender_username=gc_last.sender.username if gc_last.sender else None,
            )

        sort_time = gc_last.created_at if gc_last else gc_room.created_at

        other_items.append((
            sort_time,
            RoomItemResponse(
                id=gc_room.id,
                name=gc_room.name,
                type=gc_room.type,
                created_at=gc_room.created_at,
                interlocutor=None,
                last_message=gc_last_info,
                online_count=ws_manager.get_online_count(str(gc_room.id)),
            )
        ))

    # Sort all non-global rooms by sort_time descending
    other_items.sort(key=lambda x: x[0], reverse=True)

    result_list = []
    if global_item:
        result_list.append(global_item)
    for _, item in other_items:
        result_list.append(item)

    return result_list


@router.get(
    "/{room_id}/messages",
    response_model=List[ChatMessageResponse],
    summary="История сообщений комнаты с курсорной пагинацией"
)
async def get_room_messages(
    room_id: uuid.UUID,
    limit: int = Query(50, ge=1, le=100),
    before_id: Optional[uuid.UUID] = Query(None, description="Cursor: ID сообщения для загрузки более старых"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Возвращает историю сообщений комнаты:
    - Курсорная пагинация по before_id
    - Данные отправителя (username, cyber_tag, honor_points)
    - Данные цитируемого сообщения (reply_to)
    - Сортировка: хронологическая (от старых к новым)
    """
    room_stmt = select(Room).where(Room.id == room_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalars().first()
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Комната не найдена."
        )

    stmt = (
        select(Message)
        .where(Message.room_id == room_id)
        .options(
            selectinload(Message.sender),
            selectinload(Message.reply_to).selectinload(Message.sender)
        )
    )

    if before_id:
        cursor_stmt = select(Message.created_at).where(Message.id == before_id)
        cursor_res = await db.execute(cursor_stmt)
        cursor_time = cursor_res.scalar_one_or_none()
        if cursor_time:
            stmt = stmt.where(Message.created_at < cursor_time)

    stmt = stmt.order_by(Message.created_at.desc()).limit(limit)
    result = await db.execute(stmt)
    messages = list(result.scalars().all())

    messages.reverse()

    chat_messages = []
    for msg in messages:
        reply_info = None
        if msg.reply_to and not msg.reply_to.is_deleted:
            reply_info = ReplyMessageInfo(
                id=msg.reply_to.id,
                content=msg.reply_to.content,
                sender_username=msg.reply_to.sender.username,
                sender_cyber_tag=msg.reply_to.sender.cyber_tag,
            )

        sender_info = SenderInfo(
            id=msg.sender.id,
            username=msg.sender.username,
            cyber_tag=msg.sender.cyber_tag,
            honor_points=msg.sender.honor_points,
            avatar_url=msg.sender.avatar_url,
        )

        chat_messages.append(
            ChatMessageResponse(
                id=msg.id,
                room_id=msg.room_id,
                sender_id=msg.sender_id,
                content=msg.content,
                reply_to_id=msg.reply_to_id,
                reply_to=reply_info,
                sender=sender_info,
                is_deleted=msg.is_deleted,
                created_at=msg.created_at,
            )
        )

    return chat_messages
