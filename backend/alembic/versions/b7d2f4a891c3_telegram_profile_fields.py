"""telegram_profile_fields: users jadvaliga telegram_username, telegram_first_name,
telegram_last_name, language_code ustunlari (Mini App auth to'liq profil uchun)

Revision ID: b7d2f4a891c3
Revises: a3c8d1e5f206
Create Date: 2026-08-24
"""
from alembic import op
import sqlalchemy as sa

revision = 'b7d2f4a891c3'
down_revision = 'a3c8d1e5f206'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('users', sa.Column('telegram_username', sa.String(length=64), nullable=True))
    op.add_column('users', sa.Column('telegram_first_name', sa.String(length=120), nullable=True))
    op.add_column('users', sa.Column('telegram_last_name', sa.String(length=120), nullable=True))
    op.add_column('users', sa.Column('language_code', sa.String(length=8), nullable=True))


def downgrade() -> None:
    op.drop_column('users', 'language_code')
    op.drop_column('users', 'telegram_last_name')
    op.drop_column('users', 'telegram_first_name')
    op.drop_column('users', 'telegram_username')
