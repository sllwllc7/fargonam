import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../products/product_detail_screen.dart';

final favoritesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get('/favorites');
  return (res.data as List).cast<Map<String, dynamic>>();
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favsAsync = ref.watch(favoritesProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Sevimlilar'),
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: favsAsync.when(
        loading: () => const _FavoritesSkeleton(),
        error: (e, _) => ErrorRetryWidget(
            error: e, onRetry: () => ref.invalidate(favoritesProvider)),
        data: (favs) {
          if (favs.isEmpty) return const _EmptyFavoritesState();
          return RefreshIndicator(
            color: AppColors.cream,
            backgroundColor: AppColors.surfaceHigh,
            onRefresh: () async {
              HapticFeedback.lightImpact();
              ref.invalidate(favoritesProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  _FavoriteCard(item: favs[i]),
            ),
          );
        },
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
  bool _pressed = false;
  bool _removing = false;

  Future<void> _remove() async {
    if (_removing) return;
    HapticFeedback.lightImpact();
    setState(() => _removing = true);
    try {
      final productId = widget.item['product_id'] as int;
      await ref.read(dioProvider).delete('/favorites/$productId');
      ref.invalidate(favoritesProvider);
    } catch (e) {
      debugPrint('Sevimlilardan o\'chirishda xato: $e');
      if (mounted) {
        setState(() => _removing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('O\'chirishda xato yuz berdi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final productId = item['product_id'] as int;
    final imgUrl = item['product_image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    final priceStr = item['product_price']?.toString() ?? '0';
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
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Hero(
                  tag: 'product_image_$productId',
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: fullImg != null
                        ? AppCachedImage(
                            url: fullImg,
                            width: 76,
                            height: 76,
                            borderRadius: 0,
                          )
                        : Container(
                            color: AppColors.surfaceHigh,
                            child: const Icon(Icons.image_outlined,
                                color: AppColors.textSecondary)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['product_name'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatPrice(price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.cream,
                        fontSize: 16,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _remove,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _removing
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.error),
                        )
                      : const Icon(Icons.favorite,
                          color: AppColors.error, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFavoritesState extends StatelessWidget {
  const _EmptyFavoritesState();
  @override
  Widget build(BuildContext context) {
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
                Icons.favorite_border,
                size: 56,
                color: AppColors.error.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sevimlilar bo\'sh',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Yoqqan mahsulotlarni ❤ tugmasi\nbilan saqlab boring',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesSkeleton extends StatelessWidget {
  const _FavoritesSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: const [
            ShimmerBox(width: 76, height: 76, borderRadius: 14),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 160, height: 14),
                  SizedBox(height: 8),
                  ShimmerBox(width: 80, height: 16),
                ],
              ),
            ),
          ],
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
