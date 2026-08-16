"""orders: delivery_type va pickup_code

Xaridor do'kondan o'zi olib ketishi (pickup) uchun: 4 xonali kod
(pickup_code, butun tarix bo'yicha unikal — hech qachon qayta
ishlatilmaydi) va delivery_type ('delivery'/'pickup') ustunlari.

Revision ID: c3d7f9a2b615
Revises: b2c6e8f1a934
Create Date: 2026-08-16
"""
from alembic import op
import sqlalchemy as sa

revision = 'c3d7f9a2b615'
down_revision = 'b2c6e8f1a934'
branch_labels = None
depends_on = None


def upgrade() -> None:
    delivery_type_enum = sa.Enum('delivery', 'pickup', name='delivery_type')
    delivery_type_enum.create(op.get_bind())
    op.add_column(
        'orders',
        sa.Column('delivery_type', delivery_type_enum, nullable=False, server_default='delivery'),
    )
    op.add_column('orders', sa.Column('pickup_code', sa.String(length=4), nullable=True))
    op.create_unique_constraint('uq_orders_pickup_code', 'orders', ['pickup_code'])


def downgrade() -> None:
    op.drop_constraint('uq_orders_pickup_code', 'orders', type_='unique')
    op.drop_column('orders', 'pickup_code')
    op.drop_column('orders', 'delivery_type')
    sa.Enum(name='delivery_type').drop(op.get_bind())
