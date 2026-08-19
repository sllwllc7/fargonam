"""orders: note ustuni qo'shildi (checkout izohi, HANDOFF.md 2-bo'lim 7-band)

Revision ID: d4e5f6a7b8c9
Revises: c3d4e5f6a7b8
Create Date: 2026-08-19
"""
from alembic import op
import sqlalchemy as sa

revision = 'd4e5f6a7b8c9'
down_revision = 'c3d4e5f6a7b8'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('orders', sa.Column('note', sa.String(500), nullable=True))


def downgrade() -> None:
    op.drop_column('orders', 'note')
