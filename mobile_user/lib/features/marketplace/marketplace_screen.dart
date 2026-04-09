import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../products/product_detail_screen.dart';
import '../shops/shop_detail_screen.dart';
import '../home/home_feed_screen.dart';

/// Do'konlar ro'yxati
final shopsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get('/shops');
  return (res.data as List).cast<Map<String, dynamic>>();
});

/// Mahsulotlar filtr holati.
class _Filter {
  final int? categoryId;
  final String? query;
  const _Filter({this.categoryId, this.query});
}

class _FilterNotifier extends Notifier<_Filter> {
  @override
  _Filter build() => const _Filter();
  void update(_Filter f) => state = f;
}

final _filterProvider = NotifierProvider<_FilterNotifier, _Filter>(_FilterNotifier.new);

final filteredProductsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final f = ref.watch(_filterProvider);
  final p = <String, dynamic>{'limit': 50};
  if (f.categoryId != null) p['category_id'] = f.categoryId;
  if (f.query != null && f.query!.isNotEmpty) p['q'] = f.query;
  final res = await dio.get('/products', queryParameters: p);
  return ((res.data['items'] ?? []) as List).cast<Map<String, dynamic>>();
});

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoriesProvider);
    final prodsAsync = ref.watch(filteredProductsProvider);
    final filter = ref.watch(_filterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Do\'konlar')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(filteredProductsProvider);
          ref.invalidate(shopsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Do'konlar gorizontal
            SliverToBoxAdapter(child: _ShopsHorizontal()),
            // Qidiruv
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Mahsulot qidirish...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(_filterProvider.notifier).update(_Filter(categoryId: filter.categoryId));
                            })
                        : null,
                  ),
                  onSubmitted: (v) => ref.read(_filterProvider.notifier)
                      .update(_Filter(categoryId: filter.categoryId, query: v.trim().isEmpty ? null : v.trim())),
                ),
              ),
            ),

            // Kategoriya chiplar
            SliverToBoxAdapter(
              child: catsAsync.when(
                loading: () => const SizedBox(height: 50),
                error: (_, __) => const SizedBox.shrink(),
                data: (cats) {
                  return SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        ChoiceChip(
                          label: const Text('Hammasi'),
                          selected: filter.categoryId == null,
                          selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                          onSelected: (_) => ref.read(_filterProvider.notifier).update(_Filter(query: filter.query)),
                        ),
                        const SizedBox(width: 6),
                        for (final c in cats) ...[
                          ChoiceChip(
                            label: Text(c['name'] as String),
                            selected: filter.categoryId == c['id'],
                            selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                            onSelected: (_) => ref.read(_filterProvider.notifier)
                                .update(_Filter(categoryId: c['id'] as int, query: filter.query)),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Mahsulotlar grid
            prodsAsync.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(child: Center(child: Text('Xato: $e'))),
              data: (products) {
                if (products.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('Mahsulot topilmadi', style: TextStyle(color: Colors.grey))),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _GridProductCard(product: products[i]),
                      childCount: products.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.68,
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

class _GridProductCard extends StatelessWidget {
  const _GridProductCard({required this.product});
  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    final imgUrl = product['image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product['id'] as int)),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  fullImg != null
                      ? Image.network(fullImg, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade100, child: const Icon(Icons.broken_image)))
                      : Container(color: Colors.grey.shade100, child: const Icon(Icons.image_outlined, size: 36, color: Colors.grey)),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${product['stock']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'] as String, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    if (product['shop_name'] != null) ...[
                      const SizedBox(height: 2),
                      Text(product['shop_name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                    const Spacer(),
                    Text('${product['price']} so\'m',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primary)),
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

class _ShopsHorizontal extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(shopsProvider);
    return shopsAsync.when(
      loading: () => const SizedBox(height: 80),
      error: (_, __) => const SizedBox.shrink(),
      data: (shops) {
        if (shops.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text('Do\'konlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: shops.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final s = shops[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ShopDetailScreen(shopId: s['id'] as int))),
                    child: Container(
                      width: 130,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.store, color: AppTheme.primary, size: 18),
                          ),
                          const Spacer(),
                          Text(s['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
