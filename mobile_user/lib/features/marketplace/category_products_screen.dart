import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';
import '../cart/cart_screen.dart' show cartProvider;
import '../favorites/favorites_screen.dart' show favoritesProvider;
import '../products/product_detail_screen.dart';

final categoryProductsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, categoryId) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/products', queryParameters: {'category_id': categoryId, 'limit': 200});
  return (res.data['items'] as List).cast<Map<String, dynamic>>();
});

/// Kategoriya ichi — HANDOFF.md 2-bo'lim, 4-band.
class CategoryProductsScreen extends ConsumerStatefulWidget {
  const CategoryProductsScreen({super.key, required this.categoryId, required this.categoryName});
  final int categoryId;
  final String categoryName;

  @override
  ConsumerState<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends ConsumerState<CategoryProductsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(categoryProductsProvider(widget.categoryId));
    final cartAsync = ref.watch(cartProvider);
    final favsAsync = ref.watch(favoritesProvider);

    final cartProductIds = <int>{};
    if (cartAsync.hasValue) {
      for (final it in cartAsync.value!) {
        final pid = it['product_id'] as int?;
        if (pid != null) cartProductIds.add(pid);
      }
    }
    final favIds = <int>{};
    if (favsAsync.hasValue) {
      for (final f in favsAsync.value!) {
        final pid = f['product_id'] as int?;
        if (pid != null) favIds.add(pid);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Text('Yuklab bo\'lmadi: $e', style: AppTextStyles.caption)),
          data: (allProducts) {
            final products = allProducts.where((p) {
              if (_query.isEmpty) return true;
              final q = _query.toLowerCase();
              return (p['name'] as String? ?? '').toLowerCase().contains(q) ||
                  (p['brand'] as String? ?? '').toLowerCase().contains(q);
            }).toList();

            return ListView(
              padding: EdgeInsets.only(bottom: 96.h),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                          child: Icon(Icons.arrow_back_ios_new, size: 15.sp, color: AppColors.text),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.categoryName, style: AppTextStyles.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${allProducts.length} ta mahsulot', style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12.r)),
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 14.sp, color: AppColors.textMuted),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: TextField(
                                  onChanged: (v) => setState(() => _query = v),
                                  style: AppTextStyles.body.copyWith(fontSize: 14, color: AppColors.text),
                                  decoration: InputDecoration.collapsed(
                                    hintText: '${widget.categoryName} ichida qidirish',
                                    hintStyle: AppTextStyles.body.copyWith(fontSize: 14, color: AppColors.textMuted),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (products.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 56.h),
                    child: Column(
                      children: [
                        Text('Mahsulot topilmadi', style: AppTextStyles.cardTitle),
                        SizedBox(height: 5.h),
                        Text('Qidiruvni o\'zgartirib ko\'ring', style: AppTextStyles.caption),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: 0.66,
                      ),
                      itemBuilder: (context, i) => _ProductCard(
                        product: products[i],
                        inCart: cartProductIds.contains(products[i]['id']),
                        isFav: favIds.contains(products[i]['id']),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProductCard extends ConsumerStatefulWidget {
  const _ProductCard({required this.product, required this.inCart, required this.isFav});
  final Map<String, dynamic> product;
  final bool inCart;
  final bool isFav;

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard> {
  bool _favBusy = false;

  Future<void> _toggleFav() async {
    HapticFeedback.selectionClick();
    setState(() => _favBusy = true);
    try {
      final dio = ref.read(dioProvider);
      final id = widget.product['id'];
      if (widget.isFav) {
        await dio.delete('/favorites/$id');
      } else {
        await dio.post('/favorites/$id');
      }
      ref.invalidate(favoritesProvider);
    } finally {
      if (mounted) setState(() => _favBusy = false);
    }
  }

  String _priceLabel() {
    final minP = widget.product['min_price'];
    final maxP = widget.product['max_price'];
    if (minP == null) return '—';
    final lo = double.tryParse(minP.toString())?.toInt() ?? 0;
    final hi = double.tryParse((maxP ?? minP).toString())?.toInt() ?? lo;
    String fmt(int n) {
      final s = n.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
        buf.write(s[i]);
      }
      return buf.toString();
    }
    return lo == hi ? '${fmt(lo)} so\'m' : '${fmt(lo)} – ${fmt(hi)} so\'m';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final totalStock = p['total_stock'] as int? ?? 0;
    final out = totalStock <= 0;
    final variantCount = (p['variants'] as List?)?.length ?? 1;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p['id'] as int)));
      },
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(12.r)),
                    child: Icon(Icons.inventory_2_outlined, color: AppColors.primaryDark, size: 44.sp),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: _favBusy ? null : _toggleFav,
                    child: Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), shape: BoxShape.circle),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: widget.isFav ? 0.6 : 1, end: 1),
                        duration: AppMotion.pop,
                        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                        child: Icon(
                          widget.isFav ? Icons.favorite : Icons.favorite_border,
                          size: 14.sp,
                          color: widget.isFav ? AppColors.textMuted : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                if (out)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                      decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(6.r)),
                      child: Text('Tugagan', style: AppTextStyles.small.copyWith(color: Colors.white, fontSize: 10)),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 9.h),
            Text(p['name'] as String? ?? '', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 2.h),
            Text(
              [p['brand'], if (variantCount > 1) '$variantCount variant'].where((s) => s != null && s.toString().isNotEmpty).join(' · '),
              style: AppTextStyles.caption.copyWith(fontSize: 11.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: Text(_priceLabel(), style: AppTextStyles.cardTitle.copyWith(fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    color: widget.inCart ? AppColors.textMuted : AppColors.text,
                    shape: BoxShape.circle,
                    boxShadow: [const BoxShadow(color: Color(0x2E191970), blurRadius: 8, offset: Offset(0, 3))],
                  ),
                  child: Icon(widget.inCart ? Icons.check : Icons.add, color: AppColors.bg, size: 15.sp),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
