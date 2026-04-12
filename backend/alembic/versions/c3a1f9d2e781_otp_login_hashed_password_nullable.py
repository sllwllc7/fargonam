"""OTP login: hashed_password nullable qilindi

Revision ID: c3a1f9d2e781
Revises: b589bd84728c
Create Date: 2026-04-12
"""
from alembic import op
import sqlalchemy as sa

revision = 'c3a1f9d2e781'
down_revision = '9b8db5998420'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.alter_column('users', 'hashed_password', nullable=True)


def downgrade() -> None:
    # Pastga qaytganda NULL qiymatlarni bo'sh satr bilan to'ldirish
    op.execute("UPDATE users SET hashed_password = '' WHERE hashed_password IS NULL")
    op.alter_column('users', 'hashed_password', nullable=False)
