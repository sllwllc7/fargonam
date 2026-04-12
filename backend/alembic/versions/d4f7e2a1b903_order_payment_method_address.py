"""Order: payment_method va delivery_address qo'shildi

Revision ID: d4f7e2a1b903
Revises: c3a1f9d2e781
Create Date: 2026-04-12
"""
from alembic import op
import sqlalchemy as sa

revision = 'd4f7e2a1b903'
down_revision = 'c3a1f9d2e781'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("CREATE TYPE payment_method AS ENUM ('cash', 'card', 'payme', 'click')")
    op.add_column('orders', sa.Column(
        'payment_method',
        sa.Enum('cash', 'card', 'payme', 'click', name='payment_method'),
        nullable=False,
        server_default='cash',
    ))
    op.add_column('orders', sa.Column(
        'delivery_address',
        sa.String(500),
        nullable=True,
    ))


def downgrade() -> None:
    op.drop_column('orders', 'delivery_address')
    op.drop_column('orders', 'payment_method')
    op.execute("DROP TYPE payment_method")
