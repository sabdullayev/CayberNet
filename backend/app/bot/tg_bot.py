import asyncio
import json
import secrets
from typing import Optional
from aiogram import Bot, Dispatcher, Router, types
from aiogram.client.default import DefaultBotProperties
from aiogram.enums import ParseMode
from aiogram.filters import Command, CommandStart
from app.core.config import settings
from app.core.redis import get_redis_instance

router = Router()

bot_instance: Optional[Bot] = None
dp_instance: Optional[Dispatcher] = None


@router.message(CommandStart())
@router.message(Command("code"))
async def handle_start_or_code(message: types.Message):
    """Handle /start or /code: generate and store 6-digit OTP in Redis with 5 min TTL."""
    if not message.from_user:
        return

    # Generate 6-digit cryptographic code
    code = f"{secrets.randbelow(900000) + 100000}"

    user_info = {
        "telegram_id": message.from_user.id,
        "username": message.from_user.username or f"ronin_tg_{message.from_user.id}",
        "first_name": message.from_user.first_name or "Самурай",
    }

    try:
        redis = await get_redis_instance()
        await redis.set(f"tg_otp:{code}", json.dumps(user_info), ex=300)
    except Exception as e:
        await message.answer(f"⚠️ Ошибка нейросвязи с базой данных: {e}")
        return

    first_name = message.from_user.first_name or "Самурай"
    text = (
        f"⚡ <b>[RONIN NEUROMODEM LINKED]</b>\n\n"
        f"Приветствуем в сети, <b>{first_name}</b>!\n\n"
        f"Твой одноразовый ключ авторизации:\n"
        f"<code>{code}</code>\n\n"
        f"⏳ Срок действия ключа: <b>5 минут</b>.\n"
        f"Введи этот код в приложении <b>RoninNet</b> для входа через Нейромодем."
    )
    await message.answer(text)


async def start_telegram_bot() -> Optional[asyncio.Task]:
    """Start Telegram neuromodem bot in background task if token is configured."""
    global bot_instance, dp_instance

    token = settings.TELEGRAM_BOT_TOKEN.strip()
    if not token:
        print("🤖 [RONIN-BOT] TELEGRAM_BOT_TOKEN not provided. Neuromodem bot is disabled.")
        return None

    try:
        bot_instance = Bot(
            token=token,
            default=DefaultBotProperties(parse_mode=ParseMode.HTML)
        )
        dp_instance = Dispatcher()
        dp_instance.include_router(router)

        # Drop pending updates so old messages won't spam on restart
        await bot_instance.delete_webhook(drop_pending_updates=True)

        print("🤖 [RONIN-BOT] Telegram Neuromodem Bot initialized and starting polling...")
        polling_task = asyncio.create_task(
            dp_instance.start_polling(bot_instance),
            name="ronin_tg_bot_polling"
        )
        return polling_task
    except Exception as e:
        print(f"⚠️  [RONIN-BOT] Failed to start Telegram bot: {e}")
        return None


async def stop_telegram_bot(task: Optional[asyncio.Task] = None) -> None:
    """Gracefully stop Telegram bot and release sessions."""
    global bot_instance, dp_instance

    if dp_instance:
        await dp_instance.stop_polling()

    if task and not task.done():
        task.cancel()
        try:
            await task
        except asyncio.CancelledError:
            pass

    if bot_instance:
        try:
            await bot_instance.session.close()
        except Exception:
            pass
        bot_instance = None
    print("🤖 [RONIN-BOT] Telegram Neuromodem Bot stopped.")
