from typing import List, Optional, Union
from pydantic import BaseModel, EmailStr, Field
from app.schemas.user import UserResponse


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    sub: Optional[str] = None
    type: Optional[str] = None


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class AuthSuccessResponse(BaseModel):
    user: UserResponse
    tokens: TokenResponse


# 1. Cyber-ID Schemas
class CyberIdRegisterRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=32, description="Имя пользователя/позывной")
    password: str = Field(..., min_length=6, max_length=128, description="Пароль доступа")


class CyberIdRegisterResponse(BaseModel):
    user: UserResponse
    tokens: TokenResponse
    seed_phrase: List[str] = Field(..., description="12-словная киберпанк сид-фраза для восстановления")


class CyberIdLoginRequest(BaseModel):
    identifier: str = Field(..., description="Cyber-Tag (например, RONIN#4821) или username")
    password: str = Field(..., min_length=1, description="Пароль доступа")


class CyberIdRestoreRequest(BaseModel):
    seed_phrase: Union[str, List[str]] = Field(..., description="12 слов через пробел или список слов")
    new_password: Optional[str] = Field(None, min_length=6, description="Новый пароль (опционально)")


# 2. Email OTP Schemas
class EmailOtpSendRequest(BaseModel):
    email: EmailStr = Field(..., description="Почтовый адрес")


class EmailOtpSendResponse(BaseModel):
    message: str
    email: str
    dev_code: Optional[str] = None


class EmailOtpVerifyRequest(BaseModel):
    email: EmailStr = Field(..., description="Почтовый адрес")
    code: str = Field(..., min_length=6, max_length=6, description="6-значный одноразовый OTP код")


# 3. Telegram Neuromodem Schemas
class TelegramVerifyRequest(BaseModel):
    code: str = Field(..., min_length=6, max_length=6, description="6-значный код из Telegram бота")
