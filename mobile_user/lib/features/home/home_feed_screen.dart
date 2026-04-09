import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../news/news_screen.dart';
import '../products/product_detail_screen.dart';
import '../shell/app_shell.dart';

/// Bannerlar
final bannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/feed/banners');
  return (res.data as List).cast<Map<String, dynamic>>();
});

/// Kategoriyalar
final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/categories');
  return (res.data as List).cast<Map<String, dynamic>>();
});

/// Mashhur mahsulotlar (eng yangi 10 ta)
final topProductsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/products', queryParameters: {'limit': 10});
  return ((res.data['items'] ?? []) as List).cast<Map<String, dynamic>>();
});

class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Fargonam'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bannersProvider);
          ref.invalidate(categoriesProvider);
          ref.invalidate(topProductsProvider);
          ref.invalidate(newsProvider);
        },
        child: ListView(
          children: [
            // === QIDIRUV ===
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GestureDetector(
                onTap: () => appShellKey.currentState?.switchTab(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey.shade400),
                      const SizedBox(width: 10),
                      Text('Mahsulot qidirish...', style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // === BANNERLAR ===
            _BannerCarousel(),
            const SizedBox(height: 20),
            // === KATEGORIYALAR ===
            _SectionHeader(title: 'Kategoriyalar', onSeeAll: () {}),
            _CategoryChips(),
            const SizedBox(height: 20),
            // === MASHHUR MAHSULOTLAR ===
            _SectionHeader(title: 'Yangi mahsulotlar', onSeeAll: () {}),
            _ProductHorizontalList(),
            const SizedBox(height: 20),
            // === YANGILIKLAR ===
            _SectionHeader(
              title: 'Yangiliklar',
              onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsListScreen())),
            ),
            _NewsPreviewList(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});
  final String title;
  final VoidCallback onSeeAll;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          TextButton(onPressed: onSeeAll, child: const Text('Barchasi →')),
        ],
      ),
    );
  }
}

class _BannerCarousel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(bannersProvider);
    return bannersAsync.when(
      loading: () => Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) {
          // Placeholder banner
          return Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign, size: 40, color: Colors.white),
                  SizedBox(height: 8),
                  Text('Fargonam\'ga xush kelibsiz!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Eng yaxshi narxlar shu yerda', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
          );
        }
        return SizedBox(
          height: 180,
          child: PageView.builder(
            itemCount: banners.length,
            padEnds: false,
            controller: PageController(viewportFraction: 0.92),
            itemBuilder: (context, i) {
              final b = banners[i];
              final url = '${AppConfig.apiBaseUrl}${b['media_url']}';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(url, fit: BoxFit.cover, width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.primary,
                            child: Center(child: Text(b['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 18))),
                          )),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoriesProvider);
    return catsAsync.when(
      loading: () => const SizedBox(height: 40),
      error: (_, __) => const SizedBox.shrink(),
      data: (cats) {
        if (cats.isEmpty) return const SizedBox.shrink();
        final icons = [Icons.checkroom, Icons.fastfood, Icons.phone_android, Icons.home_work, Icons.sports_soccer, Icons.auto_awesome, Icons.local_florist, Icons.build];
        return SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final c = cats[i];
              return GestureDetector(
                onTap: () {
                  // Marketplace sahifasiga o'tish (kategoriya filtri bilan)
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icons[i % icons.length], color: AppTheme.primary),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 70,
                      child: Text(
                        c['name'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductHorizontalList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prodsAsync = ref.watch(topProductsProvider);
    return prodsAsync.when(
      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('$e')),
      data: (products) {
        if (products.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('Hali mahsulot yo\'q'));
        return SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _ProductMiniCard(product: products[i]),
          ),
        );
      },
    );
  }
}

class _ProductMiniCard extends StatelessWidget {
  const _ProductMiniCard({required this.product});
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
      child: SizedBox(
        width: 150,
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
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('${product['price']} so\'m',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsPreviewList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);
    return newsAsync.when(
      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
      data: (news) {
        if (news.isEmpty) return const SizedBox.shrink();
        final show = news.take(3).toList();
        return Column(
          children: [
            for (final n in show)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsListScreen())),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          if (n['image_url'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 60, height: 60,
                                child: Image.network('${AppConfig.apiBaseUrl}${n['image_url']}', fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200)),
                              ),
                            )
                          else
                            Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.article, color: AppTheme.primary),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n['title'] as String, maxLines: 2, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(n['body'] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
