"""Feed endpointlar — bannerlar va boshqa umumiy kontent."""
import secrets
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import require_admin
from app.core.storage import UPLOAD_ROOT, public_url
from app.db.session import get_db
from app.models.banner import Banner

router = APIRouter(prefix="/feed", tags=["feed"])

BANNERS_DIR = UPLOAD_ROOT / "banners"
ALLOWED_MEDIA = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "video/mp4": ".mp4",
}
MAX_MEDIA_BYTES = 50 * 1024 * 1024  # 50 MB


@router.get("/banners")
async def list_banners(db: AsyncSession = Depends(get_db)):
    """Faol bannerlar (tartiblangan). Auth kerak emas."""
    rows = await db.scalars(
        select(Banner).where(Banner.is_active.is_(True)).order_by(Banner.sort_order, Banner.id.desc())
    )
    return [
        {
            "id": b.id,
            "title": b.title,
            "media_url": b.media_url,
            "link_url": b.link_url,
        }
        for b in rows
    ]


@router.post("/banners", status_code=status.HTTP_201_CREATED)
async def create_banner(
    title: str,
    file: UploadFile = File(...),
    link_url: str | None = None,
    sort_order: int = 0,
    admin=Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin — yangi banner/reklama qo'shish (rasm yoki video)."""
    if file.content_type not in ALLOWED_MEDIA:
        raise HTTPException(status_code=400, detail="Faqat JPEG/PNG/WebP/MP4 yuklash mumkin")
    contents = await file.read()
    if len(contents) > MAX_MEDIA_BYTES:
        raise HTTPException(status_code=400, detail="Fayl 50MB dan katta")

    BANNERS_DIR.mkdir(parents=True, exist_ok=True)
    ext = ALLOWED_MEDIA[file.content_type]
    filename = f"banner_{secrets.token_hex(8)}{ext}"
    (BANNERS_DIR / filename).write_bytes(contents)

    banner = Banner(
        title=title,
        media_url=public_url(f"banners/{filename}"),
        link_url=link_url,
        sort_order=sort_order,
    )
    db.add(banner)
    await db.commit()
    await db.refresh(banner)
    return {"id": banner.id, "title": banner.title, "media_url": banner.media_url}
