"""product_sets: shop_id qo'shildi (sotuvchi o'z to'plamini boshqarishi uchun)

Revision ID: b2c3d4e5f6a7
Revises: a1b2c3d4e5f6
Create Date: 2026-08-19
"""
from alembic import op
import sqlalchemy as sa

revision = 'b2c3d4e5f6a7'
down_revision = 'a1b2c3d4e5f6'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('product_sets', sa.Column('shop_id', sa.Integer(), nullable=True))
    op.create_foreign_key(
        'fk_product_sets_shop_id', 'product_sets', 'shops', ['shop_id'], ['id'], ondelete='CASCADE'
    )
    op.create_index('ix_product_sets_shop_id', 'product_sets', ['shop_id'])


def downgrade() -> None:
    op.drop_index('ix_product_sets_shop_id', table_name='product_sets')
    op.drop_constraint('fk_product_sets_shop_id', 'product_sets', type_='foreignkey')
    op.drop_column('product_sets', 'shop_id')
