import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'products_providers.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key, required this.shopId});
  final int shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(shopProductsProvider(shopId));

    return Scaffold(
      appBar: AppBar(title: const Text('Mahsulotlar')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Qo\'shish'),
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => AddProductScreen(shopId: shopId)),
          );
          if (created == true) ref.invalidate(shopProductsProvider(shopId));
        },
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xato: $e')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('Hali mahsulot yo\'q. Pastdagi tugma bilan qo\'shing.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(shopProductsProvider(shopId)),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _ProductTile(product: products[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  const _ProductTile({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imgUrl = product.imageUrl != null ? '${AppConfig.apiBaseUrl}${product.imageUrl}' : null;
    return Card(
      child: ListTile(
        leading: SizedBox(
          width: 56,
          height: 56,
          child: imgUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(imgUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image_outlined, color: Colors.grey),
                ),
        ),
        title: Text(product.name),
        subtitle: Text('${product.price} so\'m  •  stock: ${product.stock}'),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            if (action == 'edit') {
              final edited = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => EditProductScreen(product: product)),
              );
              if (edited == true) ref.invalidate(shopProductsProvider(product.shopId));
            } else if (action == 'delete') {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('O\'chirish'),
                  content: Text('"${product.name}" ni o\'chirishni xohlaysizmi?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Yo\'q')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ha', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(dioProvider).delete('/products/${product.id}');
                ref.invalidate(shopProductsProvider(product.shopId));
              }
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Tahrirlash')),
            PopupMenuItem(value: 'delete', child: Text('O\'chirish', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}
