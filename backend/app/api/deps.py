"""FastAPI umumiy dependency'lar — joriy foydalanuvchini olish va h.k."""
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_token
from app.db.session import get_db
from app.models.user import User, UserRole

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    creds_exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Yaroqsiz token",
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = decode_token(token)
    if not payload or "sub" not in payload:
        raise creds_exc
    # Faqat access token qabul qilinadi (refresh emas)
    if payload.get("type") != "access":
        raise creds_exc
    try:
        user_id = int(payload["sub"])
    except (TypeError, ValueError):
        raise creds_exc
    user = await db.get(User, user_id)
    if not user or not user.is_active:
        raise creds_exc
    return user


async def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """Faqat admin bo'lsa o'tkazadi."""
    if current_user.role != UserRole.admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bu sahifa faqat admin uchun",
        )
    return current_user
