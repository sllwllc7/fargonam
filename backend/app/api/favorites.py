"""Sevimlilar endpointlar."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.favorite import Favorite
from app.models.product import Product
from app.models.product_variant import ProductVariant
from app.models.user import User

router = APIRouter(prefix="/favorites", tags=["favorites"])


@router.get("")
async def my_favorites(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    rows = (await db.scalars(
        select(Favorite).where(Favorite.user_id == current_user.id).order_by(Favorite.id.desc())
    )).all()
    result = []
    for f in rows:
        p = await db.get(Product, f.product_id)
        if p:
            # Eng arzon faol variant narxini ko'rsatamiz ("dan boshlab" narxi)
            min_price = await db.scalar(
                select(func.min(ProductVariant.price)).where(
                    ProductVariant.product_id == p.id, ProductVariant.is_active.is_(True)
                )
            )
            result.append({
                "id": f.id,
                "product_id": p.id,
                "product_name": p.name,
                "product_price": str(min_price) if min_price is not None else None,
                "product_image_url": p.image_url,
            })
    return result


@router.post("/{product_id}", status_code=status.HTTP_201_CREATED)
async def add_favorite(
    product_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    product = await db.get(Product, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    existing = await db.scalar(
        select(Favorite).where(Favorite.user_id == current_user.id, Favorite.product_id == product_id)
    )
    if existing:
        return {"status": "allaqachon qo'shilgan"}
    fav = Favorite(user_id=current_user.id, product_id=product_id)
    db.add(fav)
    await db.commit()
    return {"status": "qo'shildi"}


@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_favorite(
    product_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    fav = await db.scalar(
        select(Favorite).where(Favorite.user_id == current_user.id, Favorite.product_id == product_id)
    )
    if fav:
        await db.delete(fav)
        await db.commit()


@router.get("/check/{product_id}")
async def is_favorite(
    product_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    fav = await db.scalar(
        select(Favorite).where(Favorite.user_id == current_user.id, Favorite.product_id == product_id)
    )
    return {"is_favorite": fav is not None}
