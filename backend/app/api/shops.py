"""Shop endpointlari — sotuvchi do'kon yaratadi va boshqaradi."""
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.shop import Shop
from app.models.user import User, UserRole
from app.schemas.marketplace import ShopCreate, ShopOut

router = APIRouter(prefix="/shops", tags=["shops"])


@router.get("", response_model=list[ShopOut])
async def list_shops(
    db: AsyncSession = Depends(get_db),
    q: str | None = Query(default=None, max_length=100, description="Nomda qidirish"),
):
    base = select(Shop).where(Shop.is_active.is_(True))
    if q:
        safe_q = q.replace("%", r"\%").replace("_", r"\_")
        base = base.where(Shop.name.ilike(f"%{safe_q}%"))
    rows = await db.scalars(base)
    return list(rows)


@router.post("", response_model=ShopOut, status_code=status.HTTP_201_CREATED)
async def create_shop(
    payload: ShopCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if current_user.role not in (UserRole.seller, UserRole.admin):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Faqat sotuvchilar do'kon yarata oladi",
        )
    shop = Shop(owner_id=current_user.id, name=payload.name, description=payload.description)
    db.add(shop)
    await db.commit()
    await db.refresh(shop)
    return shop


@router.get("/{shop_id}", response_model=ShopOut)
async def get_shop(shop_id: int, db: AsyncSession = Depends(get_db)):
    shop = await db.get(Shop, shop_id)
    if not shop or not shop.is_active:
        raise HTTPException(status_code=404, detail="Do'kon topilmadi")
    return shop
