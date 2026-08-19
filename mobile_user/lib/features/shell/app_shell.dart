import 'package:fargonam_ui/fargonam_ui.dart' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme/app_colors.dart';
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

/// Asosiy ilova qobig'i — 5 ta tab, suzuvchi tab bar (`fargonam_ui`).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  AppShellState createState() => AppShellState();
}

class AppShellState extends ConsumerState<AppShell> {
  int _index = 2; // Asosiy (Home) default

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
    return PopScope(
      // Orqaga tugmasi ilovadan chiqarib yubormasin: Asosiy tabda bo'lmasa
      // shu tabga o'tkazadi, Asosiy tabda bo'lsa hech narsa qilmaydi.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_index != 2) setState(() => _index = 2);
      },
      child: Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _pages),
          ui.FloatingTabBar(activeIndex: _index, onTap: (i) => setState(() => _index = i)),
        ],
      ),
      ),
    );
  }
}
