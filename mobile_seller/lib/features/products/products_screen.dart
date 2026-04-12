import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../shop/shop_providers.dart' show Shop, ShopStatus, myShopProvider;
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'products_providers.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(myShopProvider);

    return shopAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.cream)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(title: const Text('Mahsulotlar')),
        body: ErrorRetryWidget(
            error: e, onRetry: () => ref.invalidate(myShopProvider)),
      ),
      data: (shop) {
        if (shop == null) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(title: const Text('Mahsulotlar')),
            body: const _NoShopState(),
          );
        }
        // Do'kon tasdiqlanmagan bo'lsa — ogohlantirish
        if (shop.status != ShopStatus.approved) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(title: const Text('Mahsulotlar')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Icon(
                        shop.status == ShopStatus.rejected
                            ? Icons.cancel_outlined
                            : Icons.hourglass_empty,
                        color: shop.status == ShopStatus.rejected
                            ? AppColors.error
                            : AppColors.warning,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      shop.status == ShopStatus.rejected
                          ? 'Do\'koningiz rad etilgan'
                          : 'Do\'koningiz tasdiqlanmagan',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      shop.status == ShopStatus.rejected
                          ? 'Mahsulot yuklash uchun admin bilan bog\'laning: support@fargonam.uz'
                          : 'Mahsulot yuklash uchun admin tasdiqini kuting.',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return _ProductsList(shopId: shop.id);
      },
    );
  }
}

class _NoShopState extends StatelessWidget {
  const _NoShopState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.store,
                  size: 56, color: AppColors.cream),
            ),
            const SizedBox(height: 24),
            const Text(
              'Avval do\'kon yarating',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dashboard tabida do\'kon yaratishingiz mumkin',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsList extends ConsumerWidget {
  const _ProductsList({required this.shopId});
  final int shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(shopProductsProvider(shopId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Mahsulotlar')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.midnightIndigo,
        icon: const Icon(Icons.add),
        label: const Text(
          'Qo\'shish',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        onPressed: () async {
          HapticFeedback.lightImpact();
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => AddProductScreen(shopId: shopId)),
          );
          if (created == true) {
            ref.invalidate(shopProductsProvider(shopId));
          }
        },
      ),
      body: productsAsync.when(
        loading: () => const _ProductsSkeleton(),
        error: (e, _) => ErrorRetryWidget(
          error: e,
          onRetry: () =>
              ref.invalidate(shopProductsProvider(shopId)),
        ),
        data: (products) {
          if (products.isEmpty) return const _EmptyProductsState();
          return RefreshIndicator(
            color: AppColors.cream,
            backgroundColor: AppColors.surfaceHigh,
            onRefresh: () async {
              HapticFeedback.lightImpact();
              ref.invalidate(shopProductsProvider(shopId));
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  _ProductTile(product: products[i]),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  size: 56, color: AppColors.cream),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hali mahsulot yo\'q',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pastdagi tugma bilan birinchi mahsulotingizni qo\'shing',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsSkeleton extends StatelessWidget {
  const _ProductsSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: const [
            ShimmerBox(width: 64, height: 64, borderRadius: 12),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 140, height: 14),
                  SizedBox(height: 8),
                  ShimmerBox(width: 100, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends ConsumerStatefulWidget {
  const _ProductTile({required this.product});
  final Product product;

  @override
  ConsumerState<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends ConsumerState<_ProductTile> {
  bool _pressed = false;

  Future<void> _delete() async {
    HapticFeedback.lightImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mahsulotni o\'chirish'),
        content: Text(
          '"${widget.product.name}" ni o\'chirmoqchimisiz?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Yo\'q')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      await ref
          .read(dioProvider)
          .delete('/products/${widget.product.id}');
      ref.invalidate(shopProductsProvider(widget.product.shopId));
    }
  }

  Future<void> _edit() async {
    HapticFeedback.lightImpact();
    final edited = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => EditProductScreen(product: widget.product)),
    );
    if (edited == true) {
      ref.invalidate(shopProductsProvider(widget.product.shopId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final imgUrl =
        p.imageUrl != null ? '${AppConfig.apiBaseUrl}${p.imageUrl}' : null;
    final stockColor =
        p.stock > 0 ? AppColors.success : AppColors.error;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _edit,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: imgUrl != null
                      ? Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.surfaceHigh,
                            child: const Icon(Icons.broken_image,
                                color: AppColors.textMuted),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceHigh,
                          child: const Icon(Icons.image_outlined,
                              color: AppColors.textMuted)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          formatPrice(double.tryParse(p.price) ?? 0),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.cream,
                              fontSize: 14),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.stock > 0
                                ? 'Bor: ${p.stock}'
                                : 'Tugagan',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: stockColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.error, size: 22),
                onPressed: _delete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
