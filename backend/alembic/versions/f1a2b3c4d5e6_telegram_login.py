"""telegram_login: users jadvaliga telegram_id, phone endi nullable

Revision ID: f1a2b3c4d5e6
Revises: a2c4e6f8b012
Create Date: 2026-08-12
"""
from alembic import op
import sqlalchemy as sa

revision = 'f1a2b3c4d5e6'
down_revision = 'a2c4e6f8b012'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('users', sa.Column('telegram_id', sa.BigInteger(), nullable=True))
    op.create_unique_constraint('uq_users_telegram_id', 'users', ['telegram_id'])
    op.create_index('ix_users_telegram_id', 'users', ['telegram_id'])
    op.alter_column('users', 'phone', nullable=True)


def downgrade() -> None:
    op.alter_column('users', 'phone', nullable=False)
    op.drop_index('ix_users_telegram_id', table_name='users')
    op.drop_constraint('uq_users_telegram_id', 'users', type_='unique')
    op.drop_column('users', 'telegram_id')
