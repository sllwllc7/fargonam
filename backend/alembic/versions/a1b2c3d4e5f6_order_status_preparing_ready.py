"""Order status: preparing va ready qo'shildi (Tayyorlanmoqda / Tayyor)

Revision ID: a1b2c3d4e5f6
Revises: c3d7f9a2b615
Create Date: 2026-08-19
"""
from alembic import op

revision = 'a1b2c3d4e5f6'
down_revision = 'c3d7f9a2b615'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Postgres: yangi enum qiymatini o'z tranzaksiyasida commit qilish kerak,
    # shu tranzaksiyaning o'zida ishlatib bo'lmaydi — shu migratsiya faqat
    # qiymat qo'shadi, boshqa hech narsa qilmaydi.
    op.execute("ALTER TYPE order_status ADD VALUE IF NOT EXISTS 'preparing' AFTER 'paid'")
    op.execute("ALTER TYPE order_status ADD VALUE IF NOT EXISTS 'ready' AFTER 'preparing'")


def downgrade() -> None:
    # Postgres enum qiymatini olib tashlab bo'lmaydi (native ALTER TYPE DROP
    # VALUE yo'q) — downgrade yo'q, faqat hujjatlashtiramiz.
    pass
