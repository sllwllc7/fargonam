"""Push notification — FCM token ro'yxatdan o'tkazish."""
from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.fcm_token import FcmToken
from app.models.user import User

router = APIRouter(prefix="/push", tags=["push"])


class RegisterToken(BaseModel):
    token: str = Field(min_length=10, max_length=500)
    platform: str = Field(default="android", pattern=r"^(android|ios|web)$")


@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register_fcm_token(
    payload: RegisterToken,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """FCM tokenni ro'yxatdan o'tkazish (login/startup'da chaqiriladi)."""
    # Eski token bo'lsa — yangilash
    existing = await db.scalar(
        select(FcmToken).where(FcmToken.token == payload.token)
    )
    if existing:
        existing.user_id = current_user.id
        existing.platform = payload.platform
    else:
        db.add(FcmToken(
            user_id=current_user.id,
            token=payload.token,
            platform=payload.platform,
        ))
    await db.commit()
    return {"status": "registered"}


@router.delete("/unregister", status_code=status.HTTP_204_NO_CONTENT)
async def unregister_fcm_token(
    token: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Logout'da FCM tokenni o'chirish."""
    existing = await db.scalar(
        select(FcmToken).where(
            FcmToken.token == token,
            FcmToken.user_id == current_user.id,
        )
    )
    if existing:
        await db.delete(existing)
        await db.commit()
