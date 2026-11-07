from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import init_db
from app.core.redis import init_redis, close_redis
from app.bot.tg_bot import start_telegram_bot, stop_telegram_bot
from app.api.v1.api import api_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan: initializes databases, cache, and neuromodem bot."""
    print("==================================================================")
    print("      ⚡ [CYBER NET - CYBERPUNK REALTIME CORE] ⚡               ")
    print("==================================================================")

    # 1. Initialize DB and default room ("Таверна Нео-Токио")
    try:
        await init_db()
        print("🗡️  [LIFESPAN] Database tables ready. Default Global Hub initialized.")
    except Exception as e:
        print(f"⚠️  [LIFESPAN] Database init error: {e}")

    # 2. Initialize Redis
    try:
        await init_redis()
    except Exception as e:
        print(f"⚠️  [LIFESPAN] Redis init error: {e}")

    # 3. Start Telegram Neuromodem Bot if configured
    bot_task = None
    if settings.TELEGRAM_BOT_TOKEN.strip():
        bot_task = await start_telegram_bot()
    else:
        print("🤖 [LIFESPAN] TELEGRAM_BOT_TOKEN is empty. Neuromodem bot disabled.")

    print("🟢 [LIFESPAN] RoninNet Cyber Core is fully operational.")
    print("==================================================================")

    yield

    # Shutdown sequence
    print("\n==================================================================")
    print("🔌 [SHUTDOWN] Severing neural connections...")
    if bot_task:
        await stop_telegram_bot(bot_task)
    await close_redis()
    print("💤 [SHUTDOWN] RoninNet offline.")
    print("==================================================================")


app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Cyberpunk Samurai Realtime Messenger Backend (RoninNet MVP)",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS Middleware
if settings.BACKEND_CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.BACKEND_CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# Include API v1 router
app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/", tags=["Health"])
async def root():
    return {
        "network": "CyberNet Cyber Core",
        "status": "ONLINE",
        "lore": "Добро пожаловать в CyberNet, оператор."
    }


@app.get("/health", tags=["Health"])
async def health_check():
    return {
        "status": "online",
        "system": settings.PROJECT_NAME,
        "dev_mode": settings.DEV_MODE
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
