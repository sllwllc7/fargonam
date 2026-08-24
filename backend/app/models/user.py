"""
User modeli — ham xaridor, ham sotuvchi shu jadvalda.
`role` orqali farqlanadi (buyer, seller, admin).
"""
from datetime import datetime
from enum import Enum

from sqlalchemy import BigInteger, Boolean, DateTime, String
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.db.base import Base


class UserRole(str, Enum):
    buyer = "buyer"
    seller = "seller"
    admin = "admin"


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    phone: Mapped[str | None] = mapped_column(String(20), unique=True, index=True, nullable=True)
    telegram_id: Mapped[int | None] = mapped_column(BigInteger, unique=True, index=True, nullable=True)
    full_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    # Telegram'dan kelgan xom ma'lumot — har login/​start'da yangilanadi.
    # `full_name` esa faqat birinchi yaratilishda shundan hosil qilinadi va
    # keyin foydalanuvchi profilda o'zgartirsa saqlanib qoladi (qayta yozilmaydi).
    telegram_username: Mapped[str | None] = mapped_column(String(64), nullable=True)
    telegram_first_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    telegram_last_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    language_code: Mapped[str | None] = mapped_column(String(8), nullable=True)
    hashed_password: Mapped[str | None] = mapped_column(String(255), nullable=True)
    role: Mapped[UserRole] = mapped_column(
        SAEnum(UserRole, name="user_role"),
        default=UserRole.buyer,
        nullable=False,
    )
    avatar_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} phone={self.phone} role={self.role}>"
