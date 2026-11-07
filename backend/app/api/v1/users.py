from typing import List
import uuid
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.core.redis import get_redis_instance
from app.models.user import User
from app.schemas.user import HonorAwardResponse, UserResponse, UserUpdateRequest, get_samurai_rank

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=UserResponse, summary="Текущий пользователь")
async def get_current_user_profile(
    current_user: User = Depends(get_current_user)
):
    return UserResponse.model_validate(current_user)


@router.patch("/me", response_model=UserResponse, summary="Редактирование профиля текущего пользователя")
async def update_current_user_profile(
    payload: UserUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Обновление позывного (username), cyber_tag или аватара.
    Гарантирует уникальность username и cyber_tag без учета регистра.
    """
    updated = False

    if payload.username is not None:
        new_username = payload.username.strip()
        if len(new_username) < 3 or len(new_username) > 30:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Позывной должен содержать от 3 до 30 символов."
            )
        # Check uniqueness if changed
        if new_username.lower() != current_user.username.lower():
            stmt = select(User).where(
                func.lower(User.username) == new_username.lower(),
                User.id != current_user.id
            )
            res = await db.execute(stmt)
            if res.scalars().first():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Позывной '{new_username}' уже занят другим оператором."
                )
            current_user.username = new_username
            updated = True

    if payload.cyber_tag is not None:
        new_tag = payload.cyber_tag.strip().upper()
        if len(new_tag) < 3 or len(new_tag) > 32:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cyber-Tag должен содержать от 3 до 32 символов."
            )
        # Check uniqueness if changed
        if new_tag.lower() != current_user.cyber_tag.lower():
            stmt = select(User).where(
                func.lower(User.cyber_tag) == new_tag.lower(),
                User.id != current_user.id
            )
            res = await db.execute(stmt)
            if res.scalars().first():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Cyber-Tag '{new_tag}' уже закреплен за другим оператором."
                )
            current_user.cyber_tag = new_tag
            updated = True

    if payload.avatar_url is not None:
        current_user.avatar_url = payload.avatar_url.strip() if payload.avatar_url else None
        updated = True

    if updated:
        await db.commit()
        await db.refresh(current_user)

    return UserResponse.model_validate(current_user)


@router.get("/search", response_model=List[UserResponse], summary="Поиск самураев по Cyber-Tag или имени")
async def search_users(
    query: str = Query(..., min_length=1, description="Поисковый запрос (cyber_tag или username)"),
    limit: int = Query(20, ge=1, le=50),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Поиск самураев по cyber_tag (например, RONIN#4821) или по username.
    """
    clean_query = query.strip()
    stmt = (
        select(User)
        .where(
            or_(
                User.cyber_tag.ilike(f"%{clean_query}%"),
                User.username.ilike(f"%{clean_query}%")
            )
        )
        .limit(limit)
    )
    result = await db.execute(stmt)
    users = result.scalars().all()
    return [UserResponse.model_validate(u) for u in users]


@router.get("/{user_id}", response_model=UserResponse, summary="Поиск самурая по ID")
async def get_user_by_id(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    stmt = select(User).where(User.id == user_id)
    result = await db.execute(stmt)
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Пользователь не найден")
    return UserResponse.model_validate(user)


@router.post("/{user_id}/honor", response_model=HonorAwardResponse, summary="Повысить репутацию пользователя (+1 Rep)")
async def give_honor_to_user(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Начисление +1 очка репутации (honor_points) другому пользователю.
    Защита:
    - Нельзя начислять самому себе.
    - В Redis: голосовать за одного и того же человека можно не чаще 1 раза в сутки (TTL 86400).
    """
    if user_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Пользователь не может повысить репутацию самому себе."
        )

    # Check target user
    stmt = select(User).where(User.id == user_id)
    res = await db.execute(stmt)
    target_user = res.scalars().first()
    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Целевой пользователь не найден в базе данных."
        )

    redis = await get_redis_instance()
    redis_key = f"honor:{current_user.id}:{target_user.id}"

    # Check 24h rate limit
    has_voted = await redis.get(redis_key)
    if has_voted:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Репутация этому пользователю уже повышена за последние 24 часа."
        )

    # Save vote with 24 hours expiry (86400 seconds)
    await redis.set(redis_key, "1", ex=86400)

    # Increment honor points
    target_user.honor_points += 1
    await db.commit()
    await db.refresh(target_user)

    return HonorAwardResponse(
        user_id=target_user.id,
        honor_points=target_user.honor_points,
        rank=get_samurai_rank(target_user.honor_points),
        message=f"Репутация пользователю {target_user.username} успешно повышена (+1 Rep)."
    )
