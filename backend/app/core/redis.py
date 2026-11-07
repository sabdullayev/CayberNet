import asyncio
import time
from typing import AsyncGenerator, Dict, Optional, Any
import redis.asyncio as aioredis
from app.core.config import settings

redis_client: Optional[aioredis.Redis] = None


class InMemoryDevCache:
    """Fallback in-memory cache for development mode when Redis is not running."""
    def __init__(self):
        self._store: Dict[str, Any] = {}
        self._expiry: Dict[str, float] = {}
        self._lock = asyncio.Lock()

    async def get(self, key: str) -> Optional[str]:
        async with self._lock:
            if key in self._store:
                if key in self._expiry and time.time() > self._expiry[key]:
                    del self._store[key]
                    del self._expiry[key]
                    return None
                return self._store[key]
            return None

    async def set(self, key: str, value: Any, ex: Optional[int] = None) -> bool:
        async with self._lock:
            self._store[key] = str(value)
            if ex:
                self._expiry[key] = time.time() + ex
            elif key in self._expiry:
                del self._expiry[key]
            return True

    async def delete(self, key: str) -> int:
        async with self._lock:
            deleted = 0
            if key in self._store:
                del self._store[key]
                deleted = 1
            if key in self._expiry:
                del self._expiry[key]
            return deleted

    async def ping(self) -> bool:
        return True


dev_memory_cache = InMemoryDevCache()
_using_dev_memory = False


async def init_redis() -> aioredis.Redis:
    """Initialize Redis connection or fall back to dev cache if DEV_MODE."""
    global redis_client, _using_dev_memory
    if redis_client is None:
        try:
            client = aioredis.from_url(
                settings.REDIS_URL,
                encoding="utf-8",
                decode_responses=True,
                socket_connect_timeout=2
            )
            # Test connection
            await client.ping()
            redis_client = client
            _using_dev_memory = False
            print("⚡ [RONIN-REDIS] Connected to Redis instance.")
        except Exception as e:
            if settings.DEV_MODE:
                print(f"⚠️  [RONIN-REDIS] Redis unreachable ({e}). Falling back to DEV In-Memory Cache.")
                _using_dev_memory = True
            else:
                raise e
    return redis_client


async def close_redis() -> None:
    """Close Redis connection."""
    global redis_client
    if redis_client is not None:
        try:
            await redis_client.aclose()
        except Exception:
            pass
        redis_client = None


async def get_redis_instance():
    """Get active Redis client or fallback dev cache."""
    global redis_client, _using_dev_memory
    if redis_client is None and not _using_dev_memory:
        try:
            await init_redis()
        except Exception:
            pass
    if _using_dev_memory or redis_client is None:
        return dev_memory_cache
    return redis_client


async def get_redis():
    """FastAPI dependency to provide Redis client (or dev fallback)."""
    client = await get_redis_instance()
    yield client
