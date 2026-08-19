import asyncio

from app.db.session import AsyncSessionLocal
from app.models.shop import Shop, ShopStatus
from app.models.user import User, UserRole
from sqlalchemy import select


async def main():
    async with AsyncSessionLocal() as db:
        existing = await db.scalar(select(Shop).where(Shop.id == 1))
        if existing:
            print(f"SHOP_ALREADY_EXISTS id={existing.id}")
            return
        owner = User(full_name="Fargonam", role=UserRole.seller, is_active=True)
        db.add(owner)
        await db.flush()
        shop = Shop(
            owner_id=owner.id,
            name="Fargonam",
            description="Fargonam rasmiy do'koni",
            status=ShopStatus.approved,
            is_active=True,
        )
        db.add(shop)
        await db.commit()
        await db.refresh(shop)
        print(f"SHOP_CREATED_OK id={shop.id} owner_id={owner.id}")


if __name__ == "__main__":
    asyncio.run(main())
