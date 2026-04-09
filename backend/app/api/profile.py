"""Profil avatar yuklash."""
import secrets

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.storage import UPLOAD_ROOT, public_url
from app.db.session import get_db
from app.models.user import User

router = APIRouter(prefix="/profile", tags=["profile"])

AVATAR_DIR = UPLOAD_ROOT / "avatars"
ALLOWED = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}


@router.post("/avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if file.content_type not in ALLOWED:
        raise HTTPException(status_code=400, detail="Faqat JPEG/PNG/WebP")
    contents = await file.read()
    if len(contents) > 5 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="5MB dan katta")
    AVATAR_DIR.mkdir(parents=True, exist_ok=True)
    ext = ALLOWED[file.content_type]
    fname = f"avatar_{current_user.id}_{secrets.token_hex(6)}{ext}"
    (AVATAR_DIR / fname).write_bytes(contents)
    current_user.avatar_url = public_url(f"avatars/{fname}")
    await db.commit()
    return {"avatar_url": current_user.avatar_url}
