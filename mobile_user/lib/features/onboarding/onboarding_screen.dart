import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.storefront_rounded,
      color: AppColorsDark.primary,
      title: 'Fargonam\'ga xush kelibsiz!',
      description: 'Farg\'ona vodiysi uchun yagona super-app. Do\'konlar, taksi va ko\'p narsa — hammasini bitta ilovada.',
    ),
    _OnboardingPage(
      icon: Icons.shopping_bag_outlined,
      color: AppColorsDark.success,
      title: 'Onlayn xarid qiling',
      description: 'Minglab mahsulotlar, yuzlab do\'konlar. Uydan chiqmasdan buyurtma bering — tez va qulay.',
    ),
    _OnboardingPage(
      icon: Icons.local_taxi,
      color: AppColorsDark.error,
      title: 'Taksi chaqiring',
      description: 'Bir tugma bilan taksi chaqiring. Haydovchini xaritada kuzating, narxni oldindan biling.',
    ),
  ];

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    widget.onDone();
  }

  void _next() {
    HapticFeedback.lightImpact();
    _controller.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // O'tkazish tugmasi
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('O\'tkazish'),
              ),
            ),
            // Sahifalar
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _page = i);
                },
                children: _pages,
              ),
            ),
            // Indikatorlar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: _page == i ? 28 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _page == i
                        ? AppColorsDark.primary
                        : AppColorsDark.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Tugma
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed:
                      _page == _pages.length - 1 ? _finish : _next,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _page == _pages.length - 1
                          ? 'Boshlash'
                          : 'Keyingisi',
                      key: ValueKey(_page == _pages.length - 1),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatefulWidget {
  const _OnboardingPage({required this.icon, required this.color, required this.title, required this.description});
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(widget.icon, size: 64, color: widget.color),
              ),
            ),
            const SizedBox(height: 36),
            FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  Text(widget.title, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                  Text(widget.description, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: AppColorsDark.textSecondary.withValues(alpha: 0.7), height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
