"""
Parol hash va JWT yordamchilari.
- Parollar bcrypt bilan hash qilinadi
- JWT (HS256) access va refresh tokenlar uchun
- Refresh tokenlar rotation+revocation uchun Redis'da `jti` bilan kuzatiladi
"""
import uuid
from datetime import datetime, timedelta, timezone
from typing import Any

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.core.config import settings
from app.core.redis_client import get_redis

_REFRESH_JTI_PREFIX = "refresh_jti:"

# bcrypt 12 raund (default) — yetarlicha kuchli
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(plain: str) -> str:
    return pwd_context.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(subject: str | int, extra: dict[str, Any] | None = None) -> str:
    """JWT access token yaratish. `subject` odatda user.id."""
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )
    payload: dict[str, Any] = {"sub": str(subject), "exp": expire, "type": "access"}
    if extra:
        payload.update(extra)
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


async def create_refresh_token(subject: str | int) -> str:
    """JWT refresh token yaratish — uzoq muddatli (`REFRESH_TOKEN_EXPIRE_DAYS`).

    Har bir token o'ziga xos `jti` bilan Redis'da ro'yxatga olinadi — shu orqali
    keyinchalik rotation (ishlatilganda bekor qilish) va revocation (logout)
    amalga oshiriladi."""
    days = settings.REFRESH_TOKEN_EXPIRE_DAYS
    expire = datetime.now(timezone.utc) + timedelta(days=days)
    jti = uuid.uuid4().hex
    payload: dict[str, Any] = {
        "sub": str(subject),
        "exp": expire,
        "type": "refresh",
        "jti": jti,
    }
    token = jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    await get_redis().set(f"{_REFRESH_JTI_PREFIX}{subject}:{jti}", "1", ex=days * 86400)
    return token


async def is_refresh_token_active(subject: str, jti: str) -> bool:
    """Refresh token hali bekor qilinmaganini (rotation/logout orqali) tekshiradi."""
    return await get_redis().exists(f"{_REFRESH_JTI_PREFIX}{subject}:{jti}") > 0


async def revoke_refresh_token(subject: str, jti: str) -> None:
    """Refresh tokenni bekor qiladi — qayta ishlatib bo'lmaydi (rotation/logout)."""
    await get_redis().delete(f"{_REFRESH_JTI_PREFIX}{subject}:{jti}")


def decode_token(token: str) -> dict[str, Any] | None:
    """Tokenni dekod qiladi. Yaroqsiz bo'lsa None qaytaradi."""
    try:
        return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
    except JWTError:
        return None
