"""Feed endpointlar — bannerlar va boshqa umumiy kontent."""
import secrets
from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
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
            "body": b.body,
            "media_url": b.media_url,
            "link_url": b.link_url,
            "created_at": b.created_at.isoformat() if b.created_at else None,
        }
        for b in rows
    ]


@router.post("/banners", status_code=status.HTTP_201_CREATED)
async def create_banner(
    title: str = Form(...),
    file: UploadFile | None = File(default=None),
    media_url: str | None = Form(None),
    body: str | None = Form(None),
    link_url: str | None = Form(None),
    sort_order: int = Form(0),
    admin=Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin — yangi banner/reklama qo'shish. Fayl yoki URL orqali."""
    final_media_url: str | None = None

    if file and file.filename:
        # Fayl yuklash
        if file.content_type not in ALLOWED_MEDIA:
            raise HTTPException(status_code=400, detail="Faqat JPEG/PNG/WebP/MP4 yuklash mumkin")
        contents = await file.read()
        if not contents:
            raise HTTPException(status_code=400, detail="Bo'sh fayl")
        if len(contents) > MAX_MEDIA_BYTES:
            raise HTTPException(status_code=400, detail="Fayl 50MB dan katta")
        if file.content_type.startswith("image/"):
            from app.core.upload_utils import validate_image
            try:
                validate_image(contents, max_bytes=MAX_MEDIA_BYTES)
            except ValueError as e:
                raise HTTPException(status_code=400, detail=str(e))
        BANNERS_DIR.mkdir(parents=True, exist_ok=True)
        ext = ALLOWED_MEDIA[file.content_type]
        filename = f"banner_{secrets.token_hex(8)}{ext}"
        (BANNERS_DIR / filename).write_bytes(contents)
        final_media_url = public_url(f"banners/{filename}")
    elif media_url and media_url.strip():
        # To'g'ridan URL
        final_media_url = media_url.strip()
    else:
        raise HTTPException(status_code=400, detail="Fayl yoki media URL kiritish shart")

    banner = Banner(
        title=title,
        body=body,
        media_url=final_media_url,
        link_url=link_url,
        sort_order=sort_order,
    )
    db.add(banner)
    await db.commit()
    await db.refresh(banner)
    return {"id": banner.id, "title": banner.title, "media_url": banner.media_url}


@router.patch("/banners/{banner_id}")
async def update_banner(
    banner_id: int,
    title: str | None = None,
    link_url: str | None = None,
    sort_order: int | None = None,
    is_active: bool | None = None,
    admin=Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin — bannerni tahrirlash."""
    banner = await db.get(Banner, banner_id)
    if not banner:
        raise HTTPException(status_code=404, detail="Banner topilmadi")
    if title is not None:
        banner.title = title
    if link_url is not None:
        banner.link_url = link_url
    if sort_order is not None:
        banner.sort_order = sort_order
    if is_active is not None:
        banner.is_active = is_active
    await db.commit()
    await db.refresh(banner)
    return {"id": banner.id, "title": banner.title, "is_active": banner.is_active}


@router.delete("/banners/{banner_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_banner(
    banner_id: int,
    admin=Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin — bannerni o'chirish."""
    banner = await db.get(Banner, banner_id)
    if not banner:
        raise HTTPException(status_code=404, detail="Banner topilmadi")
    # Faylni diskdan ham o'chirish
    if banner.media_url:
        try:
            fname = banner.media_url.split("/uploads/")[-1]
            fpath = UPLOAD_ROOT / fname
            if fpath.exists():
                fpath.unlink()
        except Exception:
            pass
    await db.delete(banner)
    await db.commit()


@router.get("/banners/all")
async def list_all_banners(
    admin=Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin — barcha bannerlar (aktiv va noaktiv)."""
    rows = await db.scalars(
        select(Banner).order_by(Banner.sort_order, Banner.id.desc())
    )
    return [
        {
            "id": b.id,
            "title": b.title,
            "body": b.body,
            "media_url": b.media_url,
            "link_url": b.link_url,
            "is_active": b.is_active,
            "sort_order": b.sort_order,
            "created_at": b.created_at.isoformat() if b.created_at else None,
        }
        for b in rows
    ]
