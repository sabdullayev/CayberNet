import asyncio
import json
from typing import Dict, Optional, Set
from fastapi import WebSocket
from app.core.redis import get_redis_instance


class ConnectionManager:
    """Realtime WebSocket Connection Manager with room tracking and Redis Pub/Sub."""

    def __init__(self):
        # Maps room_id (str) -> set of active WebSockets
        self.active_rooms: Dict[str, Set[WebSocket]] = {}
        # Maps websocket -> user_id (str)
        self.socket_users: Dict[WebSocket, str] = {}
        # Maps websocket -> room_id (str)
        self.socket_rooms: Dict[WebSocket, str] = {}

    def get_online_count(self, room_id: str) -> int:
        """Get unique count of connected users in room."""
        r_id = str(room_id)
        if r_id in self.active_rooms:
            # Set of unique user_ids connected to this room
            users = {
                self.socket_users[s]
                for s in self.active_rooms[r_id]
                if s in self.socket_users
            }
            return max(len(users), len(self.active_rooms[r_id]))
        return 0

    async def connect(self, room_id: str, websocket: WebSocket, user_id: str):
        """Accept WebSocket connection and register into room."""
        await websocket.accept()
        r_id = str(room_id)
        if r_id not in self.active_rooms:
            self.active_rooms[r_id] = set()
        self.active_rooms[r_id].add(websocket)
        self.socket_users[websocket] = str(user_id)
        self.socket_rooms[websocket] = r_id

    def disconnect(self, room_id: str, websocket: WebSocket):
        """Remove WebSocket from room and clean up."""
        r_id = str(room_id)
        if r_id in self.active_rooms and websocket in self.active_rooms[r_id]:
            self.active_rooms[r_id].remove(websocket)
            if not self.active_rooms[r_id]:
                del self.active_rooms[r_id]
        self.socket_users.pop(websocket, None)
        self.socket_rooms.pop(websocket, None)

    async def broadcast_to_room(
        self,
        room_id: str,
        message: dict,
        exclude: Optional[WebSocket] = None
    ):
        """Broadcast JSON payload to all connected sockets in room."""
        r_id = str(room_id)
        if r_id not in self.active_rooms:
            return

        dead_sockets = set()
        payload = json.dumps(message, ensure_ascii=False)

        for socket in list(self.active_rooms[r_id]):
            if exclude is not None and socket == exclude:
                continue
            try:
                await socket.send_text(payload)
            except Exception:
                dead_sockets.add(socket)

        for dead in dead_sockets:
            self.disconnect(r_id, dead)

    async def publish_message(self, room_id: str, message: dict):
        """Publish message across nodes via Redis Pub/Sub, or broadcast locally."""
        r_id = str(room_id)
        redis = await get_redis_instance()
        channel = f"room:{r_id}"
        payload = json.dumps({"room_id": r_id, "data": message}, ensure_ascii=False)
        try:
            if hasattr(redis, "publish"):
                await redis.publish(channel, payload)
            else:
                await self.broadcast_to_room(r_id, message)
        except Exception:
            await self.broadcast_to_room(r_id, message)


ws_manager = ConnectionManager()
