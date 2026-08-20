import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/api_client.dart';
import '../cart/cart_screen.dart' show CartScreen, cartProvider;
import '../kits/kit_detail_screen.dart';
import '../kits/kit_providers.dart';
import 'category_icons.dart';
import 'category_products_screen.dart';

class CategoryItem {
  final int id;
  final String name;
  final String slug;
  final int productCount;
  CategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.productCount,
  });
  factory CategoryItem.fromJson(Map<String, dynamic> j) => CategoryItem(
    id: j['id'] as int,
    name: j['name'] as String,
    slug: j['slug'] as String? ?? '',
    productCount: j['product_count'] as int? ?? 0,
  );
}

final categoriesProvider = FutureProvider<List<CategoryItem>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/categories');
  return (res.data as List)
      .cast<Map<String, dynamic>>()
      .map(CategoryItem.fromJson)
      .toList();
});

/// productId -> categoryId — savatdagi mahsulotlarni kategoriyaga bog'lash uchun.
final productCategoryMapProvider = FutureProvider<Map<int, int>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/products', queryParameters: {'limit': 200});
  final items = (res.data['items'] as List).cast<Map<String, dynamic>>();
  return {
    for (final p in items) p['id'] as int: p['category_id'] as int? ?? -1,
  };
});

const _searchIconSvg =
    '<svg viewBox="0 0 20 20"><circle cx="9" cy="9" r="6" stroke="#000" stroke-width="1.8" fill="none"/><path d="m14 14 4 4" stroke="#000" stroke-width="1.8" stroke-linecap="round"/></svg>';

const _checkIconSvg =
    '<svg viewBox="0 0 12 10"><path d="m1 5 3.5 3.5L11 1" stroke="#16A34A" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/></svg>';

const _chevronIconSvg =
    '<svg viewBox="0 0 8 14"><path d="m1 1 6 6-6 6" stroke="#000" stroke-width="2" stroke-linecap="round" fill="none"/></svg>';

/// Market (catalog) — HANDOFF.md 2-bo'lim, 2-band.
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final kitsAsync = ref.watch(kitsProvider);
    final cartAsync = ref.watch(cartProvider);
    final catMapAsync = ref.watch(productCategoryMapProvider);

    final cartByCategory = <int, int>{};
    if (cartAsync.hasValue && catMapAsync.hasValue) {
      for (final item in cartAsync.value!) {
        final pid = item['product_id'] as int?;
        final catId = pid != null ? catMapAsync.value![pid] : null;
        if (catId != null) {
          cartByCategory[catId] =
              (cartByCategory[catId] ?? 0) + ((item['quantity'] as int?) ?? 1);
        }
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
              child: ListView(
                padding: EdgeInsets.only(
                  bottom:
                      AppSizes.tabBarHeight + AppSizes.tabBarBottomInset + 22,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Text('Kategoriyalar', style: AppTypography.h1),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.string(
                            _searchIconSvg,
                            width: 16,
                            height: 16,
                            colorFilter: const ColorFilter.mode(
                              AppColors.textMuted,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: TextField(
                              onChanged: (v) => setState(() => _query = v),
                              style: AppTypography.bodyLg.copyWith(
                                letterSpacing: 0,
                                height: null,
                              ),
                              decoration: InputDecoration.collapsed(
                                hintText: 'Kategoriya qidirish',
                                hintStyle: AppTypography.bodyLg.copyWith(
                                  letterSpacing: 0,
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Text(
                      'Sinflar uchun tayyor mahsulotlar'.toUpperCase(),
                      style: AppTypography.sectionLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  kitsAsync.when(
                    loading: () => SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: 4,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, _) => const ShimmerBox(
                          width: 158,
                          height: 100,
                          borderRadius: AppRadius.card,
                        ),
                      ),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (kits) {
                      if (kits.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Hozircha to\'plam yo\'q',
                            style: AppTypography.caption,
                          ),
                        );
                      }
                      return SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          itemCount: kits.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final k = kits[i];
                            final tint =
                                AppColors.categoryTints[i %
                                    AppColors.categoryTints.length];
                            return FadeUpItem(
                              delay: AppMotion.staggerStep * i,
                              child: _KitCard(kit: k, tint: tint),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  categoriesAsync.when(
                    loading: () => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: const ShimmerBox(
                        width: double.infinity,
                        height: 240,
                        borderRadius: AppRadius.groupedCard,
                      ),
                    ),
                    error: (_, _) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: Text(
                        'Yuklab bo\'lmadi',
                        style: AppTypography.caption,
                      ),
                    ),
                    data: (cats) {
                      final filtered =
                          cats
                              .where(
                                (c) => c.name.toLowerCase().contains(
                                  _query.toLowerCase(),
                                ),
                              )
                              .toList()
                            ..sort((a, b) => a.name.compareTo(b.name));
                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 64,
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: SvgPicture.string(
                                  _searchIconSvg,
                                  width: 22,
                                  height: 22,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.textSecondary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Hech narsa topilmadi',
                                style: AppTypography.cardTitle,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '“$_query” bo‘yicha kategoriya yo‘q',
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mahsulotlar'.toUpperCase(),
                              style: AppTypography.sectionLabel,
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.groupedCard,
                                ),
                                border: Border.all(color: AppColors.border),
                                boxShadow: AppShadows.card,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  for (var i = 0; i < filtered.length; i++)
                                    _CategoryRow(
                                      category: filtered[i],
                                      tint:
                                          AppColors.categoryTints[i %
                                              AppColors.categoryTints.length],
                                      inCartCount:
                                          cartByCategory[filtered[i].id] ?? 0,
                                      showDivider: i < filtered.length - 1,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
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

class _KitCard extends StatefulWidget {
  const _KitCard({required this.kit, required this.tint});
  final Kit kit;
  final List<Color> tint;

  @override
  State<_KitCard> createState() => _KitCardState();
}

class _KitCardState extends State<_KitCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        pushAppRoute(context, (_) => KitDetailScreen(kit: widget.kit));
      },
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: AppMotion.pressedDuration,
        child: Container(
          width: 158,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.tint[0],
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.kit.gradeLevel ?? '?',
                  style: AppTypography.cardTitle.copyWith(
                    color: widget.tint[1],
                    fontSize: 21,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                widget.kit.name,
                style: AppTypography.cardTitleSm.copyWith(fontSize: 13.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.kit.items.length} xil · ${formatSom(widget.kit.total)}',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  height: null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatefulWidget {
  const _CategoryRow({
    required this.category,
    required this.tint,
    required this.inCartCount,
    required this.showDivider,
  });
  final CategoryItem category;
  final List<Color> tint;
  final int inCartCount;
  final bool showDivider;

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        pushAppRoute(
          context,
          (_) => CategoryProductsScreen(
            categoryId: widget.category.id,
            categoryName: widget.category.name,
            categorySlug: widget.category.slug,
          ),
        );
      },
      child: AnimatedContainer(
        duration: AppMotion.pressedDuration,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _pressed ? AppColors.background : Colors.transparent,
          border: widget.showDivider
              ? const Border(bottom: BorderSide(color: Color(0x0D000000)))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: widget.tint[0],
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: SvgPicture.string(
                categorySvg(widget.category.slug),
                width: 46,
                height: 46,
                colorFilter: ColorFilter.mode(widget.tint[1], BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.category.name, style: AppTypography.cardTitle),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.category.productCount} ta mahsulot',
                    style: AppTypography.caption.copyWith(height: null),
                  ),
                  if (widget.inCartCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.6, end: 1),
                        duration: AppMotion.pop,
                        curve: AppMotion.standard,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.string(
                              _checkIconSvg,
                              width: 10,
                              height: 8,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Savatda ${widget.inCartCount} ta bor',
                              style: AppTypography.badgeText.copyWith(
                                fontSize: 11.5,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SvgPicture.string(
              _chevronIconSvg,
              width: 8,
              height: 14,
              colorFilter: const ColorFilter.mode(
                AppColors.textSecondary,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
