import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/api_client.dart';
import '../cart/cart_screen.dart' show CartScreen, cartProvider;
import '../notifications/notifications_providers.dart';
import '../notifications/notifications_screen.dart';
import '../orders/orders_screen.dart' show myOrdersProvider, OrdersScreen;
import '../shell/app_shell.dart' show appShellKey;

final newsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/news', queryParameters: {'limit': 10});
  return (res.data['items'] as List).cast<Map<String, dynamic>>();
});

const _cartIconSvg =
    '<svg viewBox="0 0 24 24"><path d="M5 8h14l-1.2 10.5a2 2 0 0 1-2 1.5H8.2a2 2 0 0 1-2-1.5Z" stroke="#000" stroke-width="1.7" stroke-linejoin="round" fill="none"/>'
    '<path d="M9 10V6a3 3 0 0 1 6 0v4" stroke="#000" stroke-width="1.7" stroke-linecap="round" fill="none"/></svg>';

const _bellIconSvg =
    '<svg viewBox="0 0 20 20"><path d="M10 2.2a4.8 4.8 0 0 0-4.8 4.8v2.6c0 .5-.15 1-.42 1.5L3.5 12.8c-.4.7.1 1.6.9 1.6h11.2c.8 0 1.3-.9.9-1.6l-1.28-1.7a2.8 2.8 0 0 1-.42-1.5V7A4.8 4.8 0 0 0 10 2.2Z" stroke="#000" stroke-width="1.6" stroke-linejoin="round" fill="none"/>'
    '<path d="M8 16a2 2 0 0 0 4 0" stroke="#000" stroke-width="1.6" fill="none"/></svg>';

const _bagIconSvg =
    '<svg viewBox="0 0 24 24"><path d="M3.5 9.5 5 4.5h14l1.5 5M3.5 9.5a2.4 2.4 0 0 0 4.3 1.2 2.4 2.4 0 0 0 4.2 0 2.4 2.4 0 0 0 4.2 0 2.4 2.4 0 0 0 4.3-1.2M5 11.8V20h14v-8.2M9.5 20v-5h5v5" stroke="#fff" stroke-width="1.8" stroke-linejoin="round" stroke-linecap="round" fill="none"/></svg>';

const _chevronIconSvg =
    '<svg viewBox="0 0 8 14"><path d="m1 1 6 6-6 6" stroke="#000" stroke-width="2" stroke-linecap="round" fill="none"/></svg>';

const _truckIconSvg =
    '<svg viewBox="0 0 24 24"><path d="M4 7h16v13H4zM4 7l2-3h12l2 3M9 11h6" stroke="#000" stroke-width="1.7" stroke-linejoin="round" stroke-linecap="round" fill="none"/></svg>';

const _deliveryIconSvg =
    '<svg viewBox="0 0 20 20"><path d="M2 5h9v9H2zM11 8h4l3 3v3h-7" stroke="#000" stroke-width="1.6" stroke-linejoin="round" fill="none"/>'
    '<circle cx="6" cy="15.5" r="1.6" fill="#000"/><circle cx="15" cy="15.5" r="1.6" fill="#000"/></svg>';

/// Bosh sahifa — HANDOFF.md 2-bo'lim, 1-band. Salom + "Fargonam"; savat/
/// qo'ng'iroq tugmalari; Market hero karta; faol buyurtma; yetkazib berish
/// karta; Yangiliklar ro'yxati.
class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final unreadAsync = ref.watch(unreadCountProvider);
    final ordersAsync = ref.watch(myOrdersProvider);
    final newsAsync = ref.watch(newsProvider);

    final cartCount = cartAsync.maybeWhen(
      data: (items) => items.fold<int>(0, (s, it) => s + ((it['quantity'] as int?) ?? 1)),
      orElse: () => 0,
    );
    final unread = unreadAsync.maybeWhen(data: (n) => n, orElse: () => 0);
    final activeOrder = ordersAsync.maybeWhen(
      data: (orders) {
        for (final o in orders) {
          final status = o['status'] as String?;
          if (status != null && status != 'delivered' && status != 'cancelled') return o;
        }
        return null;
      },
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ScreenFadeIn(
              child: ListView(
                padding: EdgeInsets.only(bottom: AppSizes.tabBarHeight + AppSizes.tabBarBottomInset + 22),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Assalomu alaykum 👋'.toUpperCase(), style: AppTypography.eyebrow),
                              const SizedBox(height: 2),
                              Text('Fargonam', style: AppTypography.brandTitle),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _HeaderIconButton(
                          svg: _cartIconSvg,
                          count: cartCount,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            pushAppRoute(context, (_) => const CartScreen());
                          },
                        ),
                        const SizedBox(width: 8),
                        _HeaderIconButton(
                          svg: _bellIconSvg,
                          count: unread,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            pushAppRoute(context, (_) => const NotificationsScreen());
                          },
                        ),
                      ],
                    ),
                  ),
                  _HeroMarketCard(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      appShellKey.currentState?.switchTab(0);
                    },
                  ),
                  if (activeOrder != null)
                    _RowCard(
                      delayMs: 60,
                      iconSvg: _truckIconSvg,
                      iconColor: AppColors.textMuted,
                      title: 'FN-${activeOrder['id']} · ${_statusLabel(activeOrder['status'] as String? ?? '')}',
                      subtitle: 'Buyurtmani kuzatish uchun bosing',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        pushAppRoute(context, (_) => const OrdersScreen());
                      },
                    ),
                  _RowCard(
                    delayMs: 120,
                    iconSvg: _deliveryIconSvg,
                    iconColor: AppColors.textPrimary,
                    title: 'Yetkazib berish — bepul',
                    subtitle: 'To\'lov yetkazib berishda: naqd yoki karta',
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Text('Yangiliklar'.toUpperCase(), style: AppTypography.sectionLabel),
                  ),
                  newsAsync.when(
                    loading: () => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: List.generate(
                          2,
                          (_) => const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: ShimmerBox(width: double.infinity, height: 72, borderRadius: AppRadius.card),
                          ),
                        ),
                      ),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (items) {
                      if (items.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(children: [
                          for (var i = 0; i < items.length; i++)
                            FadeUpItem(
                              delay: AppMotion.staggerStep * i,
                              child: _NewsCard(item: items[i]),
                            ),
                        ]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (cartCount > 0)
            CartFab(
              cartCount: cartCount,
              onTap: () {
                HapticFeedback.lightImpact();
                pushAppRoute(context, (_) => const CartScreen());
              },
            ),
        ],
      ),
    );
  }

  static String _statusLabel(String s) => switch (s) {
        'pending' => 'Qabul qilindi',
        'preparing' => 'Tayyorlanmoqda',
        'ready' => 'Tayyor',
        'shipped' => 'Kuryerda',
        'delivered' => 'Yetkazildi',
        'cancelled' => 'Bekor qilingan',
        _ => s,
      };
}

class _HeaderIconButton extends StatefulWidget {
  const _HeaderIconButton({required this.svg, required this.count, required this.onTap});
  final String svg;
  final int count;
  final VoidCallback onTap;

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: AppMotion.pressedDuration,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: AppColors.border, blurRadius: 2, offset: const Offset(0, 1))],
              ),
              alignment: Alignment.center,
              child: SvgPicture.string(
                widget.svg,
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn),
              ),
            ),
            if (widget.count > 0)
              Positioned(
                top: -3,
                right: -3,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1),
                  duration: AppMotion.pop,
                  curve: AppMotion.standard,
                  builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.count}',
                      style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
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

class _HeroMarketCard extends StatefulWidget {
  const _HeroMarketCard({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_HeroMarketCard> createState() => _HeroMarketCardState();
}

class _HeroMarketCardState extends State<_HeroMarketCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return FadeUpItem(
      child: GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: AppMotion.pressedDuration,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          decoration: const BoxDecoration(
            boxShadow: [BoxShadow(color: Color(0x4D101F38), blurRadius: 28, offset: Offset(0, 12))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            child: Stack(
              children: [
                // dc.html: background:url(...) center 30%/cover — butun kartani qoplaydi.
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/fergana-gate.png',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.4),
                  ),
                ),
                // dc.html: inset:0 gradient — rasm bilan bir xil to'liq maydonni qoplaydi
                // (padding ICHIDA emas — shu joyda avval "chok" xatosi bor edi).
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-0.9, -0.42),
                        end: Alignment(0.9, 0.42),
                        stops: [0.25, 0.62, 1],
                        colors: [
                          Color(0xCC081223),
                          Color(0x66081223),
                          Color(0x1F081223),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Market', style: AppTypography.heroTitle),
                                const SizedBox(height: 5),
                                Text(
                                  'Maktab va ofis uchun kerakli barcha narsalar bir joyda',
                                  style: AppTypography.heroSubtitle.copyWith(color: Colors.white.withValues(alpha: 0.78)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: const Color(0x1FCCD0CF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: SvgPicture.string(_bagIconSvg, width: 27, height: 27),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Color(0xFFEDF1F7)],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: const Color(0x1F171327)),
                          boxShadow: const [BoxShadow(color: Color(0x401E0F05), blurRadius: 8, offset: Offset(0, 3))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Xarid qilishni boshlash',
                                style: AppTypography.pillButton,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 7),
                            SvgPicture.string(_chevronIconSvg, width: 7, height: 12),
                          ],
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
      ),
    );
  }
}

class _RowCard extends StatefulWidget {
  const _RowCard({
    required this.iconSvg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.delayMs = 0,
  });
  final String iconSvg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final int delayMs;

  @override
  State<_RowCard> createState() => _RowCardState();
}

class _RowCardState extends State<_RowCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: SvgPicture.string(
              widget.iconSvg,
              width: 19,
              height: 19,
              colorFilter: ColorFilter.mode(widget.iconColor, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: AppTypography.rowTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(widget.subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          if (widget.onTap != null)
            SvgPicture.string(
              _chevronIconSvg,
              width: 8,
              height: 14,
              colorFilter: const ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
            ),
        ],
      ),
    );

    final tappable = widget.onTap == null
        ? card
        : GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onTap,
            child: AnimatedScale(scale: _pressed ? 0.98 : 1.0, duration: AppMotion.pressedDuration, child: card),
          );
    return FadeUpItem(delay: Duration(milliseconds: widget.delayMs), child: tappable);
  }
}

class _NewsCard extends StatefulWidget {
  const _NewsCard({required this.item});
  final Map<String, dynamic> item;

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final time = _relativeTime(widget.item['created_at'] as String?);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: AppMotion.pressedDuration,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(13)),
                alignment: Alignment.center,
                child: SvgPicture.string(
                  _bellIconSvg,
                  width: 21,
                  height: 21,
                  colorFilter: const ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            widget.item['title'] as String? ?? '',
                            style: AppTypography.newsTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(time, style: AppTypography.timeLabel),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item['body'] as String? ?? '',
                      style: AppTypography.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  static String _relativeTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 24) return 'Bugun';
    if (diff.inDays == 1) return 'Kecha';
    if (diff.inDays < 7) return '${diff.inDays} kun oldin';
    return '${dt.day}-${_month(dt.month)}';
  }

  static String _month(int m) => const [
        'yan', 'fev', 'mar', 'apr', 'may', 'iyun', 'iyul', 'avg', 'sen', 'okt', 'noy', 'dek'
      ][m - 1];
}
