import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../products/product_detail_screen.dart';
import '../shops/shop_detail_screen.dart';

/// Qidiruv so'rovi
class _SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String q) => state = q;
}

final searchQueryProvider =
    NotifierProvider<_SearchQueryNotifier, String>(_SearchQueryNotifier.new);

final searchProductsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final q = ref.watch(searchQueryProvider);
  if (q.trim().length < 2) return [];
  final res = await ref
      .watch(dioProvider)
      .get('/products', queryParameters: {'q': q, 'limit': 20});
  return ((res.data['items'] ?? []) as List)
      .cast<Map<String, dynamic>>();
});

final searchShopsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final q = ref.watch(searchQueryProvider);
  if (q.trim().length < 2) return [];
  final res =
      await ref.watch(dioProvider).get('/shops', queryParameters: {'q': q});
  return (res.data as List).cast<Map<String, dynamic>>();
});

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

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final productsAsync = ref.watch(searchProductsProvider);
    final shopsAsync = ref.watch(searchShopsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.search,
                  color: AppColors.textMuted, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  onChanged: _onChanged,
                  onSubmitted: _search,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Mahsulot yoki do\'kon...',
                    hintStyle: TextStyle(
                        color: AppColors.textMuted, fontSize: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: false,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14),
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
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBright,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 14, color: AppColors.textMuted),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: query.trim().length < 2
          ? _RecentSearches(
              searches: _recentSearches,
              onTap: _search,
              onClear: _clearRecent,
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Do'konlar
                shopsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (shops) {
                    if (shops.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                          child: Text(
                            'DO\'KONLAR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        for (final shop in shops.take(5))
                          _ShopSearchTile(shop: shop),
                        const SizedBox(height: 12),
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(height: 1),
                        ),
                      ],
                    );
                  },
                ),

                // Mahsulotlar
                productsAsync.when(
                  loading: () => const _SearchResultsSkeleton(),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Xato: $e',
                        style:
                            const TextStyle(color: AppColors.error)),
                  ),
                  data: (products) {
                    if (products.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHigh,
                                  borderRadius:
                                      BorderRadius.circular(28),
                                ),
                                child: Icon(Icons.search_off,
                                    size: 44,
                                    color: AppColors.textMuted
                                        .withValues(alpha: 0.6)),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '"$query" topilmadi',
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Boshqa kalit so\'z bilan urinib ko\'ring',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              20, 12, 20, 8),
                          child: Text(
                            'MAHSULOTLAR (${products.length})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        for (final p in products)
                          _ProductSearchTile(product: p),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.searches,
    required this.onTap,
    required this.onClear,
  });
  final List<String> searches;
  final void Function(String) onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (searches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Icon(
                  Icons.search,
                  size: 56,
                  color: AppColors.cream.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nimani qidiryapsiz?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Mahsulot, do\'kon yoki kategoriya nomini\nkiriting',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Text(
              'Oxirgi qidiruvlar',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onClear,
              child: const Text(
                'Tozalash',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: searches
              .map((s) => GestureDetector(
                    onTap: () => onTap(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.divider, width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history,
                              size: 16,
                              color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            s,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
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

class _ShopSearchTile extends StatelessWidget {
  const _ShopSearchTile({required this.shop});
  final Map<String, dynamic> shop;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.cream, AppColors.creamDim],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.store,
            color: AppColors.midnightIndigo, size: 22),
      ),
      title: Text(
        shop['name'] as String,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: shop['description'] != null
          ? Text(
              shop['description'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted),
            )
          : null,
      trailing: const Icon(Icons.chevron_right,
          size: 20, color: AppColors.textMuted),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    ShopDetailScreen(shopId: shop['id'] as int)));
      },
    );
  }
}

class _ProductSearchTile extends StatelessWidget {
  const _ProductSearchTile({required this.product});
  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    final imgUrl = product['image_url'] as String?;
    final fullImg =
        imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    final productId = product['id'] as int;
    final priceStr = product['price']?.toString() ?? '0';
    final price = double.tryParse(priceStr) ?? 0;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Hero(
          tag: 'product_image_$productId',
          child: SizedBox(
            width: 56,
            height: 56,
            child: fullImg != null
                ? AppCachedImage(
                    url: fullImg,
                    width: 56,
                    height: 56,
                    borderRadius: 0,
                  )
                : Container(
                    color: AppColors.surfaceHigh,
                    child: const Icon(Icons.image_outlined,
                        size: 22, color: AppColors.textSecondary)),
          ),
        ),
      ),
      title: Text(
        product['name'] as String,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.textPrimary),
      ),
      subtitle: Text(
        _formatPrice(price),
        style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.cream,
            fontSize: 13),
      ),
      trailing: product['shop_name'] != null
          ? Text(
              product['shop_name'] as String,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted),
            )
          : null,
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    ProductDetailScreen(productId: productId)));
      },
    );
  }
}

class _SearchResultsSkeleton extends StatelessWidget {
  const _SearchResultsSkeleton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(
          5,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: const [
                ShimmerBox(width: 56, height: 56, borderRadius: 12),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 160, height: 12),
                      SizedBox(height: 6),
                      ShimmerBox(width: 80, height: 12),
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
  return '$buf UZS';
}
