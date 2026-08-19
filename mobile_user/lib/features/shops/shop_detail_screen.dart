import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets.dart';
import '../products/product_detail_screen.dart';

final shopDetailProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final res = await ref.watch(dioProvider).get('/shops/$id');
  return res.data as Map<String, dynamic>;
});

final shopProductsProvider = FutureProvider.family<
    List<Map<String, dynamic>>, int>((ref, shopId) async {
  final res = await ref.watch(dioProvider).get('/products',
      queryParameters: {'shop_id': shopId, 'limit': 50});
  return ((res.data['items'] ?? []) as List)
      .cast<Map<String, dynamic>>();
});

class ShopDetailScreen extends ConsumerWidget {
  const ShopDetailScreen({super.key, required this.shopId});
  final int shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopDetailProvider(shopId));
    final prodsAsync = ref.watch(shopProductsProvider(shopId));

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: shopAsync.when(
          data: (s) => Text(s['name'] as String),
          loading: () => const Text('Do\'kon'),
          error: (_, _) => const Text('Do\'kon'),
        ),
        backgroundColor: AppColorsDark.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        color: AppColorsDark.primary,
        backgroundColor: AppColorsDark.surfaceAlt,
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.invalidate(shopDetailProvider(shopId));
          ref.invalidate(shopProductsProvider(shopId));
        },
        child: CustomScrollView(
          slivers: [
            // ── Do'kon header ──
            SliverToBoxAdapter(
              child: shopAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child:
                      ShimmerBox(width: double.infinity, height: 100),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('$e',
                      style:
                          const TextStyle(color: AppColorsDark.error)),
                ),
                data: (shop) => _ShopHeader(shop: shop),
              ),
            ),

            // ── Sarlavha ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    const Text(
                      'Mahsulotlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColorsDark.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    prodsAsync.when(
                      data: (p) => Text(
                        '${p.length} ta',
                        style: TextStyle(
                            color: AppColorsDark.textSecondary.withValues(alpha: 0.7),
                            fontSize: 13),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            prodsAsync.when(
              loading: () => const _ShopProductsSkeleton(),
              error: (e, _) => SliverFillRemaining(
                child: ErrorRetryWidget(
                  error: e,
                  onRetry: () => ref
                      .invalidate(shopProductsProvider(shopId)),
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Hali mahsulot yo\'q',
                          style: TextStyle(
                              color: AppColorsDark.textSecondary.withValues(alpha: 0.7),
                              fontSize: 14),
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) =>
                          _ShopProductCard(product: products[i]),
                      childCount: products.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.62,
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

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({required this.shop});
  final Map<String, dynamic> shop;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorsDark.primary.withValues(alpha: 0.1),
            AppColorsDark.success.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppColorsDark.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColorsDark.primary,
                  AppColorsDark.primary.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColorsDark.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.store,
                color: AppColorsDark.background, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop['name'] as String,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColorsDark.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (shop['description'] != null &&
                    (shop['description'] as String).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    shop['description'] as String,
                    style: const TextStyle(
                        color: AppColorsDark.textSecondary,
                        fontSize: 13,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopProductsSkeleton extends StatelessWidget {
  const _ShopProductsSkeleton();
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, _) => Container(
            decoration: BoxDecoration(
              color: AppColorsDark.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Expanded(
                  flex: 3,
                  child: ShimmerBox(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 0),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 100, height: 12),
                      SizedBox(height: 8),
                      ShimmerBox(width: 70, height: 14),
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

class _ShopProductCard extends StatefulWidget {
  const _ShopProductCard({required this.product});
  final Map<String, dynamic> product;

  @override
  State<_ShopProductCard> createState() => _ShopProductCardState();
}

class _ShopProductCardState extends State<_ShopProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final imgUrl = p['image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    final productId = p['id'] as int;
    final priceStr = p['price']?.toString() ?? '0';
    final price = double.tryParse(priceStr) ?? 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProductDetailScreen(productId: productId)),
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: AppColorsDark.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColorsDark.border, width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Hero(
                  tag: 'product_image_$productId',
                  child: fullImg != null
                      ? AppCachedImage(
                          url: fullImg,
                          borderRadius: 0,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColorsDark.surfaceAlt,
                          child: const Icon(Icons.image_outlined,
                              size: 36,
                              color: AppColorsDark.textSecondary)),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColorsDark.textPrimary,
                            height: 1.3),
                      ),
                      const Spacer(),
                      Text(
                        _formatPrice(price),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColorsDark.primary,
                          letterSpacing: -0.3,
                        ),
                      ),
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

String _formatPrice(num value) {
  final intStr = value.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(' ');
    buf.write(intStr[i]);
  }
  return '$buf UZS';
}
