"""Mahsulot/to'plam moderatsiyasi: status, rejected_reason, submitted_at,
moderated_at, moderated_by, pending_edit. Shop.is_trusted.

Mavjud barcha mahsulot/to'plam 'approved' qilib to'ldiriladi — hech narsa
User App'dan yo'qolib qolmaydi.

Revision ID: a7b9c1d3e5f2
Revises: d4e5f6a7b8c9
Create Date: 2026-08-20
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = 'a7b9c1d3e5f2'
down_revision = 'd4e5f6a7b8c9'
branch_labels = None
depends_on = None

_STATUS_ENUM = sa.Enum('draft', 'pending', 'approved', 'rejected', name='product_status')


def _add_moderation_columns(table: str) -> None:
    op.add_column(table, sa.Column(
        'status', _STATUS_ENUM, nullable=False, server_default='pending',
    ))
    op.add_column(table, sa.Column('rejected_reason', sa.Text(), nullable=True))
    op.add_column(table, sa.Column('submitted_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column(table, sa.Column('moderated_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column(table, sa.Column(
        'moderated_by', sa.Integer(),
        sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True,
    ))
    op.add_column(table, sa.Column('pending_edit', JSONB(), nullable=True))

    # Mavjud qatorlar — approved, submitted_at/moderated_at = created_at
    op.execute(
        f"UPDATE {table} SET status = 'approved', "
        f"submitted_at = created_at, moderated_at = created_at"
    )
    op.alter_column(table, 'submitted_at', nullable=False, server_default=sa.text('now()'))


def _drop_moderation_columns(table: str) -> None:
    op.drop_column(table, 'pending_edit')
    op.drop_column(table, 'moderated_by')
    op.drop_column(table, 'moderated_at')
    op.drop_column(table, 'submitted_at')
    op.drop_column(table, 'rejected_reason')
    op.drop_column(table, 'status')


def upgrade() -> None:
    _STATUS_ENUM.create(op.get_bind())
    _add_moderation_columns('products')
    _add_moderation_columns('product_sets')
    op.add_column('shops', sa.Column(
        'is_trusted', sa.Boolean(), nullable=False, server_default=sa.false(),
    ))


def downgrade() -> None:
    op.drop_column('shops', 'is_trusted')
    _drop_moderation_columns('product_sets')
    _drop_moderation_columns('products')
    _STATUS_ENUM.drop(op.get_bind())
