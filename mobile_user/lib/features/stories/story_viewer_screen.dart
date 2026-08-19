import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../core/config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets.dart';

/// Bitta story ma'lumoti (banner'dan olinadi).
class StoryItem {
  final int id;
  final String title;
  final String? body;
  final String mediaUrl;
  final String? linkUrl;
  final String? createdAt;

  const StoryItem({
    required this.id,
    required this.title,
    this.body,
    required this.mediaUrl,
    this.linkUrl,
    this.createdAt,
  });

  factory StoryItem.fromJson(Map<String, dynamic> j) => StoryItem(
        id: j['id'] as int,
        title: j['title'] as String,
        body: j['body'] as String?,
        mediaUrl: j['media_url'] as String,
        linkUrl: j['link_url'] as String?,
        createdAt: j['created_at'] as String?,
      );

  /// To'liq media URL — agar allaqachon absolyut bo'lsa, base qo'shmasin
  String get fullMediaUrl {
    if (mediaUrl.startsWith('http://') || mediaUrl.startsWith('https://')) {
      return mediaUrl;
    }
    return '${AppConfig.apiBaseUrl}$mediaUrl';
  }

  /// Video yoki rasm ekanligini aniqlash
  bool get isVideo =>
      mediaUrl.contains('.mp4') ||
      mediaUrl.contains('.webm') ||
      mediaUrl.contains('.mov');

  /// Qachon yaratilganini chiroyli ko'rsatish
  String get timeAgo {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt!);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'hozirgina';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m avval';
    if (diff.inHours < 24) return '${diff.inHours}s avval';
    return '${diff.inDays}k avval';
  }
}

/// Story viewer — Instagram/Telegram uslubida to'liq ekranli reklama ko'rish.
class StoryViewerScreen extends ConsumerStatefulWidget {
  final List<StoryItem> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;
  bool _isPaused = false;

  // Dizayn ranglari (AppColors'dan)
  static const _surfaceBg = AppColorsDark.background;
  static const _surfaceBright = AppColorsDark.surfaceAlt;
  static const _primaryFixed = AppColorsDark.primary;
  static final _primaryFixedDim = AppColorsDark.primary.withValues(alpha: 0.7);

  // Story davomiyligi (sekundda)
  static const _storyDuration = Duration(seconds: 6);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    )..addStatusListener(_onProgressDone);
    _startStory();

    // Status bar yashirish
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _progressController.dispose();
    // Status bar qaytarish
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onProgressDone(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _goNext();
    }
  }

  void _startStory() {
    _progressController.reset();
    _progressController.forward();
  }

  void _goNext() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _startStory();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startStory();
    } else {
      _progressController.reset();
      _progressController.forward();
    }
  }

  void _pause() {
    if (!_isPaused) {
      _isPaused = true;
      _progressController.stop();
    }
  }

  void _resume() {
    if (_isPaused) {
      _isPaused = false;
      _progressController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: _surfaceBg,
      body: GestureDetector(
        // Pastga surish — yopish
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 300) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // === BACKGROUND IMAGE ===
            _StoryBackground(story: story),

            // === GRADIENT OVERLAY ===
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _surfaceBg.withValues(alpha: 0.8),
                      Colors.transparent,
                      Colors.transparent,
                      _surfaceBg.withValues(alpha: 0.95),
                    ],
                    stops: const [0.0, 0.2, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            // === TAP ZONES (chapga, pauza, o'ngga) ===
            Positioned.fill(
              child: Row(
                children: [
                  // Chapga — oldingi story
                  Expanded(
                    child: GestureDetector(
                      onTap: _goPrev,
                      onLongPressStart: (_) => _pause(),
                      onLongPressEnd: (_) => _resume(),
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  // O'rtada — pauza
                  Expanded(
                    child: GestureDetector(
                      onLongPressStart: (_) => _pause(),
                      onLongPressEnd: (_) => _resume(),
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  // O'ngga — keyingi story
                  Expanded(
                    child: GestureDetector(
                      onTap: _goNext,
                      onLongPressStart: (_) => _pause(),
                      onLongPressEnd: (_) => _resume(),
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),

            // === TOP HEADER ===
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  // Progress barlar
                  _StoryProgressBars(
                    total: widget.stories.length,
                    current: _currentIndex,
                    controller: _progressController,
                  ),
                  const SizedBox(height: 16),
                  // Header — avatar, nom, vaqt, tugmalar
                  Row(
                    children: [
                      // Chap — admin info
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _surfaceBright.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _primaryFixed.withValues(alpha: 0.2),
                                  ),
                                  gradient: LinearGradient(
                                    colors: [_primaryFixed, _primaryFixedDim],
                                  ),
                                ),
                                child: const Icon(Icons.storefront_rounded,
                                    size: 16, color: AppColors.primary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'FARGONAM',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                        color: _primaryFixed,
                                      ),
                                    ),
                                    Text(
                                      'Reklama • ${story.timeAgo}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Yopish tugmasi
                      _HeaderButton(
                        icon: Icons.close,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // === BOTTOM CONTENT ===
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sarlavha
                      _StoryTitle(title: story.title),
                      if (story.body != null && story.body!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          story.body!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 24),
                      // CTA tugmalar
                      Row(
                        children: [
                          if (story.linkUrl != null && story.linkUrl!.isNotEmpty)
                            Expanded(
                              child: _CtaButton(
                                label: 'Batafsil',
                                onTap: () async {
                                  HapticFeedback.lightImpact();
                                  _pause();
                                  final uri =
                                      Uri.tryParse(story.linkUrl!);
                                  if (uri != null &&
                                      await canLaunchUrl(uri)) {
                                    await launchUrl(uri,
                                        mode: LaunchMode
                                            .externalApplication);
                                  } else if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Havola ochilmadi: ${story.linkUrl}'),
                                        duration: const Duration(
                                            milliseconds: 1600),
                                      ),
                                    );
                                  }
                                  _resume();
                                },
                              ),
                            )
                          else
                            const Spacer(),
                          const SizedBox(width: 12),
                          // Share tugmasi
                          _ShareButton(
                            onTap: () {
                              _pause();
                              Share.share(
                                '${story.title}\nFargonam ilovasida ko\'ring!',
                              ).then((_) => _resume());
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Yopish ko'rsatmasi
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'YOPISH UCHUN PASTGA SURING',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

/// Story fon — rasm yoki video.
class _StoryBackground extends StatefulWidget {
  final StoryItem story;
  const _StoryBackground({required this.story});

  @override
  State<_StoryBackground> createState() => _StoryBackgroundState();
}

class _StoryBackgroundState extends State<_StoryBackground> {
  VideoPlayerController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.story.isVideo) _initVideo();
  }

  Future<void> _initVideo() async {
    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(widget.story.fullMediaUrl),
    );
    await ctrl.initialize();
    ctrl.setLooping(true);
    ctrl.setVolume(0);
    ctrl.play();
    if (mounted) setState(() => _ctrl = ctrl);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.story.isVideo) {
      if (_ctrl == null || !_ctrl!.value.isInitialized) {
        return Container(color: AppColorsDark.background,
          child: const Center(child: CircularProgressIndicator(color: AppColorsDark.primary)));
      }
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _ctrl!.value.size.width,
            height: _ctrl!.value.size.height,
            child: VideoPlayer(_ctrl!),
          ),
        ),
      );
    }
    return AppCachedImage(
      url: widget.story.fullMediaUrl,
      borderRadius: 0,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

/// Progress barlar — hozirgi story animatsiya bilan.
class _StoryProgressBars extends StatelessWidget {
  final int total;
  final int current;
  final AnimationController controller;

  const _StoryProgressBars({
    required this.total,
    required this.current,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3,
                child: i < current
                    // Oldingi story'lar — to'liq
                    ? const LinearProgressIndicator(
                        value: 1.0,
                        backgroundColor: Color(0x33FFFFFF),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColorsDark.primary),
                      )
                    : i == current
                        // Hozirgi story — animatsiyali
                        ? AnimatedBuilder(
                            animation: controller,
                            builder: (_, _) => LinearProgressIndicator(
                              value: controller.value,
                              backgroundColor: const Color(0x33FFFFFF),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColorsDark.primary),
                            ),
                          )
                        // Keyingi story'lar — bo'sh
                        : const LinearProgressIndicator(
                            value: 0.0,
                            backgroundColor: Color(0x33FFFFFF),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.transparent),
                          ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Sarlavha — Stitch dizayniga mos (bold, tight tracking).
class _StoryTitle extends StatelessWidget {
  final String title;
  const _StoryTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: AppColorsDark.primary,
        height: 1.15,
        letterSpacing: -1,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// "Batafsil" CTA tugma — vanilla shimmer gradient.
class _CtaButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CtaButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColorsDark.primary, AppColorsDark.primary.withValues(alpha: 0.7)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColorsDark.background.withValues(alpha: 0.8),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

/// Share tugma — shaffof yumaloq.
class _ShareButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ShareButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Icon(Icons.share, color: AppColorsDark.primary),
      ),
    );
  }
}

/// Header tugmalari (more, close).
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColorsDark.surfaceAlt.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(icon, color: AppColorsDark.primary, size: 20),
      ),
    );
  }
}
