"""product_variants: mahsulot-variant modeliga o'tish

Marketplace mahsulotlari endi ikki darajali: parent (`products` — umumiy nom)
va `product_variants` (narx/stok/SKU shu darajada). Mavjud mahsulotlarning
price/stock'idan avtomatik bittadan "Standart" variant yaratiladi (backfill),
keyin eski ustunlar olib tashlanadi. `cart_items`/`order_items` endi
`product_id` o'rniga `variant_id`ga bog'lanadi.

Shu bilan birga: `saved_addresses`ga strukturaviy maydonlar (viloyat/tuman/
mo'ljal/default), `orders`ga `delivery_address_id`, va kelajakdagi "tayyor
to'plam" funksiyasi uchun `product_sets`/`product_set_items` skeleti.

Revision ID: a9c1d3e5f708
Revises: f1a2b3c4d5e6
Create Date: 2026-08-13
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = 'a9c1d3e5f708'
down_revision = 'f1a2b3c4d5e6'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── 1. product_variants jadvali ──
    op.create_table(
        'product_variants',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('product_id', sa.Integer(), sa.ForeignKey('products.id', ondelete='CASCADE'), nullable=False),
        sa.Column('sku', sa.String(length=64), nullable=False),
        sa.Column('variant_name', sa.String(length=100), nullable=False),
        sa.Column('price', sa.Integer(), nullable=False),
        sa.Column('old_price', sa.Integer(), nullable=True),
        sa.Column('stock', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('attributes', postgresql.JSONB(), nullable=False, server_default='{}'),
        sa.Column('image_url', sa.String(length=500), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('sort_order', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint('price > 0', name='ck_variant_price_positive'),
        sa.CheckConstraint('stock >= 0', name='ck_variant_stock_nonneg'),
        sa.CheckConstraint('old_price IS NULL OR old_price > price', name='ck_variant_old_price_gt_price'),
    )
    op.create_index('ix_product_variants_product_id', 'product_variants', ['product_id'])
    op.create_index('ix_product_variants_sku', 'product_variants', ['sku'], unique=True)
    op.create_index(
        'ix_variants_attributes_gin', 'product_variants', ['attributes'], postgresql_using='gin'
    )

    # ── 2. Backfill: har mahsulotdan bitta "Standart" variant ──
    op.execute("""
        INSERT INTO product_variants (product_id, sku, variant_name, price, stock, attributes, is_active, sort_order, created_at)
        SELECT id,
               'SKU-' || id || '-MIG',
               'Standart',
               GREATEST(ROUND(price)::int, 1),
               COALESCE(stock, 0),
               '{}'::jsonb,
               true,
               0,
               now()
        FROM products
    """)

    # ── 3. products: price/stock olib tashlanadi, slug qo'shiladi ──
    op.drop_column('products', 'price')
    op.drop_column('products', 'stock')
    op.add_column('products', sa.Column('slug', sa.String(length=220), nullable=True))
    op.create_index('ix_products_slug', 'products', ['slug'], unique=True)

    # ── 4. cart_items: product_id -> variant_id ──
    op.add_column('cart_items', sa.Column('variant_id', sa.Integer(), nullable=True))
    op.execute("""
        UPDATE cart_items ci SET variant_id = pv.id
        FROM product_variants pv WHERE pv.product_id = ci.product_id
    """)
    op.alter_column('cart_items', 'variant_id', nullable=False)
    op.create_foreign_key(
        'fk_cart_items_variant', 'cart_items', 'product_variants', ['variant_id'], ['id'], ondelete='CASCADE'
    )
    op.create_index('ix_cart_items_variant_id', 'cart_items', ['variant_id'])
    # Eski ustunni o'chirish — bog'liq eski FK/unique constraint (uq_cart_user_product)
    # Postgres tomonidan avtomatik olib tashlanadi
    op.drop_column('cart_items', 'product_id')
    op.create_unique_constraint('uq_cart_user_variant', 'cart_items', ['user_id', 'variant_id'])

    # ── 5. order_items: product_id -> variant_id ──
    op.add_column('order_items', sa.Column('variant_id', sa.Integer(), nullable=True))
    op.execute("""
        UPDATE order_items oi SET variant_id = pv.id
        FROM product_variants pv WHERE pv.product_id = oi.product_id
    """)
    op.alter_column('order_items', 'variant_id', nullable=False)
    op.create_foreign_key(
        'fk_order_items_variant', 'order_items', 'product_variants', ['variant_id'], ['id'], ondelete='RESTRICT'
    )
    op.create_index('ix_order_items_variant_id', 'order_items', ['variant_id'])
    op.drop_column('order_items', 'product_id')

    # ── 6. saved_addresses: strukturaviy maydonlar ──
    op.add_column('saved_addresses', sa.Column('region', sa.String(length=100), nullable=True))
    op.add_column('saved_addresses', sa.Column('district', sa.String(length=100), nullable=True))
    op.add_column('saved_addresses', sa.Column('landmark', sa.String(length=300), nullable=True))
    op.add_column('saved_addresses', sa.Column('is_default', sa.Boolean(), nullable=False, server_default='false'))

    # ── 7. orders: saqlangan manzilga ishora ──
    op.add_column('orders', sa.Column('delivery_address_id', sa.Integer(), nullable=True))
    op.create_foreign_key(
        'fk_orders_delivery_address', 'orders', 'saved_addresses', ['delivery_address_id'], ['id'], ondelete='SET NULL'
    )

    # ── 8. product_sets / product_set_items (skelet, hozircha ishlatilmaydi) ──
    op.create_table(
        'product_sets',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('name', sa.String(length=120), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('grade_level', sa.String(length=20), nullable=True),
        sa.Column('image_url', sa.String(length=500), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        'product_set_items',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('set_id', sa.Integer(), sa.ForeignKey('product_sets.id', ondelete='CASCADE'), nullable=False),
        sa.Column('variant_id', sa.Integer(), sa.ForeignKey('product_variants.id', ondelete='CASCADE'), nullable=False),
        sa.Column('quantity', sa.Integer(), nullable=False, server_default='1'),
    )
    op.create_index('ix_product_set_items_set_id', 'product_set_items', ['set_id'])
    op.create_index('ix_product_set_items_variant_id', 'product_set_items', ['variant_id'])


def downgrade() -> None:
    op.drop_index('ix_product_set_items_variant_id', table_name='product_set_items')
    op.drop_index('ix_product_set_items_set_id', table_name='product_set_items')
    op.drop_table('product_set_items')
    op.drop_table('product_sets')

    op.drop_constraint('fk_orders_delivery_address', 'orders', type_='foreignkey')
    op.drop_column('orders', 'delivery_address_id')

    op.drop_column('saved_addresses', 'is_default')
    op.drop_column('saved_addresses', 'landmark')
    op.drop_column('saved_addresses', 'district')
    op.drop_column('saved_addresses', 'region')

    # order_items: variant_id -> product_id (variantning parentidan tiklanadi)
    op.add_column('order_items', sa.Column('product_id', sa.Integer(), nullable=True))
    op.execute("""
        UPDATE order_items oi SET product_id = pv.product_id
        FROM product_variants pv WHERE pv.id = oi.variant_id
    """)
    op.alter_column('order_items', 'product_id', nullable=False)
    op.create_foreign_key(
        'order_items_product_id_fkey', 'order_items', 'products', ['product_id'], ['id'], ondelete='RESTRICT'
    )
    op.drop_index('ix_order_items_variant_id', table_name='order_items')
    op.drop_column('order_items', 'variant_id')

    # cart_items: variant_id -> product_id
    op.add_column('cart_items', sa.Column('product_id', sa.Integer(), nullable=True))
    op.execute("""
        UPDATE cart_items ci SET product_id = pv.product_id
        FROM product_variants pv WHERE pv.id = ci.variant_id
    """)
    op.alter_column('cart_items', 'product_id', nullable=False)
    op.create_foreign_key(
        'cart_items_product_id_fkey', 'cart_items', 'products', ['product_id'], ['id'], ondelete='CASCADE'
    )
    op.drop_constraint('uq_cart_user_variant', 'cart_items', type_='unique')
    op.drop_index('ix_cart_items_variant_id', table_name='cart_items')
    op.drop_column('cart_items', 'variant_id')
    op.create_unique_constraint('uq_cart_user_product', 'cart_items', ['user_id', 'product_id'])

    op.drop_index('ix_products_slug', table_name='products')
    op.drop_column('products', 'slug')
    op.add_column('products', sa.Column('stock', sa.Integer(), nullable=False, server_default='0'))
    op.add_column('products', sa.Column('price', sa.Numeric(12, 2), nullable=True))
    op.execute("""
        UPDATE products p SET price = pv.price, stock = pv.stock
        FROM product_variants pv
        WHERE pv.product_id = p.id AND pv.sort_order = (
            SELECT MIN(sort_order) FROM product_variants WHERE product_id = p.id
        )
    """)
    op.alter_column('products', 'price', nullable=False)

    op.drop_index('ix_variants_attributes_gin', table_name='product_variants')
    op.drop_index('ix_product_variants_sku', table_name='product_variants')
    op.drop_index('ix_product_variants_product_id', table_name='product_variants')
    op.drop_table('product_variants')
