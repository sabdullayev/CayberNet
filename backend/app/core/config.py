import json
from typing import List, Union
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )

    # Core
    PROJECT_NAME: str = "CyberNet Cyber Core"
    DEV_MODE: bool = True
    API_V1_STR: str = "/api/v1"

    # Security & JWT
    SECRET_KEY: str = "cyberpunk_ronin_super_secret_jwt_key_change_in_production_katana"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # PostgreSQL (SQLAlchemy 2.0 Async)
    DATABASE_URL: str = "postgresql+asyncpg://ronin_user:ronin_secret_password@localhost:5432/ronin_db"

    # Redis Cache & Realtime Broker
    REDIS_URL: str = "redis://localhost:6379/0"

    # Telegram Neuromodem Bot
    TELEGRAM_BOT_TOKEN: str = ""

    # CORS Origins
    BACKEND_CORS_ORIGINS: Union[List[str], str] = ["*"]

    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        if isinstance(v, str):
            if v.startswith("[") and v.endswith("]"):
                try:
                    return json.loads(v)
                except Exception:
                    pass
            return [origin.strip() for origin in v.split(",") if origin.strip()]
        elif isinstance(v, list):
            return v
        return ["*"]


settings = Settings()
