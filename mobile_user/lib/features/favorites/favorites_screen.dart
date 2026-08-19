import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';
import '../products/product_detail_screen.dart';
import '../shell/app_shell.dart' show appShellKey;

final favoritesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get('/favorites');
  return (res.data as List).cast<Map<String, dynamic>>();
});

/// Sevimlilar — HANDOFF.md 2-bo'lim, 15-band.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favsAsync = ref.watch(favoritesProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.maybePop(context);
                    },
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                      child: Icon(Icons.arrow_back_ios_new, size: 15.sp, color: AppColors.text),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text('Sevimlilar', style: AppTextStyles.h2.copyWith(fontSize: 23)),
                ],
              ),
            ),
            Expanded(
              child: favsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('Yuklab bo\'lmadi', style: AppTextStyles.caption)),
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
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
                      itemCount: favs.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: 0.72,
                      ),
                      itemBuilder: (context, i) => _FavoriteCard(item: favs[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteCard extends ConsumerStatefulWidget {
  const _FavoriteCard({required this.item});
  final Map<String, dynamic> item;

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
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    final price = double.tryParse(item['product_price']?.toString() ?? '') ?? 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: productId)));
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
                    child: fullImg != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(12.r), child: Image.network(fullImg, fit: BoxFit.cover))
                        : Icon(Icons.inventory_2_outlined, color: AppColors.primaryDark, size: 40.sp),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: _remove,
                    child: Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), shape: BoxShape.circle),
                      child: _removing
                          ? Padding(padding: EdgeInsets.all(6.w), child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted))
                          : Icon(Icons.favorite, size: 14.sp, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 9.h),
            Text(item['product_name'] as String? ?? '', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 6.h),
            Text(formatSom(price), style: AppTextStyles.cardTitle.copyWith(fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
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
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96.w,
              height: 96.w,
              decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
              child: Icon(Icons.favorite_border, size: 40.sp, color: AppColors.textSecondary),
            ),
            SizedBox(height: 20.h),
            Text('Sevimlilar bo\'sh', style: AppTextStyles.cardTitle.copyWith(fontSize: 17)),
            SizedBox(height: 8.h),
            Text('Mahsulot kartasidagi yurakchani bosib, yoqqanlaringizni shu yerga saqlang',
                textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontSize: 13.5)),
            SizedBox(height: 18.h),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                appShellKey.currentState?.switchTab(0);
                Navigator.maybePop(context);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
                decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(14.r)),
                child: Text('Marketga o\'tish', style: AppTextStyles.cardTitleSm.copyWith(color: Colors.white, fontSize: 14.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
