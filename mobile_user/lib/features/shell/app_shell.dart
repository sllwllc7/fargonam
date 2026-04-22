// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/ws_service.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../home/home_feed_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../notifications/notifications_providers.dart';
import '../orders/orders_screen.dart';
import '../taxi/taxi_screen.dart';
import '../profile/profile_screen.dart';

/// Global key — bosh sahifadan tab o'zgartirish uchun.
final appShellKey = GlobalKey<AppShellState>();

// Brend rangi — boshqa fayllar shu nom bilan import qilgan, shuning uchun
// nomni o'zgartirmaslik mumkin (ignore_for_file).
const Color PRIMARY_COLOR = AppColors.cream;

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
    MarketplaceScreen(),
    TaxiScreen(),
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
        'paid' => 'To\'langan',
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
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A),
          border: Border(top: BorderSide(color: Color(0xFF1A1A1A), width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 70,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag,
                  label: 'Do\'kon',
                  isActive: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                _NavItem(
                  icon: Icons.directions_car_outlined,
                  activeIcon: Icons.directions_car,
                  label: 'Taxi',
                  isActive: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
                // Markaziy Home tugmasi
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _index = 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: PRIMARY_COLOR,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: PRIMARY_COLOR.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _index == 2 ? Icons.home : Icons.home_outlined,
                            color: const Color(0xFF0A0A0A),
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? PRIMARY_COLOR : const Color(0xFF888888),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? PRIMARY_COLOR : const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

