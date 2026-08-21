import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/api_client.dart';
import '../cart/cart_screen.dart' show CartScreen, cartProvider;
import '../favorites/favorites_screen.dart' show favoritesProvider;
import '../products/product_detail_screen.dart';
import 'category_icons.dart';

final categoryProductsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((
      ref,
      categoryId,
    ) async {
      final dio = ref.watch(dioProvider);
      final res = await dio.get(
        '/products',
        queryParameters: {'category_id': categoryId, 'limit': 200},
      );
      return (res.data['items'] as List).cast<Map<String, dynamic>>();
    });

const _searchIconSvg =
    '<svg viewBox="0 0 20 20"><circle cx="9" cy="9" r="6" stroke="#3F3F49" stroke-width="1.8" fill="none"/><path d="m14 14 4 4" stroke="#3F3F49" stroke-width="1.8" stroke-linecap="round"/></svg>';
const _filterIconSvg =
    '<svg viewBox="0 0 16 16"><path d="M1 3h14M4 8h8M6.5 13h3" stroke="#000" stroke-width="1.7" stroke-linecap="round"/></svg>';

/// Kategoriya ichi — HANDOFF.md 2-bo'lim, 4-band.
class CategoryProductsScreen extends ConsumerStatefulWidget {
  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categorySlug,
  });
  final int categoryId;
  final String categoryName;
  final String categorySlug;

  @override
  ConsumerState<CategoryProductsScreen> createState() =>
      _CategoryProductsScreenState();
}

class _CategoryProductsScreenState
    extends ConsumerState<CategoryProductsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(
      categoryProductsProvider(widget.categoryId),
    );
    final cartAsync = ref.watch(cartProvider);
    final favsAsync = ref.watch(favoritesProvider);
    final tint = AppColors
        .categoryTints[widget.categoryId % AppColors.categoryTints.length];

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
    final cartCount = cartAsync.maybeWhen(
      data: (items) =>
          items.fold<int>(0, (s, it) => s + ((it['quantity'] as int?) ?? 1)),
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ScreenFadeIn(
              child: productsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Yuklab bo\'lmadi: $e',
                    style: AppTypography.caption,
                  ),
                ),
                data: (allProducts) {
                  final products = allProducts.where((p) {
                    if (_query.isEmpty) return true;
                    final q = _query.toLowerCase();
                    return (p['name'] as String? ?? '').toLowerCase().contains(
                          q,
                        ) ||
                        (p['brand'] as String? ?? '').toLowerCase().contains(q);
                  }).toList();

                  return ListView(
                    padding: EdgeInsets.only(
                      bottom:
                          AppSizes.tabBarHeight +
                          AppSizes.tabBarBottomInset +
                          22,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          children: [
                            BackCircleButton(
                              onTap: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.categoryName,
                                    style: AppTypography.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${allProducts.length} ta mahsulot',
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.input,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SvgPicture.string(
                                      _searchIconSvg,
                                      width: 14,
                                      height: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        onChanged: (v) =>
                                            setState(() => _query = v),
                                        style: AppTypography.body.copyWith(
                                          fontSize: 14,
                                          height: null,
                                          color: AppColors.textPrimary,
                                        ),
                                        decoration: InputDecoration.collapsed(
                                          hintText:
                                              '${widget.categoryName} ichida qidirish',
                                          hintStyle: AppTypography.body
                                              .copyWith(
                                                fontSize: 14,
                                                height: null,
                                                color: AppColors.textMuted,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PressableScale(
                              scale: 0.95,
                              onTap: () {},
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.input,
                                  ),
                                  border: Border.all(
                                    color: AppColors.inputBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SvgPicture.string(
                                      _filterIconSvg,
                                      width: 13,
                                      height: 13,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Filtr',
                                      style: AppTypography.rowTitle.copyWith(
                                        fontSize: 13.5,
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
                          padding: const EdgeInsets.symmetric(
                            vertical: 56,
                            horizontal: 40,
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Mahsulot topilmadi',
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Qidiruvni o\'zgartirib ko\'ring',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: products.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  // 0.66'da haqiqiy qurilmada (katta tizim
                                  // shrifti) narx/tugma qatori 13px toshib
                                  // ketardi — kartaga ko'proq bo'yi berildi.
                                  childAspectRatio: 0.6,
                                ),
                            itemBuilder: (context, i) => FadeUpItem(
                              delay: AppMotion.staggerStep * i,
                              child: _ProductCard(
                                product: products[i],
                                slug: widget.categorySlug,
                                categoryName: widget.categoryName,
                                tint: tint,
                                inCart: cartProductIds.contains(
                                  products[i]['id'],
                                ),
                                isFav: favIds.contains(products[i]['id']),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          CartFab(
            cartCount: cartCount,
            onTap: () {
              HapticFeedback.lightImpact();
              pushAppRoute(context, (_) => const CartScreen());
            },
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends ConsumerStatefulWidget {
  const _ProductCard({
    required this.product,
    required this.slug,
    required this.categoryName,
    required this.tint,
    required this.inCart,
    required this.isFav,
  });
  final Map<String, dynamic> product;
  final String slug;
  final String categoryName;
  final List<Color> tint;
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
    return lo == hi ? formatSom(lo) : '${formatSom(lo)} – ${formatSom(hi)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final totalStock = p['total_stock'] as int? ?? 0;
    final out = totalStock <= 0;
    final variantCount = (p['variants'] as List?)?.length ?? 1;

    return PressableScale(
      onTap: () {
        HapticFeedback.lightImpact();
        pushAppRoute(
          context,
          (_) => ProductDetailScreen(productId: p['id'] as int),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.groupedCard),
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
                  child: ProductThumb(
                    imageUrl: (p['thumb_url'] ?? p['image_url']) as String?,
                    categorySlug: widget.slug,
                    tint: widget.tint,
                    borderRadius: AppRadius.input,
                    fallbackLabel: Text(
                      widget.categoryName.toLowerCase(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: widget.tint[1].withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ),
                if (out)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Tugagan',
                        style: AppTypography.small.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: _favBusy ? null : _toggleFav,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: FavoriteHeartIcon(active: widget.isFav, size: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              p['name'] as String? ?? '',
              style: AppTypography.cardTitleSm,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              [
                p['brand'],
                if (variantCount > 1) '$variantCount variant',
              ].where((s) => s != null && s.toString().isNotEmpty).join(' · '),
              style: AppTypography.caption.copyWith(fontSize: 11.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _priceLabel(),
                    style: AppTypography.priceSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: widget.inCart
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F171327),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.inCart ? Icons.check : Icons.add,
                    color: AppColors.background,
                    size: 15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
