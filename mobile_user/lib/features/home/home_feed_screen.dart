import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../marketplace/marketplace_screen.dart' show marketFilterProvider, MarketFilter;
import '../news/news_screen.dart';
import '../notifications/notifications_providers.dart';
import '../notifications/notifications_screen.dart';
import '../products/product_detail_screen.dart';
import '../search/search_screen.dart';
import '../shell/app_shell.dart' show appShellKey, PRIMARY_COLOR;
import '../stories/story_viewer_screen.dart';

// ── Provayderlar ────────────────────────────────────────────

final bannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.keepAlive(); // Tab almashganda qayta yuklanmasin
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/feed/banners');
  return ((res.data as List?) ?? []).cast<Map<String, dynamic>>();
});

final categoriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.keepAlive(); // Kategoriyalar kamdan-kam o'zgaradi — kesh
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/categories');
  return ((res.data as List?) ?? []).cast<Map<String, dynamic>>();
});

final topProductsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.keepAlive();
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/products', queryParameters: {'limit': 10});
  return (((res.data is Map ? res.data['items'] : res.data) ?? []) as List)
      .cast<Map<String, dynamic>>();
});

final announcementsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.keepAlive();
  final res = await ref
      .watch(dioProvider)
      .get('/announcements', queryParameters: {'limit': 5});
  return ((res.data as List?) ?? []).cast<Map<String, dynamic>>();
});


// ── Asosiy ekran ────────────────────────────────────────────

class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.cream,
        backgroundColor: AppColors.surfaceHigh,
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.invalidate(bannersProvider);
          ref.invalidate(categoriesProvider);
          ref.invalidate(topProductsProvider);
          ref.invalidate(newsProvider);
          ref.invalidate(unreadCountProvider);
          ref.invalidate(announcementsProvider);
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _HeaderSection()),
            const SliverToBoxAdapter(child: _AnnouncementsBanner()),

            // ── QIDIRUV ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SearchScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.divider, width: 0.5),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search,
                            color: AppColors.textMuted, size: 20),
                        SizedBox(width: 10),
                        Text('Mahsulot yoki do\'kon qidiring...',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: _CategoryChips()),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            const SliverToBoxAdapter(child: _BannerCarousel()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── MASHHUR MAHSULOTLAR ──
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Yangi mahsulotlar',
                onSeeAll: () {
                  HapticFeedback.lightImpact();
                  appShellKey.currentState?.switchTab(0);
                },
              ),
            ),
            const SliverToBoxAdapter(child: _ProductHorizontalList()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── YANGILIKLAR ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('So\'nggi yangiliklar',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NewsListScreen()));
                      },
                      child: const Text('Barchasi →'),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _NewsCards()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HEADER — shahar rasmi + Dynamic Island avatar
// ══════════════════════════════════════════════════════════════

class _HeaderSection extends ConsumerWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(bannersProvider);
    final countAsync = ref.watch(unreadCountProvider);
    final unread = countAsync.when(
        data: (v) => v, error: (_, _) => 0, loading: () => 0);

    final stories = bannersAsync.when(
      data: (banners) =>
          banners.map((b) => StoryItem.fromJson(b)).toList(),
      error: (_, _) => <StoryItem>[],
      loading: () => <StoryItem>[],
    );

    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          // ── Fon rasmi ──
          Positioned.fill(
            child: bannersAsync.when(
              data: (banners) {
                final mediaUrl = banners.isNotEmpty
                    ? banners.first['media_url'] as String?
                    : null;
                if (mediaUrl != null && mediaUrl.isNotEmpty) {
                  final url = mediaUrl.startsWith('http')
                      ? mediaUrl
                      : '${AppConfig.apiBaseUrl}$mediaUrl';
                  return AppCachedImage(
                    url: url,
                    borderRadius: 0,
                    fit: BoxFit.cover,
                  );
                }
                return _defaultBg();
              },
              error: (_, _) => _defaultBg(),
              loading: () => _defaultBg(),
            ),
          ),

          // ── Gradient overlay ──
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.1),
                    AppColors.bg.withValues(alpha: 0.8),
                    AppColors.bg,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // ── Content ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _DynamicIslandAvatar(stories: stories),
                    const Spacer(),
                    const Text(
                      'Farg\'onam',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 8)
                        ],
                      ),
                    ),
                    const Spacer(),
                    _NotificationBell(unread: unread),
                  ],
                ),
              ),
            ),
          ),

          // ── Pastdagi tagline ──
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xush kelibsiz!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 10)
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Farg\'ona vodiysi super-app',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 6)
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultBg() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a1d3a), Color(0xFF2a3254)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
}

// ── Dynamic Island Avatar ──

class _DynamicIslandAvatar extends StatelessWidget {
  const _DynamicIslandAvatar({required this.stories});
  final List<StoryItem> stories;

  @override
  Widget build(BuildContext context) {
    final hasStories = stories.isNotEmpty;
    return GestureDetector(
      onTap: hasStories
          ? () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (_, _, _) => StoryViewerScreen(
                      stories: stories, initialIndex: 0),
                  transitionsBuilder: (_, anim, _, child) =>
                      FadeTransition(opacity: anim, child: child),
                  transitionDuration:
                      const Duration(milliseconds: 200),
                ),
              );
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: const Color(0xFF0A0A0A),
          border: hasStories
              ? Border.all(color: PRIMARY_COLOR, width: 2.5)
              : Border.all(color: Colors.white24, width: 1),
          boxShadow: hasStories
              ? [
                  BoxShadow(
                      color: PRIMARY_COLOR.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2)
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.cream, AppColors.creamDim],
                ),
              ),
              child: const Icon(Icons.person,
                  color: Color(0xFF0A0A0A), size: 20),
            ),
            if (hasStories) ...[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${stories.length} story',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'Ko\'rish →',
                    style: TextStyle(color: Colors.white54, fontSize: 9),
                  ),
                ],
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Notification Bell ──

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unread});
  final int unread;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const NotificationsScreen()));
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_outlined,
                color: Colors.white, size: 22),
            if (unread > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SECTION HEADER
// ══════════════════════════════════════════════════════════════

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
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          TextButton(
              onPressed: onSeeAll, child: const Text('Barchasi →')),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// KATEGORIYALAR
// ══════════════════════════════════════════════════════════════

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips();

  static const _icons = [
    Icons.checkroom,
    Icons.fastfood,
    Icons.phone_android,
    Icons.home_work,
    Icons.sports_soccer,
    Icons.auto_awesome,
    Icons.local_florist,
    Icons.build,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoriesProvider);
    return catsAsync.when(
      loading: () => const _CategorySkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (cats) {
        if (cats.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            itemCount: cats.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final c = cats[i];
              return _PressableScale(
                onTap: () {
                  HapticFeedback.selectionClick();
                  // Kategoriyaga filter o'rnatib, marketplace tab'ga o'tish
                  ref.read(marketFilterProvider.notifier).update(
                      MarketFilter(categoryId: c['id'] as int));
                  appShellKey.currentState?.switchTab(0);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.cream.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.cream
                                .withValues(alpha: 0.15)),
                      ),
                      child: Icon(_icons[i % _icons.length],
                          color: AppColors.cream),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 70,
                      child: Text(
                        c['name'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
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

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ShimmerBox(width: 56, height: 56, borderRadius: 16),
            SizedBox(height: 6),
            ShimmerBox(width: 50, height: 10, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// BANNER KARUSEL — auto-scroll + indicator
// ══════════════════════════════════════════════════════════════

class _BannerCarousel extends ConsumerStatefulWidget {
  const _BannerCarousel();

  @override
  ConsumerState<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<_BannerCarousel> {
  final _pageCtrl = PageController(viewportFraction: 0.92);
  int _currentPage = 0;
  Timer? _autoTimer;
  int _bannersCount = 0;

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoTimer?.cancel();
    if (_bannersCount < 2) return;
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageCtrl.hasClients) return;
      final next = (_currentPage + 1) % _bannersCount;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);
    return bannersAsync.when(
      loading: () => const _BannerSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();
        if (_bannersCount != banners.length) {
          _bannersCount = banners.length;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _startAutoScroll());
        }
        return Column(
          children: [
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: banners.length,
                padEnds: false,
                onPageChanged: (i) {
                  setState(() => _currentPage = i);
                  HapticFeedback.selectionClick();
                },
                itemBuilder: (context, i) {
                  final b = banners[i];
                  final url =
                      '${AppConfig.apiBaseUrl}${b['media_url']}';
                  final linkUrl = b['link_url'] as String?;
                  return _PressableScale(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      // Banner tap → agar link_url bo'lsa brauzerda ochish,
                      // aks holda StoryViewerScreen'ga banner'ni story
                      // sifatida ochish
                      if (linkUrl != null && linkUrl.isNotEmpty) {
                        final uri = Uri.tryParse(linkUrl);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                          return;
                        }
                      }
                      // Fallback: shu banner'ni story sifatida ochish
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoryViewerScreen(
                            stories: banners
                                .map((x) => StoryItem.fromJson(x))
                                .toList(),
                            initialIndex: i,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AppCachedImage(
                              url: url,
                              borderRadius: 0,
                              fit: BoxFit.cover,
                            ),
                            // Bottom gradient + sarlavha
                            if (b['title'] != null)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 24, 16, 14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black
                                            .withValues(alpha: 0.65),
                                      ],
                                    ),
                                  ),
                                  child: Text(
                                    b['title'] as String,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                      shadows: [
                                        Shadow(
                                            color: Colors.black54,
                                            blurRadius: 6),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(banners.length, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.cream
                        : AppColors.cream.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ShimmerBox(
        width: MediaQuery.of(context).size.width - 32,
        height: 180,
        borderRadius: 20,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MAHSULOTLAR LIST
// ══════════════════════════════════════════════════════════════

class _ProductHorizontalList extends ConsumerWidget {
  const _ProductHorizontalList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prodsAsync = ref.watch(topProductsProvider);
    return prodsAsync.when(
      loading: () => const _ProductMiniSkeleton(),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('$e',
            style: const TextStyle(color: AppColors.textMuted)),
      ),
      data: (products) {
        if (products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Hali mahsulot yo\'q',
                style: TextStyle(color: AppColors.textMuted)),
          );
        }
        return SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) =>
                _ProductMiniCard(product: products[i]),
          ),
        );
      },
    );
  }
}

class _ProductMiniSkeleton extends StatelessWidget {
  const _ProductMiniSkeleton();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => Container(
          width: 150,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(
                  flex: 3,
                  child: ShimmerBox(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 0)),
              Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 100, height: 12),
                    SizedBox(height: 6),
                    ShimmerBox(width: 60, height: 14),
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

class _ProductMiniCard extends StatelessWidget {
  const _ProductMiniCard({required this.product});
  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    final imgUrl = product['image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    final productId = product['id'] as int;
    return _PressableScale(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    ProductDetailScreen(productId: productId)));
      },
      child: SizedBox(
        width: 150,
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
              Expanded(
                flex: 3,
                child: Hero(
                  tag: 'product_image_$productId',
                  child: fullImg != null
                      ? AppCachedImage(
                          url: fullImg,
                          borderRadius: 0,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.surfaceHigh,
                          child: const Icon(Icons.image_outlined,
                              size: 36,
                              color: AppColors.textSecondary)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatPrice(product['price']?.toString() ?? '0'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.cream,
                        letterSpacing: -0.2,
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

// ══════════════════════════════════════════════════════════════
// E'LONLAR BANNERI
// ══════════════════════════════════════════════════════════════

class _AnnouncementsBanner extends ConsumerWidget {
  const _AnnouncementsBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final annsAsync = ref.watch(announcementsProvider);
    return annsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (anns) {
        if (anns.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              for (final a in anns) _AnnouncementCard(announcement: a),
            ],
          ),
        );
      },
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});
  final Map<String, dynamic> announcement;

  @override
  Widget build(BuildContext context) {
    final type = announcement['type'] as String;
    final priority = announcement['priority'] as String;

    final (bgColor, icon, iconColor) = switch (priority) {
      'urgent' => (
          const Color(0xFF3D1F1F),
          Icons.warning_amber,
          AppColors.error
        ),
      'important' => (
          const Color(0xFF3D351F),
          Icons.info_outline,
          AppColors.warning
        ),
      _ => switch (type) {
          'event' => (
              const Color(0xFF1F2A3D),
              Icons.event,
              AppColors.info
            ),
          'promo' => (
              AppColors.cream.withValues(alpha: 0.08),
              Icons.campaign,
              AppColors.cream
            ),
          _ => (
              AppColors.surfaceHigh,
              Icons.notifications_outlined,
              AppColors.textSecondary
            ),
        },
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: priority == 'urgent'
            ? Border.all(color: AppColors.error.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(announcement['title'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(announcement['body'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// YANGILIKLAR
// ══════════════════════════════════════════════════════════════

class _NewsCards extends ConsumerWidget {
  const _NewsCards();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);
    return newsAsync.when(
      loading: () => const _NewsSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (news) {
        if (news.isEmpty) return const SizedBox.shrink();
        final show = news.take(3).toList();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (final n in show) _NewsCard(news: n),
            ],
          ),
        );
      },
    );
  }
}

class _NewsSkeleton extends StatelessWidget {
  const _NewsSkeleton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(2, (_) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                    height: 160,
                    borderRadius: 0),
                Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 80, height: 10),
                      SizedBox(height: 8),
                      ShimmerBox(
                          width: double.infinity, height: 14),
                      SizedBox(height: 6),
                      ShimmerBox(width: 200, height: 14),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _NewsCard extends ConsumerStatefulWidget {
  const _NewsCard({required this.news});
  final Map<String, dynamic> news;

  @override
  ConsumerState<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends ConsumerState<_NewsCard>
    with SingleTickerProviderStateMixin {
  late bool _liked;
  late int _likesCount;
  bool _likeBusy = false;
  late final AnimationController _likeAnimCtrl;

  @override
  void initState() {
    super.initState();
    _liked = widget.news['is_liked'] == true;
    _likesCount = (widget.news['likes_count'] as int?) ?? 0;
    _likeAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
  }

  @override
  void dispose() {
    _likeAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_likeBusy) return;
    HapticFeedback.lightImpact();
    setState(() {
      _liked = !_liked;
      _likesCount += _liked ? 1 : -1;
      _likeBusy = true;
    });
    _likeAnimCtrl.forward(from: 0);
    try {
      final res = await ref
          .read(dioProvider)
          .post('/news/${widget.news['id']}/like');
      final serverLiked = res.data['liked'] == true;
      if (mounted && serverLiked != _liked) {
        setState(() {
          _liked = serverLiked;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = !_liked;
          _likesCount += _liked ? 1 : -1;
        });
      }
    } finally {
      if (mounted) setState(() => _likeBusy = false);
    }
  }

  Future<void> _share() async {
    HapticFeedback.lightImpact();
    final title = widget.news['title'] as String;
    await Share.share('$title\n\nFargonam ilovasida ko\'ring');
  }

  @override
  Widget build(BuildContext context) {
    final news = widget.news;
    final imgUrl = news['image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    final dt = DateTime.tryParse(news['created_at'] as String? ?? '');
    final date = dt != null
        ? '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}'
        : '';
    final commentsCount = news['comments_count'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            SizedBox(
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppCachedImage(
                    url: fullImg,
                    borderRadius: 0,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: PRIMARY_COLOR,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('YANGILIK',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0A0A0A))),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (date.isNotEmpty)
                  Text(date,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(news['title'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.3)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Like
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleLike,
                      child: AnimatedBuilder(
                        animation: _likeAnimCtrl,
                        builder: (_, child) {
                          final t = _likeAnimCtrl.value;
                          // Scale burst
                          final scale = 1.0 +
                              0.4 *
                                  (t < 0.5
                                      ? Curves.easeOut.transform(t * 2)
                                      : Curves.easeIn
                                          .transform((1 - t) * 2));
                          return Transform.scale(
                              scale: scale, child: child);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                _liked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                                color: _liked
                                    ? AppColors.error
                                    : AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text('$_likesCount',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _liked
                                        ? AppColors.error
                                        : AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Comment
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showComments(context, news['id'] as int);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline,
                              size: 18, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text('$commentsCount',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Share
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _share,
                      child: const Icon(Icons.share_outlined,
                          size: 18, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComments(BuildContext context, int newsId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CommentsSheet(newsId: newsId),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// COMMENTS SHEET
// ══════════════════════════════════════════════════════════════

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.newsId});
  final int newsId;
  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await ref
          .read(dioProvider)
          .get('/news/${widget.newsId}/comments');
      if (!mounted) return;
      setState(() {
        _comments = (res.data as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Izohlar yuklanmadi: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (_ctrl.text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _sending = true);
    try {
      await ref.read(dioProvider).post(
          '/news/${widget.newsId}/comments',
          data: {'text': _ctrl.text.trim()});
      _ctrl.clear();
      await _load();
    } catch (e) {
      debugPrint('Izoh yuborilmadi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izoh yuborishda xato'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Izohlar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const _CommentsSkeleton()
                  : _comments.isEmpty
                      ? const _EmptyCommentsState()
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          itemCount: _comments.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final c = _comments[i];
                            final name = c['user_name'] as String? ?? '?';
                            return Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      AppColors.surfaceHigh,
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.cream),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.w700,
                                              fontSize: 13,
                                              color: AppColors
                                                  .textPrimary)),
                                      const SizedBox(height: 2),
                                      Text(c['text'] as String,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors
                                                  .textSecondary,
                                              height: 1.3)),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
            ),
            // Input
            Container(
              padding: EdgeInsets.fromLTRB(
                  12,
                  10,
                  12,
                  MediaQuery.of(context).viewInsets.bottom + 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        decoration: InputDecoration(
                          hintText: 'Izoh yozing...',
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.surfaceHigh,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sending ? null : _send,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _sending
                              ? AppColors.surfaceBright
                              : AppColors.cream,
                          shape: BoxShape.circle,
                        ),
                        child: _sending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.cream),
                              )
                            : const Icon(Icons.send,
                                color: AppColors.midnightIndigo,
                                size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsSkeleton extends StatelessWidget {
  const _CommentsSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerBox(width: 36, height: 36, borderRadius: 18),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 90, height: 12),
                SizedBox(height: 6),
                ShimmerBox(width: double.infinity, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCommentsState extends StatelessWidget {
  const _EmptyCommentsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 56,
              color: AppColors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text('Hali izoh yo\'q',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Birinchi bo\'lib izoh qoldiring',
              style:
                  TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PRESSABLE SCALE WRAPPER
// ══════════════════════════════════════════════════════════════

class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════════════

String _formatPrice(String raw) {
  final num = double.tryParse(raw);
  if (num == null) return '$raw UZS';
  final intStr = num.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(' ');
    buf.write(intStr[i]);
  }
  return '$buf UZS';
}
