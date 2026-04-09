import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../products/product_detail_screen.dart';

final shopDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final res = await ref.watch(dioProvider).get('/shops/$id');
  return res.data as Map<String, dynamic>;
});

final shopProductsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, shopId) async {
  final res = await ref.watch(dioProvider).get('/products', queryParameters: {'shop_id': shopId, 'limit': 50});
  return ((res.data['items'] ?? []) as List).cast<Map<String, dynamic>>();
});

class ShopDetailScreen extends ConsumerWidget {
  const ShopDetailScreen({super.key, required this.shopId});
  final int shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopDetailProvider(shopId));
    final prodsAsync = ref.watch(shopProductsProvider(shopId));

    return Scaffold(
      appBar: AppBar(
        title: shopAsync.when(
          data: (s) => Text(s['name'] as String),
          loading: () => const Text('Do\'kon'),
          error: (_, __) => const Text('Do\'kon'),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Do'kon ma'lumoti
          SliverToBoxAdapter(
            child: shopAsync.when(
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('$e')),
              data: (shop) => Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary.withValues(alpha: 0.08), AppTheme.secondary.withValues(alpha: 0.08)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.store, color: AppTheme.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shop['name'] as String,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          if (shop['description'] != null && (shop['description'] as String).isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(shop['description'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Mahsulotlar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: prodsAsync.when(
                data: (p) => Text('${p.length} ta mahsulot', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          prodsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('$e'))),
            data: (products) {
              if (products.isEmpty) {
                return const SliverFillRemaining(child: Center(child: Text('Hali mahsulot yo\'q')));
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _ShopProductCard(product: products[i]),
                    childCount: products.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.68,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ShopProductCard extends StatelessWidget {
  const _ShopProductCard({required this.product});
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
              child: fullImg != null
                  ? Image.network(fullImg, fit: BoxFit.cover)
                  : Container(color: Colors.grey.shade100, child: const Icon(Icons.image_outlined, size: 36, color: Colors.grey)),
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
