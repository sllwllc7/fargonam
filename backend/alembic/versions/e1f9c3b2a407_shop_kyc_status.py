"""Shop KYC: status va admin_note ustunlari qo'shildi

Revision ID: e1f9c3b2a407
Revises: d4f7e2a1b903
Create Date: 2026-04-12
"""
from alembic import op
import sqlalchemy as sa

revision = 'e1f9c3b2a407'
down_revision = 'd4f7e2a1b903'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("CREATE TYPE shop_status AS ENUM ('pending', 'approved', 'rejected')")
    op.add_column('shops', sa.Column(
        'status',
        sa.Enum('pending', 'approved', 'rejected', name='shop_status'),
        nullable=False,
        server_default='pending',
    ))
    op.add_column('shops', sa.Column(
        'admin_note',
        sa.String(500),
        nullable=True,
    ))


def downgrade() -> None:
    op.drop_column('shops', 'admin_note')
    op.drop_column('shops', 'status')
    op.execute("DROP TYPE shop_status")
