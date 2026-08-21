"""category_image

Revision ID: a3c8d1e5f206
Revises: c4d5e6f7a819
Create Date: 2026-08-21 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a3c8d1e5f206'
down_revision: Union[str, None] = 'c4d5e6f7a819'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('categories', sa.Column('image_url', sa.String(length=500), nullable=True))
    op.add_column('categories', sa.Column('thumb_url', sa.String(length=500), nullable=True))


def downgrade() -> None:
    op.drop_column('categories', 'thumb_url')
    op.drop_column('categories', 'image_url')
