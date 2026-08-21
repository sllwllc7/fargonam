import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/api_client.dart';
import '../marketplace/catalog_screen.dart' show categoriesProvider, productCategoryMapProvider;
import '../marketplace/category_icons.dart';
import '../products/product_detail_screen.dart';
import '../shell/app_shell.dart' show appShellKey;

final favoritesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get('/favorites');
  return (res.data as List).cast<Map<String, dynamic>>();
});

const _heartOutlineIconSvg =
    '<svg viewBox="0 0 24 24"><path d="M12 20 4.8 13a4.6 4.6 0 1 1 6.5-6.5l.7.7.7-.7A4.6 4.6 0 1 1 19.2 13Z" stroke="#1C1C22" stroke-width="1.7" stroke-linejoin="round" fill="none"/></svg>';

/// Sevimlilar — HANDOFF.md 2-bo'lim, 15-band.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favsAsync = ref.watch(favoritesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final catMapAsync = ref.watch(productCategoryMapProvider);
    final categories = categoriesAsync.value ?? const [];
    final catMap = catMapAsync.value ?? const {};

    List<Color> tintFor(int productId) {
      final catId = catMap[productId];
      return AppColors.categoryTints[(catId ?? 0) % AppColors.categoryTints.length];
    }

    String slugFor(int productId) {
      final catId = catMap[productId];
      for (final c in categories) {
        if (c.id == catId) return c.slug;
      }
      return '';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ScreenFadeIn(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    BackCircleButton(onTap: () => Navigator.maybePop(context)),
                    const SizedBox(width: 12),
                    Text('Sevimlilar', style: AppTypography.h2),
                  ],
                ),
              ),
              Expanded(
                child: favsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => Center(child: Text('Yuklab bo\'lmadi', style: AppTypography.caption)),
                  data: (favs) {
                    if (favs.isEmpty) return const _EmptyFavorites();
                    return RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () async {
                        HapticFeedback.lightImpact();
                        ref.invalidate(favoritesProvider);
                      },
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        itemCount: favs.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          // 0.72'da haqiqiy qurilmada (katta tizim shrifti)
                          // narx qatori bir necha o'ndan bir pikselga
                          // toshib, "BOTTOM OVERFLOWED" bannerini chiqarardi
                          // — kartaga sal ko'proq bo'yi berildi.
                          childAspectRatio: 0.68,
                        ),
                        itemBuilder: (context, i) => FadeUpItem(
                          delay: AppMotion.staggerStep * i,
                          child: _FavoriteCard(
                            item: favs[i],
                            tint: tintFor(favs[i]['product_id'] as int),
                            slug: slugFor(favs[i]['product_id'] as int),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteCard extends ConsumerStatefulWidget {
  const _FavoriteCard({required this.item, required this.tint, required this.slug});
  final Map<String, dynamic> item;
  final List<Color> tint;
  final String slug;

  @override
  ConsumerState<_FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends ConsumerState<_FavoriteCard> {
  bool _removing = false;

  Future<void> _remove() async {
    if (_removing) return;
    HapticFeedback.selectionClick();
    setState(() => _removing = true);
    try {
      final productId = widget.item['product_id'] as int;
      await ref.read(dioProvider).delete('/favorites/$productId');
      ref.invalidate(favoritesProvider);
    } catch (_) {
      if (mounted) setState(() => _removing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final productId = item['product_id'] as int;
    final imgUrl = item['product_image_url'] as String?;
    final price = double.tryParse(item['product_price']?.toString() ?? '') ?? 0;

    return PressableScale(
      onTap: () {
        HapticFeedback.lightImpact();
        pushAppRoute(context, (_) => ProductDetailScreen(productId: productId));
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
                    imageUrl: imgUrl,
                    categorySlug: widget.slug,
                    tint: widget.tint,
                    borderRadius: AppRadius.input,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: _remove,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: _removing
                          ? const Padding(padding: EdgeInsets.all(6), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted))
                          : const FavoriteHeartIcon(active: true, size: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(item['product_name'] as String? ?? '', style: AppTypography.cardTitleSm.copyWith(height: 1.25), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(formatSom(price), style: AppTypography.priceSm, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: SvgPicture.string(_heartOutlineIconSvg, width: 30, height: 30),
            ),
            const SizedBox(height: 20),
            Text('Sevimlilar bo\'sh', style: AppTypography.cardTitle.copyWith(fontSize: 17, letterSpacing: -0.4)),
            const SizedBox(height: 8),
            Text(
              'Mahsulot kartasidagi yurakchani bosib, yoqqanlaringizni shu yerga saqlang',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.textMuted, fontSize: 13.5, height: 1.45),
            ),
            const SizedBox(height: 18),
            PressableScale(
              scale: 0.96,
              onTap: () {
                HapticFeedback.selectionClick();
                appShellKey.currentState?.switchTab(0);
                Navigator.maybePop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(color: AppColors.primaryDeep, borderRadius: BorderRadius.circular(AppRadius.button)),
                child: Text('Marketga o\'tish', style: AppTypography.rowTitle.copyWith(color: AppColors.ctaText)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
