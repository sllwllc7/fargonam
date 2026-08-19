import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../shop/shop_providers.dart' show ShopStatus, myShopProvider;
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
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: _appBar('Market'),
        body: ErrorRetryWidget(error: e, onRetry: () => ref.invalidate(myShopProvider)),
      ),
      data: (shop) {
        if (shop == null) {
          return Scaffold(backgroundColor: AppColors.background, appBar: _appBar('Market'), body: const _NoShopState());
        }
        if (shop.status != ShopStatus.approved) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: _appBar('Market'),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Icon(
                        shop.status == ShopStatus.rejected ? Icons.cancel_outlined : Icons.hourglass_empty,
                        color: shop.status == ShopStatus.rejected ? AppColors.danger : AppColors.warning,
                        size: 44,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      shop.status == ShopStatus.rejected ? 'Do\'koningiz rad etilgan' : 'Do\'koningiz tasdiqlanmagan',
                      style: AppTypography.cardTitle,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      shop.status == ShopStatus.rejected
                          ? 'Mahsulot yuklash uchun admin bilan bog\'laning: support@fargonam.uz'
                          : 'Mahsulot yuklash uchun admin tasdiqini kuting.',
                      style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return _ProductGroupsList(shopId: shop.id);
      },
    );
  }
}

PreferredSizeWidget _appBar(String title) => AppBar(
      backgroundColor: AppColors.background,
      title: Text(title, style: AppTypography.title),
    );

/// Umumiy nom bo'yicha guruh — masalan "Ruchka" ostidagi barcha mahsulot qatorlari.
class _ProductGroup {
  const _ProductGroup({required this.name, required this.products});
  final String name;
  final List<Product> products;
}

class _ProductGroupsList extends ConsumerWidget {
  const _ProductGroupsList({required this.shopId});
  final int shopId;

  Future<void> _addProduct(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final created = await pushAppRoute<bool>(context, (_) => AddProductScreen(shopId: shopId));
    if (created == true) ref.invalidate(shopProductsProvider(shopId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(shopProductsProvider(shopId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar('Market'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () => _addProduct(context, ref),
        child: const Icon(Icons.add, size: 28),
      ),
      body: productsAsync.when(
        loading: () => const _ProductsSkeleton(),
        error: (e, _) => ErrorRetryWidget(error: e, onRetry: () => ref.invalidate(shopProductsProvider(shopId))),
        data: (products) {
          if (products.isEmpty) return const _EmptyProductsState();
          final byName = <String, List<Product>>{};
          for (final p in products) {
            byName.putIfAbsent(p.name.trim(), () => []).add(p);
          }
          final groups = byName.entries.map((e) => _ProductGroup(name: e.key, products: e.value)).toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              HapticFeedback.lightImpact();
              ref.invalidate(shopProductsProvider(shopId));
            },
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(20, 12, 20, AppSizes.tabBarHeight + AppSizes.tabBarBottomInset),
              itemCount: groups.length,
              separatorBuilder: (_, _) => SizedBox(height: 10),
              itemBuilder: (context, i) => _GroupTile(shopId: shopId, group: groups[i]),
            ),
          );
        },
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.shopId, required this.group});
  final int shopId;
  final _ProductGroup group;

  @override
  Widget build(BuildContext context) {
    final first = group.products.first;
    final imgUrl = first.imageUrl != null ? '${AppConfig.apiBaseUrl}${first.imageUrl}' : null;

    return PressableScale(
      onTap: () {
        HapticFeedback.lightImpact();
        pushAppRoute(context, (_) => _ProductsList(shopId: shopId, groupName: group.name));
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.image),
              child: SizedBox(
                width: 64,
                height: 64,
                child: imgUrl != null
                    ? Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.primaryLight,
                          child: Icon(Icons.broken_image, color: AppColors.textMuted),
                        ),
                      )
                    : Container(color: AppColors.primaryLight, child: Icon(Icons.image_outlined, color: AppColors.textMuted)),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.cardTitleSm),
                  SizedBox(height: 5),
                  Text(group.products.length > 1 ? '${group.products.length} ta tur' : '1 ta tur',
                      style: AppTypography.caption),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
            SizedBox(width: 6),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _NoShopState extends StatelessWidget {
  const _NoShopState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Icon(Icons.storefront_outlined, size: 42, color: AppColors.textMuted),
            ),
            SizedBox(height: 20),
            Text('Avval do\'kon yarating', style: AppTypography.cardTitle),
            SizedBox(height: 8),
            Text('Bosh sahifada do\'kon yaratishingiz mumkin',
                textAlign: TextAlign.center, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ProductsList extends ConsumerWidget {
  const _ProductsList({required this.shopId, this.groupName});
  final int shopId;
  final String? groupName;

  Future<void> _addProduct(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final created = await pushAppRoute<bool>(context, (_) => AddProductScreen(shopId: shopId));
    if (created == true) ref.invalidate(shopProductsProvider(shopId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(shopProductsProvider(shopId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(groupName ?? 'Mahsulotlar'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () => _addProduct(context, ref),
        child: const Icon(Icons.add, size: 28),
      ),
      body: productsAsync.when(
        loading: () => const _ProductsSkeleton(),
        error: (e, _) => ErrorRetryWidget(error: e, onRetry: () => ref.invalidate(shopProductsProvider(shopId))),
        data: (allProducts) {
          final products = groupName == null
              ? allProducts
              : allProducts.where((p) => p.name.trim().toLowerCase() == groupName!.trim().toLowerCase()).toList();
          if (products.isEmpty) return const _EmptyProductsState();
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              HapticFeedback.lightImpact();
              ref.invalidate(shopProductsProvider(shopId));
            },
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 100),
              itemCount: products.length,
              separatorBuilder: (_, _) => SizedBox(height: 10),
              itemBuilder: (context, i) => _ProductTile(product: products[i]),
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
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Icon(Icons.inventory_2_outlined, size: 42, color: AppColors.textMuted),
            ),
            SizedBox(height: 20),
            Text('Hali mahsulot yo\'q', style: AppTypography.cardTitle),
            SizedBox(height: 8),
            Text('Pastdagi tugma bilan birinchi mahsulotingizni qo\'shing',
                textAlign: TextAlign.center, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
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
      padding: EdgeInsets.all(20),
      itemCount: 5,
      separatorBuilder: (_, _) => SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
        child: Row(
          children: [
            ShimmerBox(width: 64, height: 64, borderRadius: AppRadius.image),
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
  Future<void> _delete() async {
    HapticFeedback.lightImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('Mahsulotni o\'chirish'),
        content: Text('"${widget.product.name}" ni o\'chirmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Yo\'q')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      try {
        await ref.read(dioProvider).delete('/products/${widget.product.id}');
        ref.invalidate(shopProductsProvider(widget.product.shopId));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('O\'chirishda xato: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  Future<void> _edit() async {
    HapticFeedback.lightImpact();
    final edited = await pushAppRoute<bool>(context, (_) => EditProductScreen(product: widget.product));
    if (edited == true) ref.invalidate(shopProductsProvider(widget.product.shopId));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final imgUrl = p.imageUrl != null ? '${AppConfig.apiBaseUrl}${p.imageUrl}' : null;
    final stockColor = p.stock > 0 ? AppColors.success : AppColors.danger;

    return PressableScale(
      scale: 0.98,
      onTap: _edit,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.image),
              child: SizedBox(
                width: 64,
                height: 64,
                child: imgUrl != null
                    ? Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Container(color: AppColors.primaryLight, child: Icon(Icons.broken_image, color: AppColors.textMuted)),
                      )
                    : Container(color: AppColors.primaryLight, child: Icon(Icons.image_outlined, color: AppColors.textMuted)),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.cardTitleSm),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Text(formatSom(double.tryParse(p.price) ?? 0), style: AppTypography.price.copyWith(fontSize: 14)),
                      SizedBox(width: 10),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration:
                            BoxDecoration(color: stockColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(6)),
                        child: Text(p.stock > 0 ? 'Bor: ${p.stock}' : 'Tugagan',
                            style: AppTypography.small.copyWith(color: stockColor, fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 22),
              onPressed: _delete,
            ),
          ],
        ),
      ),
    );
  }
}
