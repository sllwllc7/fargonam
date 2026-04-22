import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

final newsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.keepAlive();
  final res = await ref
      .watch(dioProvider)
      .get('/news', queryParameters: {'limit': 30});
  return ((res.data['items'] ?? []) as List)
      .cast<Map<String, dynamic>>();
});

class NewsListScreen extends ConsumerWidget {
  const NewsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Yangiliklar'),
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: newsAsync.when(
        loading: () => const _NewsListSkeleton(),
        error: (e, _) => ErrorRetryWidget(
            error: e, onRetry: () => ref.invalidate(newsProvider)),
        data: (news) {
          if (news.isEmpty) return const _EmptyNewsState();
          return RefreshIndicator(
            color: AppColors.cream,
            backgroundColor: AppColors.surfaceHigh,
            onRefresh: () async {
              HapticFeedback.lightImpact();
              ref.invalidate(newsProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: news.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _NewsListCard(post: news[i]),
            ),
          );
        },
      ),
    );
  }
}

class _NewsListCard extends StatefulWidget {
  const _NewsListCard({required this.post});
  final Map<String, dynamic> post;

  @override
  State<_NewsListCard> createState() => _NewsListCardState();
}

class _NewsListCardState extends State<_NewsListCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final imgUrl = post['image_url'] as String?;
    final fullImg =
        imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    final body = post['body'] as String;
    final dateStr = post['created_at'] as String;
    final dt = DateTime.tryParse(dateStr);
    final dateFormatted = dt != null
        ? '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}'
        : '';

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => _NewsDetail(post: post)));
      },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (fullImg != null)
                Hero(
                  tag: 'news_image_${post['id']}',
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: AppCachedImage(
                      url: fullImg,
                      borderRadius: 0,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'YANGILIK',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.midnightIndigo,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          dateFormatted,
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      post['title'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
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

class _NewsDetail extends StatelessWidget {
  const _NewsDetail({required this.post});
  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) {
    final imgUrl = post['image_url'] as String?;
    final fullImg =
        imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.bg,
            surfaceTintColor: Colors.transparent,
            expandedHeight: fullImg != null ? 280 : 80,
            pinned: true,
            flexibleSpace: fullImg != null
                ? FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'news_image_${post['id']}',
                          child: AppCachedImage(
                            url: fullImg,
                            borderRadius: 0,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppColors.bg,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'YANGILIK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.midnightIndigo,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    post['title'] as String,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    post['body'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsListSkeleton extends StatelessWidget {
  const _NewsListSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            ShimmerBox(
                width: double.infinity,
                height: 180,
                borderRadius: 0),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 80, height: 16, borderRadius: 6),
                  SizedBox(height: 10),
                  ShimmerBox(width: double.infinity, height: 16),
                  SizedBox(height: 6),
                  ShimmerBox(width: 220, height: 16),
                  SizedBox(height: 8),
                  ShimmerBox(width: double.infinity, height: 12),
                  SizedBox(height: 4),
                  ShimmerBox(width: double.infinity, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNewsState extends StatelessWidget {
  const _EmptyNewsState();
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
                Icons.newspaper,
                size: 56,
                color: AppColors.cream.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Yangiliklar yo\'q',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tez orada eng so\'nggi yangiliklar\nbu yerda paydo bo\'ladi',
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
