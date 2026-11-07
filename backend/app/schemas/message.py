from datetime import datetime
from typing import Optional
import uuid
from pydantic import BaseModel, ConfigDict


class MessageCreate(BaseModel):
    room_id: uuid.UUID
    content: str
    reply_to_id: Optional[uuid.UUID] = None


class SenderInfo(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    username: str
    cyber_tag: str
    honor_points: int = 0
    avatar_url: Optional[str] = None


class ReplyMessageInfo(BaseModel):
    id: uuid.UUID
    content: str
    sender_username: str
    sender_cyber_tag: str


class ChatMessageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    room_id: uuid.UUID
    sender_id: uuid.UUID
    content: str
    reply_to_id: Optional[uuid.UUID] = None
    reply_to: Optional[ReplyMessageInfo] = None
    sender: SenderInfo
    is_deleted: bool = False
    created_at: datetime


class MessageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    room_id: uuid.UUID
    sender_id: uuid.UUID
    content: str
    reply_to_id: Optional[uuid.UUID] = None
    is_deleted: bool
    created_at: datetime
