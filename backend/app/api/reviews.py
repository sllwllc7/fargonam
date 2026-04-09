"""Reyting va sharhlar endpointlar."""
from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.review import Review
from app.models.product import Product
from app.models.user import User

router = APIRouter(prefix="/reviews", tags=["reviews"])


class ReviewCreate(BaseModel):
    rating: int = Field(ge=1, le=5)
    comment: str | None = None


@router.get("/product/{product_id}")
async def product_reviews(
    product_id: int,
    db: AsyncSession = Depends(get_db),
    limit: int = Query(default=20, le=100),
    offset: int = Query(default=0, ge=0),
):
    """Mahsulot sharhlari (auth kerak emas)."""
    base = select(Review).where(Review.product_id == product_id)
    total = await db.scalar(select(func.count()).select_from(base.subquery()))
    avg_rating = await db.scalar(
        select(func.avg(Review.rating)).where(Review.product_id == product_id)
    )
    rows = (await db.scalars(
        base.order_by(Review.id.desc()).limit(limit).offset(offset)
    )).all()
    items = []
    for r in rows:
        user = await db.get(User, r.user_id)
        items.append({
            "id": r.id,
            "rating": r.rating,
            "comment": r.comment,
            "user_name": user.full_name or user.phone if user else "Noma'lum",
            "created_at": r.created_at.isoformat(),
        })
    return {
        "items": items,
        "total": total or 0,
        "avg_rating": round(float(avg_rating), 1) if avg_rating else None,
    }


@router.post("/product/{product_id}", status_code=status.HTTP_201_CREATED)
async def create_review(
    product_id: int,
    payload: ReviewCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    product = await db.get(Product, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    existing = await db.scalar(
        select(Review).where(Review.user_id == current_user.id, Review.product_id == product_id)
    )
    if existing:
        existing.rating = payload.rating
        existing.comment = payload.comment
        await db.commit()
        return {"status": "yangilandi"}
    review = Review(
        user_id=current_user.id,
        product_id=product_id,
        rating=payload.rating,
        comment=payload.comment,
    )
    db.add(review)
    await db.commit()
    return {"status": "qo'shildi"}
