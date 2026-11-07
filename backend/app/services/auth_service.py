import json
import secrets
import uuid
from typing import List, Optional, Tuple, Union
from fastapi import HTTPException, status
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.cyber_words import generate_seed_phrase, hash_seed_phrase
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    generate_cyber_tag,
    hash_password,
    verify_password,
)
from app.models.room import Room, RoomType
from app.models.room_member import RoomMember
from app.models.user import User
from app.schemas.auth import (
    CyberIdLoginRequest,
    CyberIdRegisterRequest,
    CyberIdRestoreRequest,
    TokenResponse,
)


class AuthService:
    """Service handling all three cyberpunk authentication flows."""

    @staticmethod
    async def join_global_hub_if_not_joined(db: AsyncSession, user_id: uuid.UUID) -> None:
        """Ensure the user is enrolled in the default 'Таверна Нео-Токио' global room."""
        try:
            stmt = select(Room).where(Room.type == RoomType.GLOBAL)
            result = await db.execute(stmt)
            global_room = result.scalars().first()
            if not global_room:
                return

            member_stmt = select(RoomMember).where(
                RoomMember.room_id == global_room.id,
                RoomMember.user_id == user_id
            )
            member_res = await db.execute(member_stmt)
            if not member_res.scalars().first():
                db.add(RoomMember(room_id=global_room.id, user_id=user_id))
                await db.commit()
        except Exception as e:
            await db.rollback()
            print(f"⚠️  [RONIN-AUTH] Failed to auto-join Global Hub: {e}")

    @classmethod
    async def _generate_unique_cyber_tag(cls, db: AsyncSession, base: str = "RONIN") -> str:
        """Generate a guaranteed unique cyber_tag."""
        for _ in range(20):
            tag = generate_cyber_tag(base)
            stmt = select(User).where(User.cyber_tag == tag)
            res = await db.execute(stmt)
            if not res.scalars().first():
                return tag
        return f"RONIN#{secrets.randbelow(900000) + 100000}"

    @classmethod
    async def _resolve_unique_username(cls, db: AsyncSession, preferred: str) -> str:
        """Resolve collisions for usernames by appending random numeric suffix if needed."""
        clean = "".join(c for c in preferred if c.isalnum() or c in ("_", "-"))[:28] or "ronin"
        username = clean
        stmt = select(User).where(User.username == username)
        res = await db.execute(stmt)
        if not res.scalars().first():
            return username

        for _ in range(10):
            candidate = f"{clean}_{secrets.randbelow(9000) + 1000}"
            stmt = select(User).where(User.username == candidate)
            res = await db.execute(stmt)
            if not res.scalars().first():
                return candidate
        return f"{clean}_{secrets.token_hex(3)}"

    @classmethod
    def _create_tokens_for_user(cls, user: User) -> TokenResponse:
        """Generate Access and Refresh JWT tokens."""
        claims = {
            "cyber_tag": user.cyber_tag,
            "username": user.username,
        }
        access = create_access_token(subject=str(user.id), claims=claims)
        refresh = create_refresh_token(subject=str(user.id))
        return TokenResponse(access_token=access, refresh_token=refresh)

    # --------------------------------------------------------------------------
    # 1. Cyber-ID Authentication
    # --------------------------------------------------------------------------
    @classmethod
    async def register_cyber_id(
        cls,
        db: AsyncSession,
        request: CyberIdRegisterRequest
    ) -> Tuple[User, TokenResponse, List[str]]:
        """Register via Cyber-ID with 12 cyberpunk seed words."""
        clean_username = request.username.strip()
        clean_password = request.password.strip()

        # 1. Check if username taken (case-insensitive)
        stmt = select(User).where(func.lower(User.username) == func.lower(clean_username))
        res = await db.execute(stmt)
        if res.scalars().first():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Самурай с таким позывным (username) уже существует в сети."
            )

        # 2. Generate unique Cyber-Tag
        cyber_tag = await cls._generate_unique_cyber_tag(db, clean_username)

        # 3. Generate 12 Cyberpunk Seed Words
        seed_words = generate_seed_phrase(12)
        seed_hash = hash_seed_phrase(seed_words)

        # 4. Hash password
        pwd_hash = hash_password(clean_password)

        # 5. Persist user
        user = User(
            username=clean_username,
            cyber_tag=cyber_tag,
            password_hash=pwd_hash,
            seed_phrase_hash=seed_hash,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

        # 6. Auto-join global room
        await cls.join_global_hub_if_not_joined(db, user.id)

        tokens = cls._create_tokens_for_user(user)
        return user, tokens, seed_words

    @classmethod
    async def login_cyber_id(
        cls,
        db: AsyncSession,
        request: CyberIdLoginRequest
    ) -> Tuple[User, TokenResponse]:
        """Login using cyber_tag (e.g. RONIN#4821) or username + password (case-insensitive)."""
        ident = request.identifier.strip()
        clean_password = request.password.strip()

        stmt = select(User).where(
            or_(
                func.lower(User.cyber_tag) == func.lower(ident),
                func.lower(User.username) == func.lower(ident),
            )
        )
        res = await db.execute(stmt)
        user = res.scalars().first()

        if not user or not user.password_hash:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Неверный Cyber-ID/позывной или пароль."
            )

        if not verify_password(clean_password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Неверный Cyber-ID/позывной или пароль."
            )

        await cls.join_global_hub_if_not_joined(db, user.id)
        tokens = cls._create_tokens_for_user(user)
        return user, tokens

    @classmethod
    async def restore_cyber_id(
        cls,
        db: AsyncSession,
        request: CyberIdRestoreRequest
    ) -> Tuple[User, TokenResponse]:
        """Recover access using 12 cyberpunk seed words."""
        computed_hash = hash_seed_phrase(request.seed_phrase)
        stmt = select(User).where(User.seed_phrase_hash == computed_hash)
        res = await db.execute(stmt)
        user = res.scalars().first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Самурай с такой сид-фразой не найден в реестре RoninNet."
            )

        if request.new_password:
            user.password_hash = hash_password(request.new_password)
            db.add(user)
            await db.commit()
            await db.refresh(user)

        tokens = cls._create_tokens_for_user(user)
        return user, tokens

    # --------------------------------------------------------------------------
    # 2. Email OTP Authentication
    # --------------------------------------------------------------------------
    @classmethod
    async def send_email_otp(cls, redis, email: str) -> dict:
        """Send 6-digit OTP code to email (with dev console output in DEV_MODE)."""
        code = f"{secrets.randbelow(900000) + 100000}"
        # Store in Redis with 5 min (300 sec) TTL
        await redis.set(f"email_otp:{email.lower()}", code, ex=300)

        # Output to console for quick developer feedback
        if settings.DEV_MODE:
            print("\n" + "=" * 60)
            print("⚡ [RONIN NET NEUROLINK] EMAIL OTP AUTH CODE")
            print(f"🗡️  Recipient:  {email}")
            print(f"🔑 OTP Code:   >>> {code} <<<")
            print("⏳ Validity:   300 seconds (5 min)")
            print("=" * 60 + "\n")

        return {
            "message": "Одноразовый ключ доступа отправлен на почту.",
            "email": email,
            "dev_code": code if settings.DEV_MODE else None,
        }

    @classmethod
    async def verify_email_otp(
        cls,
        db: AsyncSession,
        redis,
        email: str,
        code: str
    ) -> Tuple[User, TokenResponse]:
        """Verify Email OTP code and login/register user."""
        email_clean = email.lower().strip()
        key = f"email_otp:{email_clean}"
        stored_code = await redis.get(key)

        if not stored_code or stored_code.strip() != code.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Неверный или истекший одноразовый код подтверждения."
            )

        # Consume code (one-time use)
        await redis.delete(key)

        # Look up existing user
        stmt = select(User).where(User.email == email_clean)
        res = await db.execute(stmt)
        user = res.scalars().first()

        if not user:
            # First time login via Email: register user
            preferred_name = email_clean.split("@")[0]
            username = await cls._resolve_unique_username(db, preferred_name)
            cyber_tag = await cls._generate_unique_cyber_tag(db, "RONIN")

            user = User(
                email=email_clean,
                username=username,
                cyber_tag=cyber_tag,
            )
            db.add(user)
            await db.commit()
            await db.refresh(user)

        await cls.join_global_hub_if_not_joined(db, user.id)
        tokens = cls._create_tokens_for_user(user)
        return user, tokens

    # --------------------------------------------------------------------------
    # 3. Telegram Neuromodem Authentication
    # --------------------------------------------------------------------------
    @classmethod
    async def verify_telegram_code(
        cls,
        db: AsyncSession,
        redis,
        code: str
    ) -> Tuple[User, TokenResponse]:
        """Verify 6-digit code issued by Telegram Neuromodem bot."""
        clean_code = code.strip()
        key = f"tg_otp:{clean_code}"
        raw_data = await redis.get(key)

        if not raw_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Код Telegram neuromodem не найден или срок его действия истек."
            )

        # Consume code
        await redis.delete(key)

        try:
            tg_data = json.loads(raw_data)
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Поврежденные данные нейросвязи."
            )

        telegram_id = int(tg_data["telegram_id"])
        tg_username = tg_data.get("username")

        # Find existing user by telegram_id
        stmt = select(User).where(User.telegram_id == telegram_id)
        res = await db.execute(stmt)
        user = res.scalars().first()

        if not user:
            # Register new samurai from Telegram
            preferred = tg_username or f"ronin_{telegram_id}"
            username = await cls._resolve_unique_username(db, preferred)
            cyber_tag = await cls._generate_unique_cyber_tag(db, "RONIN")

            user = User(
                telegram_id=telegram_id,
                username=username,
                cyber_tag=cyber_tag,
            )
            db.add(user)
            await db.commit()
            await db.refresh(user)

        await cls.join_global_hub_if_not_joined(db, user.id)
        tokens = cls._create_tokens_for_user(user)
        return user, tokens

    # --------------------------------------------------------------------------
    # Refresh Token
    # --------------------------------------------------------------------------
    @classmethod
    async def refresh_tokens(cls, db: AsyncSession, refresh_token: str) -> TokenResponse:
        """Issue fresh tokens using valid Refresh Token."""
        try:
            payload = decode_token(refresh_token)
            if payload.get("type") != "refresh":
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Недействительный тип токена."
                )
            user_id = uuid.UUID(payload.get("sub"))
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Недействительный или истекший refresh-токен."
            )

        stmt = select(User).where(User.id == user_id)
        res = await db.execute(stmt)
        user = res.scalars().first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Пользователь не найден."
            )

        return cls._create_tokens_for_user(user)
