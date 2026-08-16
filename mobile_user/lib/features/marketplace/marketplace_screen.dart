import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart' as tokens;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_cached_image.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_shimmer.dart';
import '../cart/cart_screen.dart';
import '../products/product_detail_screen.dart';
import '../search/search_screen.dart';

// ── Provayderlar (o'zgarishsiz — biznes-logika, faqat UI qayta chizilgan) ──

/// Do'konlar ro'yxati
final shopsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.keepAlive();
  final res = await ref.watch(dioProvider).get('/shops');
  return (res.data as List).cast<Map<String, dynamic>>();
});

/// Marketplace filtr holati
class MarketFilter {
  final int? categoryId;
  final String? query;
  final String? groupName;
  const MarketFilter({this.categoryId, this.query, this.groupName});
}

class _FilterNotifier extends Notifier<MarketFilter> {
  @override
  MarketFilter build() => const MarketFilter();
  void update(MarketFilter f) => state = f;
  void setQuery(String? q) =>
      state = MarketFilter(categoryId: state.categoryId, query: q, groupName: state.groupName);
  void setCategory(int? id) =>
      state = MarketFilter(categoryId: id, query: state.query, groupName: state.groupName);
  void setGroupName(String? name) =>
      state = MarketFilter(categoryId: state.categoryId, query: state.query, groupName: name);
}

final marketFilterProvider =
    NotifierProvider<_FilterNotifier, MarketFilter>(_FilterNotifier.new);

/// Paginated mahsulotlar holati
class PaginatedProducts {
  final List<Map<String, dynamic>> items;
  final int total;
  final bool loading;
  final String? error;
  const PaginatedProducts(
      {this.items = const [], this.total = 0, this.loading = false, this.error});
  bool get hasMore => items.length < total;
}

class PaginatedProductsNotifier extends Notifier<PaginatedProducts> {
  static const _pageSize = 20;
  // Guruh bo'yicha (bitta umumiy nom) ko'rilganda hammasi bitta so'rovda
  // olinadi — pagination shart emas, katalog kichik (MVP-1).
  static const _groupPageSize = 200;

  @override
  PaginatedProducts build() {
    ref.watch(marketFilterProvider);
    _loadFirst();
    return const PaginatedProducts(loading: true);
  }

  Future<void> _loadFirst() async {
    state = const PaginatedProducts(loading: true);
    try {
      final data = await _fetch(0);
      state = PaginatedProducts(
        items: data['items'],
        total: data['total'],
      );
    } catch (e) {
      state = PaginatedProducts(error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    if (ref.read(marketFilterProvider).groupName != null) return;
    state = PaginatedProducts(
        items: state.items, total: state.total, loading: true);
    try {
      final data = await _fetch(state.items.length);
      state = PaginatedProducts(
        items: [...state.items, ...data['items']],
        total: data['total'],
      );
    } catch (e) {
      state = PaginatedProducts(
          items: state.items, total: state.total, error: e.toString());
    }
  }

  Future<void> refresh() async => _loadFirst();

  Future<Map<String, dynamic>> _fetch(int offset) async {
    final dio = ref.read(dioProvider);
    final f = ref.read(marketFilterProvider);
    final grouped = f.groupName != null;
    final p = <String, dynamic>{'limit': grouped ? _groupPageSize : _pageSize, 'offset': offset};
    if (f.categoryId != null) p['category_id'] = f.categoryId;
    if (grouped) {
      p['q'] = f.groupName;
    } else if (f.query != null && f.query!.isNotEmpty) {
      p['q'] = f.query;
    }
    final res = await dio.get('/products', queryParameters: p);
    var items =
        ((res.data['items'] ?? []) as List).cast<Map<String, dynamic>>();
    var total = res.data['total'] as int? ?? 0;
    if (grouped) {
      // Backend'dagi 'q' qisman moslik (ILIKE) beradi — masalan "Qalam" so'ralganda
      // "Rangli qalam" ham tushib qolishi mumkin. Guruh nomi bilan ANIQ mos
      // kelganlarnigina qoldiramiz.
      final target = f.groupName!.trim().toLowerCase();
      items = items.where((it) => (it['name'] as String).trim().toLowerCase() == target).toList();
      total = items.length;
    }
    return {'items': items, 'total': total};
  }
}

final paginatedProductsProvider =
    NotifierProvider<PaginatedProductsNotifier, PaginatedProducts>(
        PaginatedProductsNotifier.new);

// ── Asosiy ekran ────────────────────────────────────────────

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key, this.groupName});
  /// Berilsa — faqat shu umumiy nomdagi mahsulotlar ko'rsatiladi
  /// (masalan "Ruchka" guruhi ichidagi hamma turlar).
  final String? groupName;
  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    if (widget.groupName != null) {
      // Widget hali build bo'layotganda provider'ni to'g'ridan-to'g'ri
      // o'zgartirib bo'lmaydi (Riverpod bu holatni taqiqlaydi) —
      // build tsikli tugagach ishga tushadigan microtask'ga kechiktiramiz.
      Future.microtask(() {
        if (mounted) ref.read(marketFilterProvider.notifier).setGroupName(widget.groupName);
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    if (widget.groupName != null) {
      final notifier = ref.read(marketFilterProvider.notifier);
      Future.microtask(() => notifier.setGroupName(null));
    }
    super.dispose();
  }

  DateTime _lastScrollLoad = DateTime(2000);
  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      final now = DateTime.now();
      if (now.difference(_lastScrollLoad).inMilliseconds < 500) return;
      _lastScrollLoad = now;
      ref.read(paginatedProductsProvider.notifier).loadMore();
    }
  }

  void _openSearch() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Sahifa foni (#f8f9fa) — kartochka/qidiruv foni (AppColors.background,
    // paper-white)dan atayin farqlangan, mockup shu ikki qatlamli fonni
    // ishlatadi. Dark rejimda eski indigo fon saqlanadi.
    final pageBg = isDark ? AppColorsDark.background : tokens.AppColors.background;
    final surface = isDark ? AppColorsDark.surface : AppColors.background;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;

    final filter = ref.watch(marketFilterProvider);
    final prods = ref.watch(paginatedProductsProvider);

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: primary,
          backgroundColor: surface,
          onRefresh: () async {
            HapticFeedback.lightImpact();
            ref.read(paginatedProductsProvider.notifier).refresh();
          },
          child: CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              // ── APP BAR ──
              SliverAppBar(
                backgroundColor: surface,
                surfaceTintColor: Colors.transparent,
                floating: true,
                snap: true,
                toolbarHeight: 64.h,
                title: Text(
                  widget.groupName ?? 'Marketplace',
                  style: tokens.AppTypography.headlineMd
                      .copyWith(color: textPrimary, fontWeight: FontWeight.w700),
                ),
                leading: widget.groupName != null
                    ? IconButton(
                        icon: Icon(Icons.arrow_back, color: textPrimary),
                        onPressed: () => Navigator.maybePop(context),
                      )
                    : IconButton(
                        icon: Icon(Icons.search, color: textPrimary),
                        onPressed: _openSearch,
                      ),
                actions: const [CartBadgeButton()],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(color: isDark ? AppColorsDark.border : AppColors.border, height: 1),
                ),
              ),

              // ── SEARCH BAR (tap → SearchScreen) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.xl, 8.h, AppSpacing.xl, 0),
                  child: GestureDetector(
                    onTap: _openSearch,
                    child: Container(
                      height: tokens.AppSizes.searchInput,
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(tokens.AppRadius.xl),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: textSecondary, size: 20.sp),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Qidiruv...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tokens.AppTypography.bodyMd.copyWith(color: textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── PROMO BANNER ──
              SliverToBoxAdapter(
                child: _PromoBanner(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _scrollCtrl.animateTo(
                      _scrollCtrl.position.maxScrollExtent * 0.5,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              ),

              // ── KATEGORIYA FILTRI (faqat Bosh sahifadan kategoriya bosilganda faollashadi) ──
              if (filter.categoryId != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                    child: _ActiveFilterChip(
                      onClear: () {
                        HapticFeedback.lightImpact();
                        ref.read(marketFilterProvider.notifier).setCategory(null);
                      },
                    ),
                  ),
                ),

              // ── MAHSULOTLAR SARLAVHASI ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
                  child: Text(
                    widget.groupName != null
                        ? '${widget.groupName} turlari'
                        : (filter.categoryId != null ? 'Kategoriya mahsulotlari' : 'Tavsiya etilganlar'),
                    style: tokens.AppTypography.headlineMd.copyWith(color: textPrimary),
                  ),
                ),
              ),

              // ── MAHSULOTLAR GRID ──
              if (prods.error != null && prods.items.isEmpty)
                SliverFillRemaining(
                  child: AppErrorState(
                    error: prods.error!,
                    onRetry: () => ref.read(paginatedProductsProvider.notifier).refresh(),
                  ),
                )
              else if (prods.items.isEmpty && prods.loading)
                const _ProductsGridSkeleton()
              else if (prods.items.isEmpty)
                SliverFillRemaining(
                  child: AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: filter.categoryId != null
                        ? 'Bu kategoriyada mahsulot yo\'q'
                        : 'Mahsulotlar mavjud emas',
                    subtitle: 'Tez orada yangi mahsulotlar qo\'shiladi',
                    action: filter.categoryId != null
                        ? AppButton(
                            label: 'Barcha mahsulotlar',
                            icon: Icons.refresh,
                            fullWidth: false,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref.read(marketFilterProvider.notifier).setCategory(null);
                            },
                          )
                        : AppButton(
                            label: 'Qidirish',
                            icon: Icons.search,
                            fullWidth: false,
                            onPressed: _openSearch,
                          ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _ProductCard(
                        product: prods.items[i],
                        showQuickAdd: widget.groupName != null,
                      ),
                      childCount: prods.items.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.lg,
                      crossAxisSpacing: AppSpacing.lg,
                      // Guruh/kategoriya ko'rinishida tezkor qo'shish qatori
                      // qo'shimcha balandlik talab qiladi.
                      childAspectRatio: widget.groupName != null ? 0.5 : 0.58,
                    ),
                  ),
                ),
                if (prods.loading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Center(child: CircularProgressIndicator(color: primary)),
                    ),
                  ),
                if (!prods.hasMore && prods.items.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 100.h),
                      child: Center(
                        child: Text('${prods.total} ta mahsulot',
                            style: (isDark ? AppTextStylesDark.caption : AppTextStyles.caption)),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cart badge tugma ────────────────────────────────────────

class CartBadgeButton extends ConsumerWidget {
  const CartBadgeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final error = isDark ? AppColorsDark.error : AppColors.error;
    final background = isDark ? AppColorsDark.background : AppColors.background;

    final cartAsync = ref.watch(cartProvider);
    final count = cartAsync.maybeWhen(data: (items) => items.length, orElse: () => 0);
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.shopping_cart_outlined, color: textPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
          },
        ),
        if (count > 0)
          Positioned(
            top: 8.h,
            right: 6.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
              constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.h),
              decoration: BoxDecoration(
                color: error,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: background, width: 1.5),
              ),
              child: Center(
                child: Text('$count',
                    style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Promo Banner ────────────────────────────────────────────

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final primaryLight = isDark ? AppColorsDark.primaryLight : AppColors.primaryLight;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 168.h,
          decoration: BoxDecoration(
            color: primaryLight.withValues(alpha: isDark ? 1 : 0.5),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -30,
                child: Container(
                  width: 130.w,
                  height: 130.w,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: primary.withValues(alpha: 0.12)),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'MAXSUS TAKLIF',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Birinchi buyurtma\nuchun chegirma!',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(AppRadius.chip)),
                      child: Text('Xarid qilish',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.sp)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Faol filtr chip (Bosh sahifadan kategoriya bosilganda) ──

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final primaryLight = isDark ? AppColorsDark.primaryLight : AppColors.primaryLight;

    return GestureDetector(
      onTap: onClear,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: primaryLight.withValues(alpha: isDark ? 1 : 0.5),
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Kategoriya bo\'yicha filtrlangan',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: primary)),
            SizedBox(width: AppSpacing.xs),
            Icon(Icons.close, size: 16, color: primary),
          ],
        ),
      ),
    );
  }
}

// ── Mahsulot kartasi ────────────────────────────────────────

class _ProductCard extends ConsumerStatefulWidget {
  const _ProductCard({required this.product, this.showQuickAdd = false});
  final Map<String, dynamic> product;
  /// Kategoriya/guruh bo'yicha ko'rilganda +1/+5/+10 tez qo'shish qatori
  /// ko'rinadi (mockup: "Kategoriya" ekrani). Umumiy tavsiya ro'yxatida
  /// (mockup: "Marketplace") bitta add-tugma yetarli.
  final bool showQuickAdd;

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard> {
  bool _addingToCart = false;
  bool _addedToCart = false;
  bool _favOptimistic = false;
  bool _favBusy = false;

  List<Map<String, dynamic>> get _variants =>
      ((widget.product['variants'] as List?) ?? const []).cast<Map<String, dynamic>>();
  bool get _hasMultipleVariants => _variants.length > 1;

  void _openDetail() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: widget.product['id'] as int)),
    );
  }

  Future<void> _addToCart({int quantity = 1}) async {
    // Bir nechta turi bo'lgan mahsulotda qaysi turini olishini tanlashi kerak —
    // to'g'ridan-to'g'ri "standart" turdan qo'shib qo'yish o'rniga ekranga o'tkazamiz.
    if (_hasMultipleVariants) {
      _openDetail();
      return;
    }
    if (_addingToCart || _addedToCart) return;
    HapticFeedback.mediumImpact();
    setState(() => _addingToCart = true);
    try {
      await ref.read(dioProvider).post('/cart', data: {
        'product_id': widget.product['id'] as int,
        'quantity': quantity,
      });
      ref.invalidate(cartProvider);
      if (!mounted) return;
      setState(() {
        _addingToCart = false;
        _addedToCart = true;
      });
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        _showCartSnackBar(
          context,
          text: 'Savatchaga qo\'shildi',
          color: isDark ? AppColorsDark.success : AppColors.success,
        );
      }
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _addedToCart = false);
      });
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() => _addingToCart = false);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        _showCartSnackBar(
          context,
          text: e.response?.data['detail']?.toString() ?? 'Savatchaga qo\'shilmadi',
          color: isDark ? AppColorsDark.error : AppColors.error,
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favBusy) return;
    HapticFeedback.lightImpact();
    setState(() {
      _favOptimistic = !_favOptimistic;
      _favBusy = true;
    });
    try {
      final productId = widget.product['id'] as int;
      if (_favOptimistic) {
        await ref.read(dioProvider).post('/favorites/$productId');
      } else {
        await ref.read(dioProvider).delete('/favorites/$productId');
      }
    } catch (_) {
      if (mounted) setState(() => _favOptimistic = !_favOptimistic);
    } finally {
      if (mounted) setState(() => _favBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final success = isDark ? AppColorsDark.success : AppColors.success;
    final cardBg = isDark ? AppColorsDark.surface : AppColors.background;
    final border = isDark ? AppColorsDark.border : AppColors.border;
    final imgBg = isDark ? AppColorsDark.surfaceAlt : tokens.AppColors.vanillaCream.withValues(alpha: 0.25);
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final warning = isDark ? AppColorsDark.error : tokens.AppColors.statusWarning;
    final error = isDark ? AppColorsDark.error : AppColors.error;

    final p = widget.product;
    final imgUrl = p['image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    final productId = p['id'] as int;
    final totalStock = int.tryParse(p['total_stock']?.toString() ?? p['stock']?.toString() ?? '');
    final isOutOfStock = totalStock != null && totalStock <= 0;
    final createdAt = DateTime.tryParse(p['created_at']?.toString() ?? '');
    final isNew = !isOutOfStock &&
        createdAt != null &&
        DateTime.now().difference(createdAt).inDays <= 7;
    final priceLabel = _hasMultipleVariants
        ? _formatPriceRange(p['min_price'], p['max_price'])
        : _formatPrice(p['price']?.toString() ?? '0');
    final priceParts = priceLabel.split(' so\'m');
    final canQuickAdd = widget.showQuickAdd && !_hasMultipleVariants && !isOutOfStock;

    return Opacity(
      opacity: isOutOfStock ? 0.6 : 1,
      child: _PressableScale(
        onTap: _openDetail,
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(tokens.AppRadius.xl),
            border: Border.all(color: border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rasm
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'product_image_$productId',
                      child: _maybeGrayscale(
                        isOutOfStock,
                        fullImg != null
                            ? AppCachedImage(url: fullImg, borderRadius: 0, fit: BoxFit.cover)
                            : _ImagePlaceholder(color: imgBg, iconColor: textSecondary),
                      ),
                    ),
                    if (isNew || isOutOfStock)
                      Positioned(
                        top: AppSpacing.sm,
                        left: AppSpacing.sm,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: isOutOfStock ? error : warning,
                            borderRadius: BorderRadius.circular(tokens.AppRadius.sm),
                          ),
                          child: Text(
                            isOutOfStock ? 'Sotuvda yo\'q' : 'Yangi',
                            style: tokens.AppTypography.labelSm.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    // Favorite tugma
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleFavorite,
                        child: AnimatedScale(
                          scale: _favOptimistic ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 180),
                          child: Container(
                            width: 34.w,
                            height: 34.w,
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), shape: BoxShape.circle),
                            child: Icon(
                              _favOptimistic ? Icons.favorite : Icons.favorite_border,
                              color: _favOptimistic ? error : textPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Ma'lumotlar
              Expanded(
                flex: canQuickAdd ? 5 : 4,
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p['shop_name'] != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 2.h),
                          child: Text(
                            p['shop_name'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tokens.AppTypography.labelSm.copyWith(color: textSecondary, fontSize: 10),
                          ),
                        ),
                      Text(
                        p['name'] as String,
                        maxLines: canQuickAdd ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: tokens.AppTypography.bodyMd.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              priceParts.first,
                              maxLines: 1,
                              style: tokens.AppTypography.priceDisplay.copyWith(color: primary),
                            ),
                            if (priceParts.length > 1)
                              Text(' so\'m',
                                  style: tokens.AppTypography.labelSm.copyWith(color: textSecondary)),
                          ],
                        ),
                      ),
                      if (canQuickAdd) ...[
                        SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [1, 5, 10].map((qty) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: qty == 10 ? 0 : 4.w),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _addToCart(quantity: qty),
                                  child: Container(
                                    height: 28.h,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: primary,
                                      borderRadius: BorderRadius.circular(tokens.AppRadius.sm),
                                    ),
                                    child: _addingToCart
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                                          )
                                        : Text('+$qty',
                                            style: tokens.AppTypography.labelSm.copyWith(color: Colors.white, fontSize: 11)),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        SizedBox(height: AppSpacing.xs),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: isOutOfStock ? null : _addToCart,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 32.w,
                              height: 32.w,
                              decoration: BoxDecoration(
                                color: isOutOfStock ? textSecondary : (_addedToCart ? success : primary),
                                borderRadius: BorderRadius.circular(tokens.AppRadius.sm),
                              ),
                              child: _addingToCart
                                  ? const Padding(
                                      padding: EdgeInsets.all(7),
                                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                                    )
                                  : Icon(
                                      _hasMultipleVariants
                                          ? Icons.chevron_right
                                          : (_addedToCart ? Icons.check : Icons.add),
                                      color: Colors.white,
                                      size: 16,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pressable scale wrapper ─────────────────────────────────

class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

// ── Skeleton/placeholder widgetlar ──────────────────────────

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.color, required this.iconColor});
  final Color color;
  final Color iconColor;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Icon(Icons.image_outlined, size: 40, color: iconColor),
    );
  }
}

class _ProductsGridSkeleton extends StatelessWidget {
  const _ProductsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
          childAspectRatio: 0.58,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, _) => AppShimmer(height: double.infinity, borderRadius: AppRadius.card),
          childCount: 6,
        ),
      ),
    );
  }
}

/// "Sotuvda yo'q" mahsulot rasmini kul rang qiladi (mockup: grayscale filter).
Widget _maybeGrayscale(bool grayscale, Widget child) {
  if (!grayscale) return child;
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix(<double>[
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0, 0, 0, 1, 0,
    ]),
    child: child,
  );
}

/// Narxni chiroyli formatlash: 1250000 -> 1 250 000 so'm
String _formatPrice(String raw) {
  final num = double.tryParse(raw);
  if (num == null) return '$raw so\'m';
  final intStr = num.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(' ');
    buf.write(intStr[i]);
  }
  return '$buf so\'m';
}

/// Bir nechta turi bo'lgan mahsulot uchun narx oralig'i: "5 000 - 12 000 so'm"
String _formatPriceRange(dynamic min, dynamic max) {
  final minStr = min?.toString();
  final maxStr = max?.toString();
  if (minStr == null) return _formatPrice('0');
  if (maxStr == null || minStr == maxStr) return _formatPrice(minStr);
  final minNum = double.tryParse(minStr);
  final maxNum = double.tryParse(maxStr);
  if (minNum == maxNum) return _formatPrice(minStr);
  final formattedMin = _formatPrice(minStr).replaceAll(' so\'m', '');
  return '$formattedMin - ${_formatPrice(maxStr)}';
}

/// Savatga qo'shish snackbar'i — floating, pastki navigatsiya balandligidan
/// yuqorida (mahsulot qatorini yopmasin), navbatga to'planmaydi.
void _showCartSnackBar(BuildContext context, {required String text, required Color color}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(text),
      duration: const Duration(seconds: 2),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: 70 + AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
    ),
  );
}
