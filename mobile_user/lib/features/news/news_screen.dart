import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';


final newsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get('/news', queryParameters: {'limit': 30});
  return ((res.data['items'] ?? []) as List).cast<Map<String, dynamic>>();
});

class NewsListScreen extends ConsumerWidget {
  const NewsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Yangiliklar')),
      body: newsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (news) {
          if (news.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.newspaper, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('Hozircha yangilik yo\'q', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(newsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: news.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _NewsCard(post: news[i]),
            ),
          );
        },
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.post});
  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) {
    final imgUrl = post['image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    final body = post['body'] as String;
    final dateStr = post['created_at'] as String;
    final dt = DateTime.tryParse(dateStr);
    final dateFormatted = dt != null ? '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}' : '';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _NewsDetail(post: post))),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (fullImg != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(fullImg, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200)),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post['title'] as String,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(body, maxLines: 3, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4)),
                  const SizedBox(height: 8),
                  Text(dateFormatted, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsDetail extends StatelessWidget {
  const _NewsDetail({required this.post});
  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) {
    final imgUrl = post['image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (fullImg != null)
              AspectRatio(aspectRatio: 16 / 9, child: Image.network(fullImg, fit: BoxFit.cover)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post['title'] as String,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Text(post['body'] as String,
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
