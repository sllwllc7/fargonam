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
import '../kits/kit_detail_screen.dart';
import '../kits/kit_providers.dart';
import 'category_products_screen.dart';

class CategoryItem {
  final int id;
  final String name;
  final int productCount;
  CategoryItem({required this.id, required this.name, required this.productCount});
  factory CategoryItem.fromJson(Map<String, dynamic> j) => CategoryItem(
        id: j['id'] as int,
        name: j['name'] as String,
        productCount: j['product_count'] as int? ?? 0,
      );
}

final categoriesProvider = FutureProvider<List<CategoryItem>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/categories');
  return (res.data as List).cast<Map<String, dynamic>>().map(CategoryItem.fromJson).toList();
});

/// productId -> categoryId — savatdagi mahsulotlarni kategoriyaga bog'lash uchun.
final _productCategoryMapProvider = FutureProvider<Map<int, int>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/products', queryParameters: {'limit': 200});
  final items = (res.data['items'] as List).cast<Map<String, dynamic>>();
  return {for (final p in items) p['id'] as int: p['category_id'] as int? ?? -1};
});

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
    final catMapAsync = ref.watch(_productCategoryMapProvider);

    final cartByCategory = <int, int>{};
    if (cartAsync.hasValue && catMapAsync.hasValue) {
      for (final item in cartAsync.value!) {
        final pid = item['product_id'] as int?;
        final catId = pid != null ? catMapAsync.value![pid] : null;
        if (catId != null) {
          cartByCategory[catId] = (cartByCategory[catId] ?? 0) + ((item['quantity'] as int?) ?? 1);
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: 96.h),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: Text('Kategoriyalar', style: AppTextStyles.h1.copyWith(fontSize: 28)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(13.r)),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 16.sp, color: AppColors.textMuted),
                    SizedBox(width: 9.w),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        style: AppTextStyles.body.copyWith(color: AppColors.text, fontSize: 15),
                        decoration: InputDecoration.collapsed(
                          hintText: 'Kategoriya qidirish',
                          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 0),
              child: Text('SINFLAR UCHUN TAYYOR MAHSULOTLAR', style: AppTextStyles.sectionLabel),
            ),
            SizedBox(height: 12.h),
            kitsAsync.when(
              loading: () => SizedBox(
                height: 96.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  itemCount: 4,
                  separatorBuilder: (_, _) => SizedBox(width: 10.w),
                  itemBuilder: (_, _) => Container(
                    width: 158.w,
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18.r)),
                  ),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (kits) {
                if (kits.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text('Hozircha to\'plam yo\'q', style: AppTextStyles.caption),
                  );
                }
                return SizedBox(
                  height: 100.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4),
                    itemCount: kits.length,
                    separatorBuilder: (_, _) => SizedBox(width: 10.w),
                    itemBuilder: (context, i) {
                      final k = kits[i];
                      final tint = AppColors.categoryTints[i % AppColors.categoryTints.length];
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => KitDetailScreen(kit: k)));
                        },
                        child: Container(
                          width: 158.w,
                          padding: EdgeInsets.all(13.w),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppShadows.card,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: BoxDecoration(color: tint[0], borderRadius: BorderRadius.circular(13.r)),
                                child: Center(
                                  child: Text(k.gradeLevel ?? '?',
                                      style: AppTextStyles.cardTitle.copyWith(color: tint[1], fontSize: 17)),
                                ),
                              ),
                              SizedBox(height: 9.h),
                              Text(k.name, style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                              SizedBox(height: 2.h),
                              Text('${k.items.length} xil', style: AppTextStyles.caption.copyWith(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 10.h),
              child: Text('MAHSULOTLAR', style: AppTextStyles.sectionLabel),
            ),
            categoriesAsync.when(
              loading: () => Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Container(height: 240.h, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16.r))),
              ),
              error: (_, _) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text('Yuklab bo\'lmadi', style: AppTextStyles.caption),
              ),
              data: (cats) {
                final filtered = cats.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).toList()
                  ..sort((a, b) => a.name.compareTo(b.name));
                if (filtered.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 40.h),
                    child: Column(
                      children: [
                        Text('Hech narsa topilmadi', style: AppTextStyles.cardTitle),
                        SizedBox(height: 5.h),
                        Text('"$_query" bo\'yicha kategoriya yo\'q', style: AppTextStyles.caption),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < filtered.length; i++)
                          _CategoryRow(
                            category: filtered[i],
                            tint: AppColors.categoryTints[i % AppColors.categoryTints.length],
                            inCartCount: cartByCategory[filtered[i].id] ?? 0,
                            showDivider: i < filtered.length - 1,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.tint, required this.inCartCount, required this.showDivider});
  final CategoryItem category;
  final List<Color> tint;
  final int inCartCount;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryProductsScreen(categoryId: category.id, categoryName: category.name)));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          border: showDivider ? const Border(bottom: BorderSide(color: Color(0x0D000000))) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 92.w,
              height: 92.w,
              decoration: BoxDecoration(color: tint[0], borderRadius: BorderRadius.circular(20.r)),
              child: Icon(_iconFor(category.name), color: tint[1], size: 42.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name, style: AppTextStyles.cardTitle.copyWith(fontSize: 16.5)),
                  SizedBox(height: 2.h),
                  Text('${category.productCount} ta mahsulot', style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
                  if (inCartCount > 0)
                    Container(
                      margin: EdgeInsets.only(top: 7.h),
                      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                      decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(8.r)),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.6, end: 1),
                        duration: AppMotion.pop,
                        curve: AppMotion.screenInCurve,
                        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 10, color: AppColors.primaryDark),
                            SizedBox(width: 4.w),
                            Text('Savatda $inCartCount ta bor',
                                style: AppTextStyles.small.copyWith(color: AppColors.primaryDark, fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('ruchka') || n.contains('qalam')) return Icons.edit_outlined;
    if (n.contains('daftar') || n.contains('albom')) return Icons.menu_book_outlined;
    if (n.contains('qog')) return Icons.description_outlined;
    if (n.contains('flomaster') || n.contains('marker') || n.contains('rangli')) return Icons.brush_outlined;
    if (n.contains('ochirg') || n.contains("o'chirg")) return Icons.square_outlined;
    if (n.contains('lineyka')) return Icons.straighten_outlined;
    if (n.contains('yelim') || n.contains('skotch')) return Icons.local_offer_outlined;
    if (n.contains('qaychi')) return Icons.content_cut_outlined;
    if (n.contains('papka')) return Icons.folder_outlined;
    if (n.contains('kundalik')) return Icons.book_outlined;
    if (n.contains('qalamdon')) return Icons.inventory_2_outlined;
    if (n.contains('shtrix')) return Icons.format_color_fill_outlined;
    return Icons.category_outlined;
  }
}
