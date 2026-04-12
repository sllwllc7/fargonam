"""Profil avatar yuklash."""
import secrets

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.storage import UPLOAD_ROOT, public_url
from app.core.upload_utils import validate_image
from app.db.session import get_db
from app.models.user import User

router = APIRouter(prefix="/profile", tags=["profile"])

AVATAR_DIR = UPLOAD_ROOT / "avatars"


@router.post("/avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    contents = await file.read()
    try:
        ext = validate_image(contents, max_bytes=5 * 1024 * 1024)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    AVATAR_DIR.mkdir(parents=True, exist_ok=True)
    fname = f"avatar_{current_user.id}_{secrets.token_hex(6)}{ext}"
    (AVATAR_DIR / fname).write_bytes(contents)
    current_user.avatar_url = public_url(f"avatars/{fname}")
    await db.commit()
    return {"avatar_url": current_user.avatar_url}
