from datetime import datetime
from typing import Optional
import uuid
from pydantic import BaseModel, ConfigDict, computed_field


def get_samurai_rank(honor_points: int) -> str:
    if honor_points < 10:
        return "Скиталец Сетки"
    elif honor_points < 50:
        return "Нетраннер"
    elif honor_points < 100:
        return "Кибер-Агент"
    else:
        return "Архитектор Сетки"


class UserBase(BaseModel):
    username: str
    avatar_url: Optional[str] = None


class UserUpdateRequest(BaseModel):
    username: Optional[str] = None
    cyber_tag: Optional[str] = None
    avatar_url: Optional[str] = None


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    cyber_tag: str
    username: str
    email: Optional[str] = None
    telegram_id: Optional[int] = None
    avatar_url: Optional[str] = None
    honor_points: int = 0
    created_at: datetime

    @computed_field
    @property
    def rank(self) -> str:
        return get_samurai_rank(self.honor_points)


class HonorAwardResponse(BaseModel):
    user_id: uuid.UUID
    honor_points: int
    rank: str
    message: str = "Репутация пользователю успешно повышена (+1 Rep)."
