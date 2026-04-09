import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../products/product_detail_screen.dart';

final favoritesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get('/favorites');
  return (res.data as List).cast<Map<String, dynamic>>();
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favsAsync = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sevimlilar')),
      body: favsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (favs) {
          if (favs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('Sevimlilar bo\'sh', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(favoritesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final f = favs[i];
                final imgUrl = f['product_image_url'] as String?;
                final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(productId: f['product_id'] as int))),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 64, height: 64,
                              child: fullImg != null
                                  ? Image.network(fullImg, fit: BoxFit.cover)
                                  : Container(color: Colors.grey.shade100, child: const Icon(Icons.image_outlined)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(f['product_name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('${f['product_price']} so\'m',
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite, color: AppTheme.accent),
                            onPressed: () async {
                              await ref.read(dioProvider).delete('/favorites/${f['product_id']}');
                              ref.invalidate(favoritesProvider);
                            },
                          ),
                        ],
                      ),
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
