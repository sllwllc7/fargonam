"""orders.cancel_reason ustuni

Buyurtma bekor qilinganda sababni saqlash uchun (sotuvchi "Bajarib
bo'lmaydi" desa to'ldiradi, xaridor o'zi bekor qilsa bo'sh qoladi).

Revision ID: b2c6e8f1a934
Revises: a9c1d3e5f708
Create Date: 2026-08-16
"""
from alembic import op
import sqlalchemy as sa

revision = 'b2c6e8f1a934'
down_revision = 'a9c1d3e5f708'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('orders', sa.Column('cancel_reason', sa.String(length=500), nullable=True))


def downgrade() -> None:
    op.drop_column('orders', 'cancel_reason')
