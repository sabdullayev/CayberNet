import uuid
from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy import BigInteger, DateTime, Integer, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid,
        primary_key=True,
        default=uuid.uuid4
    )
    cyber_tag: Mapped[str] = mapped_column(
        String(32),
        unique=True,
        index=True,
        nullable=False
    )
    username: Mapped[str] = mapped_column(
        String(64),
        unique=True,
        index=True,
        nullable=False
    )
    password_hash: Mapped[Optional[str]] = mapped_column(
        String(255),
        nullable=True
    )
    seed_phrase_hash: Mapped[Optional[str]] = mapped_column(
        String(255),
        nullable=True,
        index=True
    )
    email: Mapped[Optional[str]] = mapped_column(
        String(255),
        unique=True,
        index=True,
        nullable=True
    )
    telegram_id: Mapped[Optional[int]] = mapped_column(
        BigInteger,
        unique=True,
        index=True,
        nullable=True
    )
    avatar_url: Mapped[Optional[str]] = mapped_column(
        String(512),
        nullable=True
    )
    honor_points: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    # Relationships
    room_memberships: Mapped[List["RoomMember"]] = relationship(
        "RoomMember",
        back_populates="user",
        cascade="all, delete-orphan"
    )
    messages: Mapped[List["Message"]] = relationship(
        "Message",
        back_populates="sender",
        cascade="all, delete-orphan"
    )
