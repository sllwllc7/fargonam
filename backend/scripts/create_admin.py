"""
Birinchi admin yaratish skripti.

Ishlatish:
    cd ~/fargonam/backend
    .venv/bin/python -m scripts.create_admin +998901234567 mening_parolim "Feron Admin"

Agar foydalanuvchi mavjud bo'lsa — uni admin rolga o'tkazadi.
"""
import asyncio
import sys

from sqlalchemy import select

from app.core.security import hash_password
from app.db.session import AsyncSessionLocal
from app.models.user import User, UserRole


async def main(phone: str, password: str, full_name: str | None) -> None:
    async with AsyncSessionLocal() as db:
        existing = await db.scalar(select(User).where(User.phone == phone))
        if existing:
            existing.role = UserRole.admin
            existing.is_active = True
            await db.commit()
            print(f"✅ Mavjud foydalanuvchi adminga o'tkazildi: id={existing.id} phone={phone}")
            return
        user = User(
            phone=phone,
            full_name=full_name,
            hashed_password=hash_password(password),
            role=UserRole.admin,
            is_active=True,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
        print(f"✅ Yangi admin yaratildi: id={user.id} phone={phone}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Foydalanish: python -m scripts.create_admin <phone> <password> [full_name]")
        sys.exit(1)
    phone = sys.argv[1]
    password = sys.argv[2]
    full_name = sys.argv[3] if len(sys.argv) > 3 else None
    asyncio.run(main(phone, password, full_name))
