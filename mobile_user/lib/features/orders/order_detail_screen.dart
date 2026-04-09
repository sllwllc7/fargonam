import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/theme.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List?) ?? [];
    final status = order['status'] as String;
    final dt = DateTime.tryParse(order['created_at'] as String);
    final date = dt != null ? '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}' : '';

    final (statusLabel, statusColor) = switch (status) {
      'pending' => ('Kutilmoqda', Colors.orange),
      'paid' => ('To\'langan', Colors.blue),
      'shipped' => ('Yo\'lda', Colors.indigo),
      'delivered' => ('Yetkazildi', Colors.green),
      'cancelled' => ('Bekor', Colors.red),
      _ => (status, Colors.grey),
    };

    return Scaffold(
      appBar: AppBar(title: Text('Buyurtma #${order['id']}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Holat va sana
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(statusLabel, style: TextStyle(fontWeight: FontWeight.w700, color: statusColor)),
                  ),
                  const Spacer(),
                  Text(date, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Mahsulotlar
          const Text('Mahsulotlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final item in items) _OrderItemTile(item: item as Map<String, dynamic>),
          const SizedBox(height: 16),

          // Jami
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Jami:', style: TextStyle(fontSize: 16)),
                  const Spacer(),
                  Text('${order['total']} so\'m',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final name = item['product_name'] as String? ?? 'Mahsulot #${item['product_id']}';
    final imgUrl = item['product_image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    final qty = item['quantity'] as int;
    final price = item['price_at_purchase'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56, height: 56,
                child: fullImg != null
                    ? Image.network(fullImg, fit: BoxFit.cover)
                    : Container(color: Colors.grey.shade100, child: const Icon(Icons.image_outlined)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('$price so\'m × $qty', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
