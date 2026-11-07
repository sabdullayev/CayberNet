import uuid
from typing import AsyncGenerator
from sqlalchemy import select
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase
from app.core.config import settings


class Base(DeclarativeBase):
    """Base model for all SQLAlchemy 2.0 models."""
    pass


# Primary Async Engine (PostgreSQL via asyncpg)
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    future=True,
    pool_pre_ping=True
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
)


async def init_db() -> None:
    """Initialize database tables and create default Global Hub room if missing."""
    global engine, AsyncSessionLocal

    # Import models so Base.metadata contains all tables
    import app.models  # noqa: F401
    from app.models.room import Room, RoomType

    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
    except Exception as e:
        if settings.DEV_MODE:
            print(f"⚠️  [RONIN-DB] Failed connecting to PostgreSQL ({e}).")
            print("🗡️  [RONIN-DB] Falling back to Dev SQLite engine (sqlite+aiosqlite:///./ronin_dev.db)...")
            engine = create_async_engine(
                "sqlite+aiosqlite:///./ronin_dev.db",
                echo=False,
                future=True
            )
            AsyncSessionLocal = async_sessionmaker(
                bind=engine,
                class_=AsyncSession,
                autocommit=False,
                autoflush=False,
                expire_on_commit=False,
            )
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
        else:
            raise e

    # Create default global room: "Таверна Нео-Токио" (Global Hub)
    async with AsyncSessionLocal() as session:
        stmt = select(Room).where(Room.type == RoomType.GLOBAL)
        result = await session.execute(stmt)
        global_room = result.scalars().first()

        if not global_room:
            global_room = Room(
                name="Таверна Нео-Токио",
                type=RoomType.GLOBAL,
            )
            session.add(global_room)
            await session.commit()
            print("🏮 [RONIN-DB] Created default global room: 'Таверна Нео-Токио' (Global Hub)")
        else:
            print(f"🏮 [RONIN-DB] Global Hub found: '{global_room.name}' (ID: {global_room.id})")


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency for obtaining async database session."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
