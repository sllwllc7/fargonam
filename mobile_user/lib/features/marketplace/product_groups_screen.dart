import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_cached_image.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_shimmer.dart';
import '../search/search_screen.dart';
import 'marketplace_screen.dart' show CartBadgeButton, MarketplaceScreen;

/// Umumiy nomdagi mahsulotlar guruhi — masalan "Ruchka" ostida turli xil
/// ruchkalar (alohida Product qatorlari, har biri o'z variantlariga ega
/// bo'lishi mumkin).
class ProductGroup {
  const ProductGroup({
    required this.name,
    required this.imageUrl,
    required this.itemCount,
    this.minPrice,
    this.maxPrice,
  });
  final String name;
  final String? imageUrl;
  final int itemCount;
  final num? minPrice;
  final num? maxPrice;
}

/// Katalogdagi barcha mahsulotlarni nomi bo'yicha guruhlaydi (client-side —
/// MVP-1'da katalog kichik, alohida backend endpoint shart emas).
final productGroupsProvider = FutureProvider<List<ProductGroup>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/products', queryParameters: {'limit': 200});
  final items = ((res.data['items'] ?? []) as List).cast<Map<String, dynamic>>();

  final byName = <String, List<Map<String, dynamic>>>{};
  for (final it in items) {
    final name = (it['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) continue;
    byName.putIfAbsent(name, () => []).add(it);
  }

  final groups = byName.entries.map((e) {
    num? minP, maxP;
    for (final it in e.value) {
      final mn = num.tryParse(it['min_price']?.toString() ?? '');
      final mx = num.tryParse(it['max_price']?.toString() ?? '');
      if (mn != null) minP = (minP == null || mn < minP) ? mn : minP;
      if (mx != null) maxP = (maxP == null || mx > maxP) ? mx : maxP;
    }
    return ProductGroup(
      name: e.key,
      imageUrl: e.value.first['image_url'] as String?,
      itemCount: e.value.length,
      minPrice: minP,
      maxPrice: maxP,
    );
  }).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  return groups;
});

/// Marketplace 1-bosqich: umumiy nomlar ro'yxati (Ruchka, Daftar, Rangli
/// qalam, ...). Birortasiga bosilsa — [MarketplaceScreen] o'sha nom bilan
/// filtrlangan holda ochiladi.
class ProductGroupsScreen extends ConsumerWidget {
  const ProductGroupsScreen({super.key});

  void _openSearch(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColorsDark.background : AppColors.background;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final h1 = isDark ? AppTextStylesDark.h1 : AppTextStyles.h1;

    final groupsAsync = ref.watch(productGroupsProvider);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: primary,
          backgroundColor: background,
          onRefresh: () async {
            HapticFeedback.lightImpact();
            ref.invalidate(productGroupsProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: background,
                surfaceTintColor: Colors.transparent,
                floating: true,
                snap: true,
                toolbarHeight: 64.h,
                title: Text('Marketplace', style: h1),
                leading: IconButton(
                  icon: Icon(Icons.search, color: textPrimary),
                  onPressed: () => _openSearch(context),
                ),
                actions: const [CartBadgeButton()],
              ),
              groupsAsync.when(
                loading: () => const _GroupsSkeleton(),
                error: (e, _) => SliverFillRemaining(
                  child: AppErrorState(
                    error: e,
                    onRetry: () => ref.invalidate(productGroupsProvider),
                  ),
                ),
                data: (groups) {
                  if (groups.isEmpty) {
                    return SliverFillRemaining(
                      child: AppEmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Mahsulotlar mavjud emas',
                        subtitle: 'Tez orada yangi mahsulotlar qo\'shiladi',
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.md),
                          child: _GroupTile(group: groups[i]),
                        ),
                        childCount: groups.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group});
  final ProductGroup group;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;

    final fullImg = group.imageUrl != null ? '${AppConfig.apiBaseUrl}${group.imageUrl}' : null;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MarketplaceScreen(groupName: group.name)),
        );
      },
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(AppRadius.card)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.input),
              child: SizedBox(
                width: 56.w,
                height: 56.w,
                child: fullImg != null
                    ? AppCachedImage(url: fullImg, borderRadius: 0, fit: BoxFit.cover)
                    : Container(color: isDark ? AppColorsDark.background : AppColors.background, child: Icon(Icons.image_outlined, color: textSecondary)),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: textPrimary)),
                  SizedBox(height: 4.h),
                  Text(
                    group.itemCount > 1 ? '${group.itemCount} ta tur' : '1 ta tur',
                    style: TextStyle(fontSize: 12.sp, color: textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (group.minPrice != null)
              Padding(
                padding: EdgeInsets.only(right: AppSpacing.sm),
                child: Text(
                  _formatGroupPrice(group.minPrice!, group.maxPrice),
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: primary),
                ),
              ),
            Icon(Icons.chevron_right, color: textSecondary),
          ],
        ),
      ),
    );
  }
}

class _GroupsSkeleton extends StatelessWidget {
  const _GroupsSkeleton();
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, _) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: AppShimmer(height: 80.h, borderRadius: AppRadius.card),
          ),
          childCount: 6,
        ),
      ),
    );
  }
}

String _formatGroupPrice(num min, num? max) {
  String fmt(num v) {
    final intStr = v.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < intStr.length; i++) {
      if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(' ');
      buf.write(intStr[i]);
    }
    return buf.toString();
  }

  if (max == null || max == min) return '${fmt(min)} so\'m';
  return '${fmt(min)}+';
}
