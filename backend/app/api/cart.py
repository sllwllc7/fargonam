"""Cart va Order endpointlari — savatcha va buyurtma berish."""
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.cart import CartItem
from app.models.order import Order, OrderItem
from app.models.product import Product
from app.models.user import User
from app.schemas.marketplace import CartItemAdd, CartItemOut, OrderItemOut, OrderOut

router = APIRouter(tags=["cart-orders"])


async def _enrich_order(order: Order, db: AsyncSession) -> OrderOut:
    """Order'ga mahsulot nomi va rasmini qo'shadi."""
    enriched_items = []
    for oi in order.items:
        product = await db.get(Product, oi.product_id)
        enriched_items.append(OrderItemOut(
            id=oi.id,
            product_id=oi.product_id,
            quantity=oi.quantity,
            price_at_purchase=oi.price_at_purchase,
            product_name=product.name if product else None,
            product_image_url=product.image_url if product else None,
        ))
    return OrderOut(
        id=order.id,
        user_id=order.user_id,
        total=order.total,
        status=order.status,
        created_at=order.created_at,
        items=enriched_items,
    )


@router.get("/cart", response_model=list[CartItemOut])
async def get_cart(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    rows = (await db.scalars(select(CartItem).where(CartItem.user_id == current_user.id))).all()
    result = []
    for ci in rows:
        product = await db.get(Product, ci.product_id)
        result.append(CartItemOut(
            id=ci.id,
            product_id=ci.product_id,
            quantity=ci.quantity,
            product_name=product.name if product else None,
            product_price=str(product.price) if product else None,
            product_image_url=product.image_url if product else None,
        ))
    return result


@router.post("/cart", response_model=CartItemOut, status_code=status.HTTP_201_CREATED)
async def add_to_cart(
    payload: CartItemAdd,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    product = await db.get(Product, payload.product_id)
    if not product or not product.is_active:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    existing = await db.scalar(
        select(CartItem).where(
            CartItem.user_id == current_user.id,
            CartItem.product_id == payload.product_id,
        )
    )
    if existing:
        existing.quantity += payload.quantity
        await db.commit()
        await db.refresh(existing)
        return existing
    item = CartItem(
        user_id=current_user.id,
        product_id=payload.product_id,
        quantity=payload.quantity,
    )
    db.add(item)
    await db.commit()
    await db.refresh(item)
    return item


@router.patch("/cart/{item_id}")
async def update_cart_quantity(
    item_id: int,
    quantity: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Savatchadagi element sonini o'zgartirish."""
    item = await db.get(CartItem, item_id)
    if not item or item.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Element topilmadi")
    if quantity <= 0:
        await db.delete(item)
        await db.commit()
        return {"status": "deleted"}
    item.quantity = quantity
    await db.commit()
    return {"status": "updated", "quantity": quantity}


@router.delete("/cart/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_from_cart(
    item_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    item = await db.get(CartItem, item_id)
    if not item or item.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Element topilmadi")
    await db.delete(item)
    await db.commit()


@router.post("/orders", response_model=OrderOut, status_code=status.HTTP_201_CREATED)
async def checkout(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Savatchadagi hamma narsadan buyurtma yaratadi va savatchani bo'shatadi."""
    cart_rows = (
        await db.scalars(select(CartItem).where(CartItem.user_id == current_user.id))
    ).all()
    if not cart_rows:
        raise HTTPException(status_code=400, detail="Savatcha bo'sh")

    # Mahsulotlarni va stockni tekshirish
    total = Decimal("0")
    items_to_create: list[OrderItem] = []
    for ci in cart_rows:
        product = await db.get(Product, ci.product_id)
        if not product or not product.is_active:
            raise HTTPException(
                status_code=400, detail=f"Mahsulot #{ci.product_id} mavjud emas"
            )
        if product.stock < ci.quantity:
            raise HTTPException(
                status_code=400,
                detail=f"'{product.name}' yetarli emas (qolgan: {product.stock})",
            )
        product.stock -= ci.quantity
        line_total = product.price * ci.quantity
        total += line_total
        items_to_create.append(
            OrderItem(
                product_id=product.id,
                quantity=ci.quantity,
                price_at_purchase=product.price,
            )
        )

    order = Order(user_id=current_user.id, total=total, items=items_to_create)
    db.add(order)

    # Savatchani tozalash
    for ci in cart_rows:
        await db.delete(ci)

    await db.commit()
    await db.refresh(order)
    return await _enrich_order(order, db)


@router.get("/orders", response_model=list[OrderOut])
async def list_my_orders(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    rows = (await db.scalars(
        select(Order).where(Order.user_id == current_user.id).order_by(Order.id.desc())
    )).all()
    return [await _enrich_order(o, db) for o in rows]
