"""Yangiliklar endpointlar — admin yozadi, hamma o'qiydi."""
import secrets

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_admin
from app.core.storage import UPLOAD_ROOT, public_url
from app.db.session import get_db
from app.models.news import NewsPost
from app.models.user import User

router = APIRouter(prefix="/news", tags=["news"])

NEWS_IMG_DIR = UPLOAD_ROOT / "news"
ALLOWED_IMG = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}


@router.get("")
async def list_news(
    db: AsyncSession = Depends(get_db),
    limit: int = Query(default=20, le=100, ge=1),
    offset: int = Query(default=0, ge=0),
):
    """Barcha e'lonlanigan yangiliklar (auth kerak emas)."""
    base = select(NewsPost).where(NewsPost.is_published.is_(True))
    total = await db.scalar(select(func.count()).select_from(base.subquery()))
    rows = (await db.scalars(
        base.order_by(NewsPost.id.desc()).limit(limit).offset(offset)
    )).all()
    return {
        "items": [
            {
                "id": n.id,
                "title": n.title,
                "body": n.body,
                "image_url": n.image_url,
                "created_at": n.created_at.isoformat(),
            }
            for n in rows
        ],
        "total": total or 0,
    }


@router.get("/{news_id}")
async def get_news(news_id: int, db: AsyncSession = Depends(get_db)):
    n = await db.get(NewsPost, news_id)
    if not n or not n.is_published:
        raise HTTPException(status_code=404, detail="Yangilik topilmadi")
    return {"id": n.id, "title": n.title, "body": n.body, "image_url": n.image_url, "created_at": n.created_at.isoformat()}


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_news(
    title: str,
    body: str,
    file: UploadFile | None = File(default=None),
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin yangilik/e'lon yaratadi (rasm ixtiyoriy)."""
    image_url = None
    if file and file.content_type in ALLOWED_IMG:
        NEWS_IMG_DIR.mkdir(parents=True, exist_ok=True)
        contents = await file.read()
        if len(contents) > 10 * 1024 * 1024:
            raise HTTPException(status_code=400, detail="Rasm 10MB dan katta")
        ext = ALLOWED_IMG[file.content_type]
        fname = f"news_{secrets.token_hex(8)}{ext}"
        (NEWS_IMG_DIR / fname).write_bytes(contents)
        image_url = public_url(f"news/{fname}")

    post = NewsPost(author_id=admin.id, title=title, body=body, image_url=image_url)
    db.add(post)
    await db.commit()
    await db.refresh(post)
    return {"id": post.id, "title": post.title}
