from datetime import datetime
from typing import List, Optional
import uuid
from pydantic import BaseModel, ConfigDict, Field
from app.models.room import RoomType


class RoomBase(BaseModel):
    name: str
    type: RoomType = RoomType.GLOBAL


class RoomCreate(RoomBase):
    pass


class RoomCreateGroupRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=64, description="Название группы / синдиката")
    description: Optional[str] = Field(None, max_length=256, description="Описание синдиката")
    member_ids: Optional[List[uuid.UUID]] = Field(default_factory=list, description="UUID участников")


class RoomCreateChannelRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=64, description="Название нейро-канала")
    description: Optional[str] = Field(None, max_length=256, description="Описание канала")


class RoomResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    type: RoomType
    created_at: datetime


class RoomGlobalResponse(RoomResponse):
    online_count: int = 0


class LastMessageInfo(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    sender_id: uuid.UUID
    content: str
    is_deleted: bool
    created_at: datetime
    sender_username: Optional[str] = None


class InterlocutorInfo(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    username: str
    cyber_tag: str
    avatar_url: Optional[str] = None
    honor_points: int = 0
    rank: str = "Бродяга"


class RoomItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    type: RoomType
    created_at: datetime
    interlocutor: Optional[InterlocutorInfo] = None
    last_message: Optional[LastMessageInfo] = None
    online_count: Optional[int] = None
