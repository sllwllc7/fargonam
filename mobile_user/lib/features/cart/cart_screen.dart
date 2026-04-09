import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart';

final cartProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get('/cart');
  return (res.data as List).cast<Map<String, dynamic>>();
});

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Savatcha')),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xato: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Savatcha bo\'sh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Mahsulot qo\'shish uchun do\'konlarga o\'ting', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          // Jami narxni hisoblash
          double total = 0;
          for (final ci in items) {
            final priceStr = ci['product_price'] as String?;
            if (priceStr != null) {
              total += double.parse(priceStr) * (ci['quantity'] as int);
            }
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.invalidate(cartProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _CartItemCard(item: items[i], ref: ref),
                  ),
                ),
              ),

              // Pastki panel — jami narx + checkout
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -4))],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Jami:', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          Text('${total.toStringAsFixed(0)} so\'m',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(child: _CheckoutButton(itemCount: items.length, ref: ref)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item, required this.ref});
  final Map<String, dynamic> item;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final name = item['product_name'] as String? ?? 'Mahsulot #${item['product_id']}';
    final price = item['product_price'] as String?;
    final qty = item['quantity'] as int;
    final imgUrl = item['product_image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rasm
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 70, height: 70,
                child: fullImg != null
                    ? Image.network(fullImg, fit: BoxFit.cover)
                    : Container(color: Colors.grey.shade100, child: const Icon(Icons.image_outlined, color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 14),

            // Nomi va narx
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  if (price != null)
                    Text('$price so\'m', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Soni +/- va o'chirish
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QtyButton(
                      icon: Icons.remove,
                      onTap: () async {
                        if (qty <= 1) {
                          await ref.read(dioProvider).delete('/cart/${item['id']}');
                        } else {
                          await ref.read(dioProvider).patch('/cart/${item['id']}',
                              queryParameters: {'quantity': qty - 1});
                        }
                        ref.invalidate(cartProvider);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                    _QtyButton(
                      icon: Icons.add,
                      onTap: () async {
                        await ref.read(dioProvider).patch('/cart/${item['id']}',
                            queryParameters: {'quantity': qty + 1});
                        ref.invalidate(cartProvider);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutButton extends StatefulWidget {
  const _CheckoutButton({required this.itemCount, required this.ref});
  final int itemCount;
  final WidgetRef ref;
  @override
  State<_CheckoutButton> createState() => _CheckoutButtonState();
}

class _CheckoutButtonState extends State<_CheckoutButton> {
  bool _loading = false;

  Future<void> _checkout() async {
    setState(() => _loading = true);
    try {
      final res = await widget.ref.read(dioProvider).post('/orders');
      widget.ref.invalidate(cartProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Buyurtma berildi! Jami: ${res.data['total']} so\'m'),
            backgroundColor: AppTheme.secondary,
          ),
        );
      }
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
    return FilledButton(
      onPressed: _loading ? null : _checkout,
      child: _loading
          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
          : Text('Buyurtma berish (${widget.itemCount})'),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppTheme.primary),
      ),
    );
  }
}
