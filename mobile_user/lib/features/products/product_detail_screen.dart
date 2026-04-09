import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../favorites/favorites_screen.dart';

final productDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final res = await ref.watch(dioProvider).get('/products/$id');
  return res.data as Map<String, dynamic>;
});

final isFavoriteProvider = FutureProvider.family<bool, int>((ref, productId) async {
  try {
    final res = await ref.watch(dioProvider).get('/favorites/check/$productId');
    return res.data['is_favorite'] as bool;
  } catch (_) {
    return false;
  }
});

final productReviewsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, productId) async {
  final res = await ref.watch(dioProvider).get('/reviews/product/$productId');
  return res.data as Map<String, dynamic>;
});

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pAsync = ref.watch(productDetailProvider(productId));
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [_FavoriteButton(productId: productId)],
      ),
      body: pAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xato: $e')),
        data: (p) => _ProductBody(product: p),
      ),
    );
  }
}

class _ProductBody extends StatelessWidget {
  const _ProductBody({required this.product});
  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    final imgUrl = product['image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    final stock = product['stock'] as int;
    final inStock = stock > 0;

    return Column(
      children: [
        // Rasm
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              fullImg != null
                  ? Image.network(fullImg, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_outlined, size: 80, color: Colors.grey)),
              // Gradient overlay (pastdan)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tafsilotlar
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          transform: Matrix4.translationValues(0, -24, 0),
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nomi va narx
              Text(product['name'] as String,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              if (product['shop_name'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.store, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(product['shop_name'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('${product['price']} so\'m',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: inStock ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      inStock ? 'Bor: $stock dona' : 'Tugagan',
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: inStock ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),

              // Tavsif
              if (product['description'] != null && (product['description'] as String).isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                const Text('Tavsif', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(product['description'] as String,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5)),
              ],
              const SizedBox(height: 16),

              // Reyting
              _ReviewsSection(productId: product['id'] as int),
              const SizedBox(height: 20),

              // Savatchaga qo'shish tugmasi
              SizedBox(
                width: double.infinity,
                child: _AddToCartButton(productId: product['id'] as int, inStock: inStock),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddToCartButton extends ConsumerStatefulWidget {
  const _AddToCartButton({required this.productId, required this.inStock});
  final int productId;
  final bool inStock;
  @override
  ConsumerState<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends ConsumerState<_AddToCartButton> {
  bool _loading = false;
  bool _added = false;

  Future<void> _add() async {
    setState(() => _loading = true);
    try {
      await ref.read(dioProvider).post('/cart', data: {'product_id': widget.productId, 'quantity': 1});
      setState(() => _added = true);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data['detail']?.toString() ?? 'Xato'), backgroundColor: AppTheme.accent),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.inStock) {
      return FilledButton(
        onPressed: null,
        style: FilledButton.styleFrom(backgroundColor: Colors.grey.shade300),
        child: const Text('Mahsulot tugagan'),
      );
    }
    if (_added) {
      return FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle),
        label: const Text('Savatchada'),
        style: FilledButton.styleFrom(backgroundColor: AppTheme.secondary),
      );
    }
    return FilledButton.icon(
      onPressed: _loading ? null : _add,
      icon: _loading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.add_shopping_cart),
      label: const Text('Savatchaga qo\'shish'),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.productId});
  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavAsync = ref.watch(isFavoriteProvider(productId));
    return isFavAsync.when(
      loading: () => const SizedBox(width: 48),
      error: (_, __) => const SizedBox(width: 48),
      data: (isFav) => IconButton(
        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? AppTheme.accent : Colors.white, size: 28),
        onPressed: () async {
          final dio = ref.read(dioProvider);
          if (isFav) {
            await dio.delete('/favorites/$productId');
          } else {
            await dio.post('/favorites/$productId');
          }
          ref.invalidate(isFavoriteProvider(productId));
          ref.invalidate(favoritesProvider);
        },
      ),
    );
  }
}

class _ReviewsSection extends ConsumerStatefulWidget {
  const _ReviewsSection({required this.productId});
  final int productId;
  @override
  ConsumerState<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<_ReviewsSection> {
  int _myRating = 0;
  final _commentCtrl = TextEditingController();
  bool _showForm = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_myRating == 0) return;
    await ref.read(dioProvider).post('/reviews/product/${widget.productId}', data: {
      'rating': _myRating,
      if (_commentCtrl.text.trim().isNotEmpty) 'comment': _commentCtrl.text.trim(),
    });
    _commentCtrl.clear();
    setState(() { _showForm = false; _myRating = 0; });
    ref.invalidate(productReviewsProvider(widget.productId));
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(productReviewsProvider(widget.productId));
    return reviewsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final avg = data['avg_rating'];
        final total = data['total'] as int;
        final items = (data['items'] as List).cast<Map<String, dynamic>>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            // Sarlavha + o'rtacha
            Row(
              children: [
                const Text('Sharhlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                if (avg != null) ...[
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  Text(' ${avg}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(' ($total)', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _showForm = !_showForm),
                  child: Text(_showForm ? 'Yopish' : 'Sharh qo\'shish'),
                ),
              ],
            ),
            // Sharh formi
            if (_showForm) ...[
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setState(() => _myRating = i + 1),
                  child: Icon(
                    i < _myRating ? Icons.star : Icons.star_border,
                    color: Colors.amber, size: 32,
                  ),
                )),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentCtrl,
                decoration: const InputDecoration(hintText: 'Fikringiz (ixtiyoriy)...', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              FilledButton(onPressed: _myRating > 0 ? _submitReview : null, child: const Text('Yuborish')),
            ],
            // Mavjud sharhlar (3 tagacha)
            for (final r in items.take(3)) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  ...List.generate(5, (i) => Icon(
                    i < (r['rating'] as int) ? Icons.star : Icons.star_border,
                    color: Colors.amber, size: 16,
                  )),
                  const SizedBox(width: 8),
                  Text(r['user_name'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
              if (r['comment'] != null && (r['comment'] as String).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(r['comment'] as String, style: const TextStyle(fontSize: 13)),
                ),
            ],
          ],
        );
      },
    );
  }
}
