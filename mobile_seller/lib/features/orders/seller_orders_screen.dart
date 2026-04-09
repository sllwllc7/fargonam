import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';

final sellerOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/seller/orders');
  return (res.data as List).cast<Map<String, dynamic>>();
});

class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(sellerOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kelgan buyurtmalar')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xato: $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('Hali buyurtma kelmagan'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sellerOrdersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final o = orders[i];
                final items = (o['items'] as List?) ?? [];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Buyurtma #${o['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Spacer(),
                            _StatusChip(status: o['status'] as String),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Jami: ${o['total']} so\'m', style: const TextStyle(fontSize: 15)),
                        Text('Xaridor ID: ${o['user_id']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('${items.length} ta mahsulot', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        for (final item in items)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '  • Mahsulot #${item['product_id']} × ${item['quantity']}  (${item['price_at_purchase']} so\'m)',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'pending' => Colors.orange,
      'paid' => Colors.blue,
      'shipped' => Colors.indigo,
      'delivered' => Colors.green,
      'cancelled' => Colors.red,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
