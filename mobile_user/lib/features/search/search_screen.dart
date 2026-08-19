import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_cached_image.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_shimmer.dart';
import '../products/product_detail_screen.dart';
import '../shops/shop_detail_screen.dart';

// ── Provayderlar ─────────────────────────────────────────────

class _SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String q) => state = q;
}

final searchQueryProvider =
    NotifierProvider<_SearchQueryNotifier, String>(_SearchQueryNotifier.new);

/// Qidiruv filtri — narx oralig'i + saralash. Backend `/products`da
/// allaqachon `min_price`/`max_price`/`sort` qo'llab-quvvatlaydi, lekin
/// hech qanday UI bu parametrlarni yubormasdi — shu bosqichda qo'shildi.
class SearchFilter {
  final double? minPrice;
  final double? maxPrice;
  final String? sort; // price_asc | price_desc | newest | rating
  const SearchFilter({this.minPrice, this.maxPrice, this.sort});
  bool get isActive => minPrice != null || maxPrice != null || sort != null;
}

class _SearchFilterNotifier extends Notifier<SearchFilter> {
  @override
  SearchFilter build() => const SearchFilter();
  void set(SearchFilter f) => state = f;
  void clear() => state = const SearchFilter();
}

final searchFilterProvider =
    NotifierProvider<_SearchFilterNotifier, SearchFilter>(_SearchFilterNotifier.new);

final searchProductsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final q = ref.watch(searchQueryProvider);
  if (q.trim().length < 2) return [];
  final filter = ref.watch(searchFilterProvider);
  final params = <String, dynamic>{'q': q, 'limit': 20};
  if (filter.minPrice != null) params['min_price'] = filter.minPrice;
  if (filter.maxPrice != null) params['max_price'] = filter.maxPrice;
  if (filter.sort != null) params['sort'] = filter.sort;
  final res = await ref.watch(dioProvider).get('/products', queryParameters: params);
  return ((res.data['items'] ?? []) as List).cast<Map<String, dynamic>>();
});

final searchShopsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final q = ref.watch(searchQueryProvider);
  if (q.trim().length < 2) return [];
  final res = await ref.watch(dioProvider).get('/shops', queryParameters: {'q': q});
  return (res.data as List).cast<Map<String, dynamic>>();
});

// ── Asosiy ekran ────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveSearch(String q) async {
    if (q.trim().isEmpty) return;
    _recentSearches.remove(q);
    _recentSearches.insert(0, q);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  void _onChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchQueryProvider.notifier).set(val);
    });
  }

  void _search(String q) {
    HapticFeedback.lightImpact();
    _ctrl.text = q;
    ref.read(searchQueryProvider.notifier).set(q);
    _saveSearch(q);
    _focus.unfocus();
  }

  Future<void> _clearRecent() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() => _recentSearches = []);
  }

  void _openFilter() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColorsDark.background : AppColors.background;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final caption = isDark ? AppTextStylesDark.caption : AppTextStyles.caption;
    final error = isDark ? AppColorsDark.error : AppColors.error;

    final query = ref.watch(searchQueryProvider);
    final filter = ref.watch(searchFilterProvider);
    final productsAsync = ref.watch(searchProductsProvider);
    final shopsAsync = ref.watch(searchShopsProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Container(
          margin: EdgeInsets.only(right: AppSpacing.sm),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(AppRadius.input)),
          child: Row(
            children: [
              Icon(Icons.search, color: textSecondary, size: 22.sp),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  onChanged: _onChanged,
                  onSubmitted: _search,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(color: textPrimary, fontSize: 15.sp),
                  decoration: InputDecoration(
                    hintText: 'Mahsulot yoki do\'kon...',
                    hintStyle: TextStyle(color: textSecondary, fontSize: 14.sp),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ),
              if (query.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _ctrl.clear();
                    ref.read(searchQueryProvider.notifier).set('');
                    _focus.requestFocus();
                  },
                  child: Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
                    child: Icon(Icons.close, size: 14, color: textSecondary),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: GestureDetector(
              onTap: _openFilter,
              child: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: filter.isActive ? primary : surface,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Icon(Icons.tune, color: filter.isActive ? Colors.white : textPrimary, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: query.trim().length < 2
          ? _RecentSearches(searches: _recentSearches, onTap: _search, onClear: _clearRecent)
          : ListView(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                shopsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (shops) {
                    if (shops.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.sm),
                          child: Text('DO\'KONLAR', style: caption.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1)),
                        ),
                        for (final shop in shops.take(5)) _ShopSearchTile(shop: shop),
                        SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Divider(height: 1, color: isDark ? AppColorsDark.border : AppColors.border),
                        ),
                      ],
                    );
                  },
                ),
                productsAsync.when(
                  loading: () => const _SearchResultsSkeleton(),
                  error: (e, _) => Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Text('Xato: $e', style: TextStyle(color: error)),
                  ),
                  data: (products) {
                    if (products.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: AppEmptyState(
                          icon: Icons.search_off,
                          title: '"$query" topilmadi',
                          subtitle: 'Boshqa kalit so\'z bilan urinib ko\'ring',
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.sm),
                          child: Text('MAHSULOTLAR (${products.length})',
                              style: caption.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1)),
                        ),
                        for (final p in products) _ProductSearchTile(product: p),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }
}

// ── Filtr bottom-sheet ───────────────────────────────────────

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();
  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  String? _sort;

  static const _sortOptions = [
    (null, 'Mashhur'),
    ('newest', 'Yangi'),
    ('price_asc', 'Arzon'),
    ('price_desc', 'Qimmat'),
  ];

  @override
  void initState() {
    super.initState();
    final f = ref.read(searchFilterProvider);
    _minCtrl = TextEditingController(text: f.minPrice?.toStringAsFixed(0) ?? '');
    _maxCtrl = TextEditingController(text: f.maxPrice?.toStringAsFixed(0) ?? '');
    _sort = f.sort;
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColorsDark.background : AppColors.background;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final title = isDark ? AppTextStylesDark.title : AppTextStyles.title;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Text('Saralash', style: title),
              SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final opt in _sortOptions)
                    AppChip(
                      label: opt.$2,
                      selected: _sort == opt.$1,
                      onTap: () => setState(() => _sort = opt.$1),
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.xl),
              Text('Narx oralig\'i (so\'m)', style: title),
              SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Min',
                        filled: true,
                        fillColor: surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _maxCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Max',
                        filled: true,
                        fillColor: surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Tozalash',
                      variant: AppButtonVariant.secondary,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(searchFilterProvider.notifier).clear();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: 'Qo\'llash',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(searchFilterProvider.notifier).set(SearchFilter(
                              minPrice: double.tryParse(_minCtrl.text),
                              maxPrice: double.tryParse(_maxCtrl.text),
                              sort: _sort,
                            ));
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Oxirgi qidiruvlar ────────────────────────────────────────

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({required this.searches, required this.onTap, required this.onClear});
  final List<String> searches;
  final void Function(String) onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final error = isDark ? AppColorsDark.error : AppColors.error;
    final title = isDark ? AppTextStylesDark.title : AppTextStyles.title;

    if (searches.isEmpty) {
      return AppEmptyState(
        icon: Icons.search,
        title: 'Nimani qidiryapsiz?',
        subtitle: 'Mahsulot, do\'kon yoki kategoriya nomini\nkiriting',
      );
    }
    return ListView(
      padding: EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Text('Oxirgi qidiruvlar', style: title),
            const Spacer(),
            TextButton(
              onPressed: onClear,
              child: Text('Tozalash', style: TextStyle(fontSize: 13.sp, color: error, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: searches
              .map((s) => GestureDetector(
                    onTap: () => onTap(s),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2.h),
                      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(AppRadius.chip)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history, size: 16, color: textSecondary),
                          SizedBox(width: AppSpacing.xs),
                          Text(s, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: textPrimary)),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ── Do'kon natijasi ──────────────────────────────────────────

class _ShopSearchTile extends StatelessWidget {
  const _ShopSearchTile({required this.shop});
  final Map<String, dynamic> shop;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      leading: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(AppRadius.input)),
        child: const Icon(Icons.store, color: Colors.white, size: 22),
      ),
      title: Text(shop['name'] as String, style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary)),
      subtitle: shop['description'] != null
          ? Text(shop['description'] as String,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, color: textSecondary))
          : null,
      trailing: Icon(Icons.chevron_right, size: 20, color: textSecondary),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => ShopDetailScreen(shopId: shop['id'] as int)));
      },
    );
  }
}

// ── Mahsulot natijasi ────────────────────────────────────────

class _ProductSearchTile extends StatelessWidget {
  const _ProductSearchTile({required this.product});
  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    final imgUrl = product['image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    final productId = product['id'] as int;
    final priceStr = product['price']?.toString() ?? '0';
    final price = double.tryParse(priceStr) ?? 0;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xs),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: Hero(
          tag: 'product_image_$productId',
          child: SizedBox(
            width: 56.w,
            height: 56.w,
            child: fullImg != null
                ? AppCachedImage(url: fullImg, width: 56.w, height: 56.w, borderRadius: 0)
                : Container(color: surface, child: Icon(Icons.image_outlined, size: 22, color: textSecondary)),
          ),
        ),
      ),
      title: Text(product['name'] as String,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp, color: textPrimary)),
      subtitle: Text(_formatPrice(price), style: TextStyle(fontWeight: FontWeight.w800, color: primary, fontSize: 13.sp)),
      trailing: product['shop_name'] != null
          ? Text(product['shop_name'] as String, style: TextStyle(fontSize: 11.sp, color: textSecondary))
          : null,
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: productId)));
      },
    );
  }
}

class _SearchResultsSkeleton extends StatelessWidget {
  const _SearchResultsSkeleton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: List.generate(
          5,
          (_) => Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                AppShimmer(width: 56.w, height: 56.w, borderRadius: AppRadius.input),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppShimmer(width: 160.w, height: 12.h),
                      SizedBox(height: AppSpacing.xs),
                      AppShimmer(width: 80.w, height: 12.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatPrice(num value) {
  final intStr = value.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(' ');
    buf.write(intStr[i]);
  }
  return '$buf so\'m';
}
