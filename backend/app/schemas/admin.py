"""Admin uchun sxemalar."""
from pydantic import BaseModel

from app.models.order import OrderStatus


class UserAdminUpdate(BaseModel):
    is_active: bool | None = None
    role: str | None = None  # buyer/seller/admin


class OrderStatusUpdate(BaseModel):
    status: OrderStatus


class AdminStats(BaseModel):
    users_total: int
    sellers_total: int
    shops_total: int
    shops_pending: int = 0  # Admin tasdig'ini kutayotgan do'konlar
    products_total: int
    orders_total: int
    revenue_total: float
