"""Product/ProductImage: thumb_url (kvadrat preview, Pillow bilan generatsiya qilinadi).

Revision ID: c4d5e6f7a819
Revises: b3c4d5e6f708
Create Date: 2026-08-20
"""
from alembic import op
import sqlalchemy as sa

revision = 'c4d5e6f7a819'
down_revision = 'b3c4d5e6f708'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('products', sa.Column('thumb_url', sa.String(length=500), nullable=True))
    op.add_column('product_images', sa.Column('thumb_url', sa.String(length=500), nullable=True))


def downgrade() -> None:
    op.drop_column('product_images', 'thumb_url')
    op.drop_column('products', 'thumb_url')
