from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db, get_redis
from app.models.user import User
from app.schemas.auth import (
    AuthSuccessResponse,
    CyberIdLoginRequest,
    CyberIdRegisterRequest,
    CyberIdRegisterResponse,
    CyberIdRestoreRequest,
    EmailOtpSendRequest,
    EmailOtpSendResponse,
    EmailOtpVerifyRequest,
    RefreshTokenRequest,
    TelegramVerifyRequest,
    TokenResponse,
)
from app.schemas.user import UserResponse
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Authentication (Cyberpunk Neuromodem)"])


# ------------------------------------------------------------------------------
# 1. Cyber-ID Endpoints
# ------------------------------------------------------------------------------
@router.post(
    "/cyber-id/register",
    response_model=CyberIdRegisterResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Регистрация через Cyber-ID с генерацией 12 киберпанк-слов"
)
async def register_cyber_id(
    data: CyberIdRegisterRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Регистрирует нового самурая:
    - Создает уникальный `cyber_tag` (напр. RONIN#4821)
    - Генерирует 12-словную киберпанк сид-фразу
    - Хэширует пароль и сид-фразу
    - Добавляет пользователя в дефолтную комнату 'Таверна Нео-Токио'
    - Возвращает профиль, токены и 12 слов для бэкапа
    """
    user, tokens, seed_words = await AuthService.register_cyber_id(db, data)
    return CyberIdRegisterResponse(
        user=UserResponse.model_validate(user),
        tokens=tokens,
        seed_phrase=seed_words
    )


@router.post(
    "/cyber-id/login",
    response_model=AuthSuccessResponse,
    summary="Вход по Cyber-Tag или username + пароль"
)
async def login_cyber_id(
    data: CyberIdLoginRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Вход самурая по его Cyber-Tag (например RONIN#4821) или username и паролю.
    """
    user, tokens = await AuthService.login_cyber_id(db, data)
    return AuthSuccessResponse(
        user=UserResponse.model_validate(user),
        tokens=tokens
    )


@router.post(
    "/cyber-id/restore",
    response_model=AuthSuccessResponse,
    summary="Восстановление доступа по 12 киберпанк-словам"
)
async def restore_cyber_id(
    data: CyberIdRestoreRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Восстановление доступа или мгновенная авторизация по 12-словной сид-фразе.
    Опционально можно сразу задать новый пароль.
    """
    user, tokens = await AuthService.restore_cyber_id(db, data)
    return AuthSuccessResponse(
        user=UserResponse.model_validate(user),
        tokens=tokens
    )


# ------------------------------------------------------------------------------
# 2. Email OTP Endpoints
# ------------------------------------------------------------------------------
@router.post(
    "/email/send-code",
    response_model=EmailOtpSendResponse,
    summary="Запрос 6-значного OTP кода на Email"
)
async def send_email_otp(
    data: EmailOtpSendRequest,
    redis=Depends(get_redis)
):
    """
    Генерирует 6-значный одноразовый код, сохраняет в Redis на 5 минут.
    В режиме DEV_MODE код также ярко выводится в консоль сервера.
    """
    result = await AuthService.send_email_otp(redis, data.email)
    return EmailOtpSendResponse(**result)


@router.post(
    "/email/verify",
    response_model=AuthSuccessResponse,
    summary="Вход/регистрация по 6-значному Email коду"
)
async def verify_email_otp(
    data: EmailOtpVerifyRequest,
    db: AsyncSession = Depends(get_db),
    redis=Depends(get_redis)
):
    """
    Проверяет 6-значный код из почты. Если самурай заходит впервые,
    создает аккаунт и автоматически подключает к 'Таверне Нео-Токио'.
    """
    user, tokens = await AuthService.verify_email_otp(db, redis, data.email, data.code)
    return AuthSuccessResponse(
        user=UserResponse.model_validate(user),
        tokens=tokens
    )


# ------------------------------------------------------------------------------
# 3. Telegram Neuromodem Endpoints
# ------------------------------------------------------------------------------
@router.post(
    "/telegram/verify",
    response_model=AuthSuccessResponse,
    summary="Вход/регистрация по коду из Telegram бота"
)
async def verify_telegram_code(
    data: TelegramVerifyRequest,
    db: AsyncSession = Depends(get_db),
    redis=Depends(get_redis)
):
    """
    Проверяет 6-значный код, сгенерированный ботом в Telegram по команде /start.
    Автоматически связывает telegram_id с пользователем или регистрирует нового самурая.
    """
    user, tokens = await AuthService.verify_telegram_code(db, redis, data.code)
    return AuthSuccessResponse(
        user=UserResponse.model_validate(user),
        tokens=tokens
    )


# ------------------------------------------------------------------------------
# 4. Token & Profile Endpoints
# ------------------------------------------------------------------------------
@router.post(
    "/refresh",
    response_model=TokenResponse,
    summary="Обновление JWT Access-токена через Refresh-токен"
)
async def refresh_tokens(
    data: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db)
):
    """Выдает свежую пару токенов по валидному Refresh токену."""
    return await AuthService.refresh_tokens(db, data.refresh_token)


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Получение профиля текущего самурая"
)
async def get_me(
    current_user: User = Depends(get_current_user)
):
    """Возвращает информацию об авторизованном пользователе."""
    return UserResponse.model_validate(current_user)
