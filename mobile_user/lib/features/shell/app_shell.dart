// ignore_for_file: constant_identifier_names

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/ws_service.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../home/home_feed_screen.dart';
import '../marketplace/catalog_screen.dart';
import '../notifications/notifications_providers.dart';
import '../orders/orders_screen.dart';
import '../taxi/taxi_coming_soon_screen.dart';
import '../taxi/taxi_screen.dart' show activeRideProvider;
import '../profile/profile_screen.dart';

/// Global key — bosh sahifadan tab o'zgartirish uchun.
final appShellKey = GlobalKey<AppShellState>();

// Brend rangi — boshqa fayllar shu nom bilan import qilgan, shuning uchun
// nomni o'zgartirmaslik mumkin (ignore_for_file).
const Color PRIMARY_COLOR = AppColors.text;

/// Asosiy ilova qobig'i — 5 ta tab.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  AppShellState createState() => AppShellState();
}

class AppShellState extends ConsumerState<AppShell> {
  int _index = 2; // Home default

  // ── Global user WebSocket (real-time events) ──
  ChatWsService? _userWs;

  void switchTab(int index) => setState(() => _index = index);

  final _pages = const [
    CatalogScreen(),
    TaxiComingSoonScreen(),
    HomeFeedScreen(),
    AiAssistantScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectUserWs());
  }

  /// Global WebSocket'ga ulanish — order_status, ride_status, notifications
  /// va chat xabarlari uchun. Foydalanuvchi ilovada bo'lgan vaqtda doim
  /// ulangan bo'ladi.
  Future<void> _connectUserWs() async {
    _userWs = ChatWsService(
      onOrderStatus: (payload) {
        // Buyurtma holati o'zgardi — orders providerini yangilash
        ref.invalidate(myOrdersProvider);
        if (mounted) {
          final status = payload['status'] as String? ?? '';
          final orderId = payload['order_id'];
          final statusText = _orderStatusText(status);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Buyurtma #$orderId: $statusText'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      onRideStatus: (payload) {
        // Sayohat holati o'zgardi — taxi ekranini yangilash
        ref.invalidate(activeRideProvider);
      },
      onNotification: (payload) {
        // Yangi bildirishnoma
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadCountProvider);
      },
      // Chat xabarlari uchun — hozircha chat_screen o'zi ulanib ishlatadi
      onMessage: (_) {
        // Agar foydalanuvchi chat ekranida bo'lmasa, unread hisoblagichni
        // yangilash mumkin (kelajakda)
      },
    );
    await _userWs!.connect(ref.read(secureStorageProvider));
  }

  String _orderStatusText(String s) => switch (s) {
        'pending' => 'Kutilmoqda',
        'paid' => 'Tasdiqlandi',
        'shipped' => 'Yo\'lga chiqdi',
        'delivered' => 'Yetkazildi',
        'cancelled' => 'Bekor qilindi',
        _ => s,
      };

  @override
  void dispose() {
    _userWs?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: AppSizes.bottomNav.h,
            decoration: const BoxDecoration(
              color: Color(0xF5FFFFFF), // rgba(255,255,255,.96)
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 8.w, right: 8.w, top: 8.h, bottom: 24.h),
                  child: Row(
                    children: [
                      _NavItem(
                        icon: Icons.storefront_outlined,
                        activeIcon: Icons.storefront,
                        label: 'Market',
                        isActive: _index == 0,
                        onTap: () => setState(() => _index = 0),
                      ),
                      _NavItem(
                        icon: Icons.local_taxi_outlined,
                        activeIcon: Icons.local_taxi,
                        label: 'Taxi',
                        isActive: _index == 1,
                        onTap: () => setState(() => _index = 1),
                        badgeDot: true,
                      ),
                      const Expanded(child: SizedBox()), // markaziy tugma uchun bo'sh joy
                      _NavItem(
                        icon: Icons.auto_awesome_outlined,
                        activeIcon: Icons.auto_awesome,
                        label: 'AI',
                        isActive: _index == 3,
                        onTap: () => setState(() => _index = 3),
                      ),
                      _NavItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'Profil',
                        isActive: _index == 4,
                        onTap: () => setState(() => _index = 4),
                      ),
                    ],
                  ),
                ),
                // Markaziy Home tugmasi — ko'tarilgan dumaloq, panel balandligiga
                // ta'sir qilmasdan yuqoriga chiqib turadi (CSS margin-top:-18px muodili).
                Positioned(
                  top: -18.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => setState(() => _index = 2),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52.w,
                            height: 52.w,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              gradient: _index == 2 ? AppGradients.primary : null,
                              color: _index == 2 ? null : AppColors.textSecondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.surface, width: 4),
                              boxShadow: AppShadows.fab,
                            ),
                            child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'Bosh sahifa',
                            style: AppTextStyles.small.copyWith(
                              color: _index == 2 ? AppColors.text : AppColors.textSecondary,
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
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeDot = false,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool badgeDot;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.text : AppColors.textSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(horizontal: isActive ? 10.w : 0, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primaryLight.withValues(alpha: 0.55) : Colors.transparent,
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: AnimatedScale(
                      scale: isActive ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      child: Icon(isActive ? activeIcon : icon, color: color, size: 22),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    style: AppTextStyles.small.copyWith(color: color),
                    child: Text(label),
                  ),
                ],
              ),
              if (badgeDot)
                Positioned(
                  top: -2,
                  right: 26.w,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

