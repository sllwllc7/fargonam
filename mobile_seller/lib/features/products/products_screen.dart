import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: _appBar('Market'),
        body: ErrorRetryWidget(error: e, onRetry: () => ref.invalidate(myShopProvider)),
      ),
      data: (shop) {
        if (shop == null) {
          return Scaffold(backgroundColor: AppColors.bg, appBar: _appBar('Market'), body: const _NoShopState());
        }
        if (shop.status != ShopStatus.approved) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: _appBar('Market'),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(28.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Icon(
                        shop.status == ShopStatus.rejected ? Icons.cancel_outlined : Icons.hourglass_empty,
                        color: shop.status == ShopStatus.rejected ? AppColors.danger : AppColors.warning,
                        size: 44.sp,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      shop.status == ShopStatus.rejected ? 'Do\'koningiz rad etilgan' : 'Do\'koningiz tasdiqlanmagan',
                      style: AppTextStyles.cardTitle,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      shop.status == ShopStatus.rejected
                          ? 'Mahsulot yuklash uchun admin bilan bog\'laning: support@fargonam.uz'
                          : 'Mahsulot yuklash uchun admin tasdiqini kuting.',
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
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
      backgroundColor: AppColors.bg,
      title: Text(title, style: AppTextStyles.title),
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
    final created =
        await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => AddProductScreen(shopId: shopId)));
    if (created == true) ref.invalidate(shopProductsProvider(shopId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(shopProductsProvider(shopId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _appBar('Market'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.sellerAccent,
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
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
              itemCount: groups.length,
              separatorBuilder: (_, _) => SizedBox(height: 10.h),
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

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _ProductsList(shopId: shopId, groupName: group.name)),
        );
      },
      child: Container(
        padding: EdgeInsets.all(12.w),
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
                width: 64.w,
                height: 64.w,
                child: imgUrl != null
                    ? Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFFEDE9FE),
                          child: Icon(Icons.broken_image, color: AppColors.textMuted),
                        ),
                      )
                    : Container(color: const Color(0xFFEDE9FE), child: Icon(Icons.image_outlined, color: AppColors.textMuted)),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.cardTitleSm),
                  SizedBox(height: 5.h),
                  Text(group.products.length > 1 ? '${group.products.length} ta tur' : '1 ta tur',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 18.sp, color: AppColors.textSecondary),
            SizedBox(width: 6.w),
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
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96.w,
              height: 96.w,
              decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
              child: Icon(Icons.storefront_outlined, size: 42.sp, color: AppColors.textMuted),
            ),
            SizedBox(height: 20.h),
            Text('Avval do\'kon yarating', style: AppTextStyles.cardTitle),
            SizedBox(height: 8.h),
            Text('Bosh sahifada do\'kon yaratishingiz mumkin',
                textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
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
    final created =
        await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => AddProductScreen(shopId: shopId)));
    if (created == true) ref.invalidate(shopProductsProvider(shopId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(shopProductsProvider(shopId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _appBar(groupName ?? 'Mahsulotlar'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.sellerAccent,
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
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
              itemCount: products.length,
              separatorBuilder: (_, _) => SizedBox(height: 10.h),
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
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96.w,
              height: 96.w,
              decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
              child: Icon(Icons.inventory_2_outlined, size: 42.sp, color: AppColors.textMuted),
            ),
            SizedBox(height: 20.h),
            Text('Hali mahsulot yo\'q', style: AppTextStyles.cardTitle),
            SizedBox(height: 8.h),
            Text('Pastdagi tugma bilan birinchi mahsulotingizni qo\'shing',
                textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
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
      padding: EdgeInsets.all(20.w),
      itemCount: 5,
      separatorBuilder: (_, _) => SizedBox(height: 10.h),
      itemBuilder: (_, _) => Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
        child: Row(
          children: [
            ShimmerBox(width: 64.w, height: 64.w, borderRadius: AppRadius.image),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 140.w, height: 14),
                  SizedBox(height: 8.h),
                  ShimmerBox(width: 100.w, height: 14),
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
    final edited = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProductScreen(product: widget.product)),
    );
    if (edited == true) ref.invalidate(shopProductsProvider(widget.product.shopId));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final imgUrl = p.imageUrl != null ? '${AppConfig.apiBaseUrl}${p.imageUrl}' : null;
    final stockColor = p.stock > 0 ? AppColors.success : AppColors.danger;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _edit,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: EdgeInsets.all(12.w),
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
                  width: 64.w,
                  height: 64.w,
                  child: imgUrl != null
                      ? Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Container(color: const Color(0xFFEDE9FE), child: Icon(Icons.broken_image, color: AppColors.textMuted)),
                        )
                      : Container(color: const Color(0xFFEDE9FE), child: Icon(Icons.image_outlined, color: AppColors.textMuted)),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.cardTitleSm),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Text(formatSom(double.tryParse(p.price) ?? 0), style: AppTextStyles.price.copyWith(fontSize: 14)),
                        SizedBox(width: 10.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration:
                              BoxDecoration(color: stockColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(6.r)),
                          child: Text(p.stock > 0 ? 'Bor: ${p.stock}' : 'Tugagan',
                              style: AppTextStyles.small.copyWith(color: stockColor, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, size: 18.sp, color: AppColors.textSecondary),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 22),
                onPressed: _delete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
