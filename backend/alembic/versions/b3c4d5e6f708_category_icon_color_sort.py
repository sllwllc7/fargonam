"""Category: icon, color, sort_order.

Admin panelning kategoriya CRUD'i uchun (REJA: Web Admin Panel +
Moderatsiya, §2). `icon`/`color` hozircha faqat saqlanadi — mobil ilova
ikonkani o'z slug'i bo'yicha tanlaydi, bu ustunlarga bog'lanish keyingi
bosqichda. `sort_order` esa darhol ishlaydi: `GET /categories` shu ustun
bo'yicha tartiblanadi, mavjud qatorlar `id * 10` bilan to'ldiriladi — hozirgi
ko'rinish (id tartibi) o'zgarmaydi, keyin admin qayta tartiblay oladi.

Revision ID: b3c4d5e6f708
Revises: a7b9c1d3e5f2
Create Date: 2026-08-20
"""
from alembic import op
import sqlalchemy as sa

revision = 'b3c4d5e6f708'
down_revision = 'a7b9c1d3e5f2'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('categories', sa.Column('icon', sa.String(length=64), nullable=True))
    op.add_column('categories', sa.Column('color', sa.String(length=7), nullable=True))
    op.add_column('categories', sa.Column(
        'sort_order', sa.Integer(), nullable=False, server_default='0',
    ))
    op.execute('UPDATE categories SET sort_order = id * 10')


def downgrade() -> None:
    op.drop_column('categories', 'sort_order')
    op.drop_column('categories', 'color')
    op.drop_column('categories', 'icon')
