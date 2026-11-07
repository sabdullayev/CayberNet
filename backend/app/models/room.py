import enum
import uuid
from datetime import datetime, timezone
from typing import List
from sqlalchemy import DateTime, Enum, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class RoomType(str, enum.Enum):
    GLOBAL = "global"
    DIRECT = "direct"
    GROUP = "group"
    CHANNEL = "channel"


class Room(Base):
    __tablename__ = "rooms"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid,
        primary_key=True,
        default=uuid.uuid4
    )
    type: Mapped[RoomType] = mapped_column(
        Enum(RoomType, name="room_type_enum"),
        default=RoomType.GLOBAL,
        nullable=False
    )
    name: Mapped[str] = mapped_column(
        String(128),
        nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    # Relationships
    members: Mapped[List["RoomMember"]] = relationship(
        "RoomMember",
        back_populates="room",
        cascade="all, delete-orphan"
    )
    messages: Mapped[List["Message"]] = relationship(
        "Message",
        back_populates="room",
        cascade="all, delete-orphan"
    )
