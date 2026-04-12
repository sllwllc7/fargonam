import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../cart/cart_screen.dart';
import '../home/home_feed_screen.dart';
import '../products/product_detail_screen.dart';
import '../shops/shop_detail_screen.dart';
import '../shops/shops_list_screen.dart';

// ── Provayderlar ─────────────────────────────────────────────

/// Do'konlar ro'yxati
final shopsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get('/shops');
  return (res.data as List).cast<Map<String, dynamic>>();
});

/// Marketplace filtr holati
class MarketFilter {
  final int? categoryId;
  final String? query;
  const MarketFilter({this.categoryId, this.query});
}

class _FilterNotifier extends Notifier<MarketFilter> {
  @override
  MarketFilter build() => const MarketFilter();
  void update(MarketFilter f) => state = f;
  void setQuery(String? q) =>
      state = MarketFilter(categoryId: state.categoryId, query: q);
  void setCategory(int? id) =>
      state = MarketFilter(categoryId: id, query: state.query);
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
    final p = <String, dynamic>{'limit': _pageSize, 'offset': offset};
    if (f.categoryId != null) p['category_id'] = f.categoryId;
    if (f.query != null && f.query!.isNotEmpty) p['q'] = f.query;
    final res = await dio.get('/products', queryParameters: p);
    final items =
        ((res.data['items'] ?? []) as List).cast<Map<String, dynamic>>();
    final total = res.data['total'] as int? ?? 0;
    return {'items': items, 'total': total};
  }
}

final paginatedProductsProvider =
    NotifierProvider<PaginatedProductsNotifier, PaginatedProducts>(
        PaginatedProductsNotifier.new);

// ── Asosiy ekran ────────────────────────────────────────────

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _searchExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
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

  void _submitSearch(String value) {
    final q = value.trim();
    ref
        .read(marketFilterProvider.notifier)
        .setQuery(q.isEmpty ? null : q);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(marketFilterProvider);
    final catsAsync = ref.watch(categoriesProvider);
    final prods = ref.watch(paginatedProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.cream,
        backgroundColor: AppColors.surfaceHigh,
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.invalidate(categoriesProvider);
          ref.read(paginatedProductsProvider.notifier).refresh();
          ref.invalidate(shopsProvider);
        },
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            // ── APP BAR ──
            SliverAppBar(
              backgroundColor: AppColors.bg,
              surfaceTintColor: Colors.transparent,
              floating: true,
              snap: true,
              toolbarHeight: 64,
              title: _searchExpanded
                  ? _SearchField(
                      controller: _searchCtrl,
                      onSubmitted: _submitSearch,
                      onClose: () {
                        HapticFeedback.lightImpact();
                        setState(() => _searchExpanded = false);
                        _searchCtrl.clear();
                        ref
                            .read(marketFilterProvider.notifier)
                            .setQuery(null);
                      },
                    )
                  : const Text(
                      'Marketplace',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        letterSpacing: -0.5,
                        color: AppColors.cream,
                      ),
                    ),
              leading: _searchExpanded
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.search,
                          color: AppColors.cream),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() => _searchExpanded = true);
                      },
                    ),
              actions: [
                if (!_searchExpanded) const _CartBadgeButton(),
              ],
            ),

            // ── SEARCH BAR ──
            if (!_searchExpanded)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _searchExpanded = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search,
                              color: AppColors.textMuted
                                  .withValues(alpha: 0.6),
                              size: 22),
                          const SizedBox(width: 12),
                          Text(
                            'Mahsulotlarni qidiring...',
                            style: TextStyle(
                                color: AppColors.textMuted
                                    .withValues(alpha: 0.6),
                                fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── PROMO BANNER ──
            if (filter.query == null || filter.query!.isEmpty)
              SliverToBoxAdapter(
                child: _PromoBanner(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(marketFilterProvider.notifier)
                        .setCategory(null);
                    _scrollCtrl.animateTo(
                      _scrollCtrl.position.maxScrollExtent * 0.5,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              ),

            // ── KATEGORIYALAR ──
            SliverToBoxAdapter(
              child: catsAsync.when(
                loading: () => const _CategorySkeleton(),
                error: (_, _) => const SizedBox.shrink(),
                data: (cats) => _CategorySection(
                  categories: cats,
                  selectedId: filter.categoryId,
                  onSelect: (id) {
                    HapticFeedback.selectionClick();
                    ref
                        .read(marketFilterProvider.notifier)
                        .setCategory(id);
                  },
                ),
              ),
            ),

            // ── DO'KONLAR ──
            if (filter.query == null || filter.query!.isEmpty)
              const SliverToBoxAdapter(child: _ShopsSection()),

            // ── MAHSULOTLAR SARLAVHASI ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Text(
                  filter.query != null && filter.query!.isNotEmpty
                      ? '"${filter.query}" natijalari'
                      : 'Tavsiya etilganlar',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.5,
                    color: AppColors.cream,
                  ),
                ),
              ),
            ),

            // ── MAHSULOTLAR GRID ──
            if (prods.error != null && prods.items.isEmpty)
              SliverFillRemaining(
                child: ErrorRetryWidget(
                  error: prods.error!,
                  onRetry: () => ref
                      .read(paginatedProductsProvider.notifier)
                      .refresh(),
                ),
              )
            else if (prods.items.isEmpty && prods.loading)
              const _ProductsGridSkeleton()
            else if (prods.items.isEmpty)
              SliverFillRemaining(
                child: _MarketEmptyState(
                  hasQuery: filter.query != null,
                  onAction: () {
                    HapticFeedback.lightImpact();
                    setState(() => _searchExpanded = true);
                    if (filter.query != null) {
                      ref
                          .read(marketFilterProvider.notifier)
                          .setQuery(null);
                      ref
                          .read(marketFilterProvider.notifier)
                          .setCategory(null);
                      _searchCtrl.clear();
                    }
                  },
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _ProductCard(product: prods.items[i]),
                    childCount: prods.items.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.58,
                  ),
                ),
              ),
              if (prods.loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.cream)),
                  ),
                ),
              if (!prods.hasMore && prods.items.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    child: Center(
                      child: Text(
                        '${prods.total} ta mahsulot',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Cart badge tugma ────────────────────────────────────────

class _CartBadgeButton extends ConsumerWidget {
  const _CartBadgeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final count = cartAsync.maybeWhen(
      data: (items) => items.length,
      orElse: () => 0,
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined,
              color: AppColors.cream),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
        if (count > 0)
          Positioned(
            top: 8,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 5, vertical: 1),
              constraints:
                  const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.bg, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Qidiruv maydoni (app bar ichida) ────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClose;

  const _SearchField({
    required this.controller,
    required this.onSubmitted,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Qidiring...',
        hintStyle:
            TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        suffixIcon: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textMuted),
          onPressed: onClose,
        ),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
    );
  }
}

// ── Promo Banner ────────────────────────────────────────────

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [
                AppColors.midnightIndigo,
                AppColors.surface,
                AppColors.bgDeep,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.midnightIndigo.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cream.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cream.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'MAXSUS TAKLIF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: AppColors.cream.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Birinchi buyurtma\nuchun chegirma!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.cream,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.cream, AppColors.creamDim],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Xarid qilish',
                        style: TextStyle(
                          color: AppColors.midnightIndigo,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
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

// ── Kategoriyalar ───────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelect;

  const _CategorySection({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  static const _icons = [
    Icons.checkroom,
    Icons.fastfood,
    Icons.phone_android,
    Icons.home_work,
    Icons.sports_soccer,
    Icons.auto_awesome,
    Icons.local_florist,
    Icons.build,
    Icons.watch,
    Icons.laptop,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 4),
          child: Text(
            'Kategoriyalar',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.5,
              color: AppColors.cream,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            itemCount: categories.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                final isSelected = selectedId == null;
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: _CategoryChip(
                    icon: Icons.grid_view_rounded,
                    label: 'Barchasi',
                    isSelected: isSelected,
                    onTap: () => onSelect(null),
                  ),
                );
              }
              final cat = categories[i - 1];
              final isSelected = selectedId == cat['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: _CategoryChip(
                  icon: _icons[(i - 1) % _icons.length],
                  label: cat['name'] as String,
                  isSelected: isSelected,
                  onTap: () =>
                      onSelect(isSelected ? null : cat['id'] as int),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: isSelected ? AppColors.cream : AppColors.surfaceHigh,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.cream.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 28,
              color: isSelected
                  ? AppColors.midnightIndigo
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.cream
                    : AppColors.textPrimary.withValues(alpha: 0.5),
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Do'konlar gorizontal ────────────────────────────────────

class _ShopsSection extends ConsumerWidget {
  const _ShopsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(shopsProvider);
    return shopsAsync.when(
      loading: () => const _ShopsSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (shops) {
        if (shops.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  const Text(
                    'Do\'konlar',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: -0.5,
                      color: AppColors.cream,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ShopsListScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Hammasini ko\'rish →',
                      style: TextStyle(
                        color: AppColors.cream.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: shops.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final s = shops[i];
                  return _PressableScale(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ShopDetailScreen(
                                shopId: s['id'] as int)),
                      );
                    },
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: AppColors.surfaceBright
                                .withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.cream,
                                  AppColors.creamDim,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.store,
                                color: AppColors.midnightIndigo,
                                size: 18),
                          ),
                          const Spacer(),
                          Text(
                            s['name'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Mahsulot kartasi ────────────────────────────────────────

class _ProductCard extends ConsumerStatefulWidget {
  const _ProductCard({required this.product});
  final Map<String, dynamic> product;

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard> {
  bool _addingToCart = false;
  bool _addedToCart = false;
  bool _favOptimistic = false;
  bool _favBusy = false;

  Future<void> _addToCart() async {
    if (_addingToCart || _addedToCart) return;
    HapticFeedback.mediumImpact();
    setState(() => _addingToCart = true);
    try {
      await ref.read(dioProvider).post('/cart', data: {
        'product_id': widget.product['id'] as int,
        'quantity': 1,
      });
      ref.invalidate(cartProvider);
      if (!mounted) return;
      setState(() {
        _addingToCart = false;
        _addedToCart = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Savatchaga qo\'shildi'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'Ko\'rish',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ),
      );
      // 2 sekunddan keyin tugmani qaytarish
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _addedToCart = false);
      });
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() => _addingToCart = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data['detail']?.toString() ??
                'Savatchaga qo\'shilmadi'),
            backgroundColor: AppColors.error,
          ),
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
    final p = widget.product;
    final imgUrl = p['image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    final rating = p['rating'];
    final price = p['price']?.toString() ?? '0';
    final productId = p['id'] as int;

    return _PressableScale(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: productId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
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
                    child: fullImg != null
                        ? AppCachedImage(
                            url: fullImg,
                            borderRadius: 0,
                            fit: BoxFit.cover,
                          )
                        : const _ImagePlaceholder(),
                  ),
                  // Top badge — yuqori reyting
                  if (rating != null &&
                      double.tryParse(rating.toString()) != null &&
                      double.parse(rating.toString()) >= 4.5)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star,
                                size: 11,
                                color: AppColors.midnightIndigo),
                            SizedBox(width: 2),
                            Text(
                              'TOP',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.midnightIndigo,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Favorite tugma
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleFavorite,
                      child: AnimatedScale(
                        scale: _favOptimistic ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.bg.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _favOptimistic
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _favOptimistic
                                ? AppColors.error
                                : AppColors.cream,
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
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            p['name'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (rating != null) ...[
                          const SizedBox(width: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: AppColors.cream, size: 13),
                              const SizedBox(width: 2),
                              Text(
                                '$rating',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    if (p['shop_name'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        p['shop_name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.cream.withValues(alpha: 0.4),
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatPrice(price),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cream,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _addToCart,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _addedToCart
                                    ? [
                                        AppColors.success,
                                        AppColors.success,
                                      ]
                                    : const [
                                        AppColors.cream,
                                        AppColors.creamDim,
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _addingToCart
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.midnightIndigo,
                                    ),
                                  )
                                : Icon(
                                    _addedToCart
                                        ? Icons.check
                                        : Icons.add_shopping_cart,
                                    color: _addedToCart
                                        ? Colors.white
                                        : AppColors.midnightIndigo,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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
  const _ImagePlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceHigh,
      child: Icon(Icons.image_outlined,
          size: 40, color: AppColors.textMuted.withValues(alpha: 0.3)),
    );
  }
}

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 6,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ShimmerBox(width: 64, height: 64, borderRadius: 22),
              SizedBox(height: 8),
              ShimmerBox(width: 50, height: 10, borderRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopsSkeleton extends StatelessWidget {
  const _ShopsSkeleton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, _) =>
              const ShimmerBox(width: 140, height: 80, borderRadius: 22),
        ),
      ),
    );
  }
}

class _ProductsGridSkeleton extends StatelessWidget {
  const _ProductsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.58,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, _) => Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Expanded(
                  flex: 5,
                  child: ShimmerBox(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 0),
                ),
                Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 120, height: 14),
                      SizedBox(height: 8),
                      ShimmerBox(width: 80, height: 12),
                      SizedBox(height: 14),
                      ShimmerBox(width: 90, height: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
          childCount: 6,
        ),
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────

class _MarketEmptyState extends StatelessWidget {
  const _MarketEmptyState({required this.hasQuery, required this.onAction});
  final bool hasQuery;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                hasQuery ? Icons.search_off : Icons.inventory_2_outlined,
                size: 48,
                color: AppColors.textMuted.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasQuery ? 'Hech narsa topilmadi' : 'Mahsulotlar mavjud emas',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Boshqa kalit so\'z bilan urinib ko\'ring'
                  : 'Tez orada yangi mahsulotlar qo\'shiladi',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAction,
              icon: Icon(hasQuery ? Icons.refresh : Icons.search),
              label: Text(hasQuery ? 'Filterlarni tozalash' : 'Qidirish'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Narxni chiroyli formatlash: 1250000 -> 1 250 000 UZS
String _formatPrice(String raw) {
  final num = double.tryParse(raw);
  if (num == null) return '$raw UZS';
  final intStr = num.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(' ');
    buf.write(intStr[i]);
  }
  return '$buf UZS';
}
