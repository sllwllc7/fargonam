"""Yangiliklar endpointlar — admin yozadi, hamma o'qiydi."""
import secrets

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from pydantic import BaseModel, Field

from app.api.deps import get_current_user, require_admin
from app.core.storage import UPLOAD_ROOT, public_url
from app.core.upload_utils import validate_image
from app.db.session import get_db
from app.models.news import NewsPost
from app.models.news_interaction import NewsComment, NewsLike
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
    # Like va comment sonlarini olish
    items = []
    for n in rows:
        likes_count = await db.scalar(
            select(func.count()).where(NewsLike.news_id == n.id)
        )
        comments_count = await db.scalar(
            select(func.count()).where(NewsComment.news_id == n.id)
        )
        items.append({
            "id": n.id,
            "title": n.title,
            "body": n.body,
            "image_url": n.image_url,
            "created_at": n.created_at.isoformat(),
            "likes_count": likes_count or 0,
            "comments_count": comments_count or 0,
        })
    return {"items": items, "total": total or 0}


@router.get("/{news_id}")
async def get_news(news_id: int, db: AsyncSession = Depends(get_db)):
    n = await db.get(NewsPost, news_id)
    if not n or not n.is_published:
        raise HTTPException(status_code=404, detail="Yangilik topilmadi")
    return {"id": n.id, "title": n.title, "body": n.body, "image_url": n.image_url, "created_at": n.created_at.isoformat()}


class NewsCreate(BaseModel):
    title: str = Field(max_length=500)
    body: str = Field(max_length=10000)
    image_url: str | None = None


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_news(
    payload: NewsCreate,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin yangilik yaratadi (JSON body, image_url — ixtiyoriy URL)."""
    post = NewsPost(author_id=admin.id, title=payload.title, body=payload.body, image_url=payload.image_url)
    db.add(post)
    await db.commit()
    await db.refresh(post)
    return {"id": post.id, "title": post.title}


@router.delete("/{news_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_news(
    news_id: int,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin yangilikni o'chiradi."""
    post = await db.get(NewsPost, news_id)
    if not post:
        raise HTTPException(status_code=404, detail="Yangilik topilmadi")
    await db.delete(post)
    await db.commit()


# ========== LIKE ==========

@router.post("/{news_id}/like", status_code=status.HTTP_201_CREATED)
async def like_news(
    news_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Yangilikka like bosish (toggle — qayta bossa o'chiradi)."""
    existing = await db.scalar(
        select(NewsLike).where(NewsLike.user_id == current_user.id, NewsLike.news_id == news_id)
    )
    if existing:
        await db.delete(existing)
        await db.commit()
        return {"liked": False}
    db.add(NewsLike(user_id=current_user.id, news_id=news_id))
    await db.commit()
    return {"liked": True}


@router.get("/{news_id}/liked")
async def check_liked(
    news_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    existing = await db.scalar(
        select(NewsLike).where(NewsLike.user_id == current_user.id, NewsLike.news_id == news_id)
    )
    return {"liked": existing is not None}


# ========== COMMENTS ==========

class CommentCreate(BaseModel):
    text: str = Field(min_length=1, max_length=500)


@router.get("/{news_id}/comments")
async def list_comments(
    news_id: int,
    db: AsyncSession = Depends(get_db),
    limit: int = Query(default=50, le=200),
):
    rows = (await db.scalars(
        select(NewsComment).where(NewsComment.news_id == news_id).order_by(NewsComment.id.desc()).limit(limit)
    )).all()
    result = []
    for c in rows:
        user = await db.get(User, c.user_id)
        result.append({
            "id": c.id,
            "user_name": user.full_name or user.phone if user else "Noma'lum",
            "text": c.text,
            "created_at": c.created_at.isoformat(),
        })
    return result


@router.post("/{news_id}/comments", status_code=status.HTTP_201_CREATED)
async def add_comment(
    news_id: int,
    payload: CommentCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    news = await db.get(NewsPost, news_id)
    if not news:
        raise HTTPException(status_code=404, detail="Yangilik topilmadi")
    comment = NewsComment(user_id=current_user.id, news_id=news_id, text=payload.text)
    db.add(comment)
    await db.commit()
    await db.refresh(comment)
    return {"id": comment.id, "text": comment.text}
