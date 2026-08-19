import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'navigator_key.dart';
import 'theme/app_colors.dart';
import '../features/chat/conversations_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/orders/orders_screen.dart';

/// Background message handler (top-level funksiya bo'lishi shart)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.notification?.title}');
}

/// Push notification xizmati
class PushService {
  final Ref _ref;
  PushService(this._ref);

  /// Firebase Messaging'ni boshlash va tokenni backend'ga yuborish
  Future<void> init() async {
    try {
      await _doInit();
    } catch (e) {
      debugPrint('Push init xato: $e');
    }
  }

  Future<void> _doInit() async {
    final messaging = FirebaseMessaging.instance;

    // Ruxsat so'rash (iOS va Android 13+ uchun)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Push notification ruxsat berilmadi');
      return;
    }

    // FCM tokenni olish va backend'ga yuborish
    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Token yangilanganda
    messaging.onTokenRefresh.listen(_registerToken);

    // Foreground xabarlar
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Notification bosilganda (app background'da bo'lganda)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // App notification orqali ochilganda (app yopiq bo'lganda)
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  /// FCM tokenni backend'ga ro'yxatdan o'tkazish
  Future<void> _registerToken(String token) async {
    try {
      await _ref.read(dioProvider).post('/push/register', data: {
        'token': token,
        'platform': 'android',
      });
      debugPrint('FCM token ro\'yxatdan o\'tdi: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('FCM token ro\'yxatdan o\'tkazishda xato: $e');
    }
  }

  /// Logout'da tokenni o'chirish
  Future<void> unregister() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _ref.read(dioProvider).delete('/push/unregister', queryParameters: {'token': token});
      }
    } catch (e) {
      debugPrint('Push unregister xato: $e');
    }
  }

  /// Foreground'da kelgan xabarni banner sifatida ko'rsatish
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint('FCM foreground: ${notification.title} — ${notification.body}');

    final context = navigatorKey.currentContext;
    if (context == null) return;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _InAppBanner(
        title: notification.title ?? '',
        body: notification.body ?? '',
        type: message.data['type'] ?? '',
        onDismiss: () => entry.remove(),
        onTap: () {
          entry.remove();
          _handleMessageTap(message);
        },
      ),
    );
    overlay.insert(entry);

    // 4 soniyadan keyin avtomatik yopish
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  /// Notification bosilganda — tegishli sahifaga o'tish
  void _handleMessageTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    debugPrint('FCM tap: type=$type, data=$data');

    final nav = navigatorKey.currentState;
    if (nav == null) return;

    switch (type) {
      case 'order' || 'seller_order':
        nav.push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
      case 'chat':
        nav.push(MaterialPageRoute(builder: (_) => const ConversationsScreen()));
      case 'ride':
        // Taksi tabi — AppShell'ga qaytish yetarli
        break;
      default:
        nav.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    }
  }
}

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));

/// In-app push banner — tepada ko'rinadi
class _InAppBanner extends StatefulWidget {
  const _InAppBanner({
    required this.title,
    required this.body,
    required this.type,
    required this.onDismiss,
    required this.onTap,
  });
  final String title;
  final String body;
  final String type;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  @override
  State<_InAppBanner> createState() => _InAppBannerState();
}

class _InAppBannerState extends State<_InAppBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnim = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  IconData get _icon => switch (widget.type) {
    'order' || 'seller_order' => Icons.receipt_long,
    'chat' => Icons.chat_bubble,
    'ride' => Icons.local_taxi,
    _ => Icons.notifications,
  };

  Color get _color => switch (widget.type) {
    'order' || 'seller_order' => AppColors.primary,
    'chat' => AppColors.success,
    'ride' => const Color(0xFFC77B1E), // DESIGN.md warning
    _ => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTap: widget.onTap,
          onVerticalDragEnd: (_) => widget.onDismiss(),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _color.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_icon, color: _color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        if (widget.body.isNotEmpty)
                          Text(widget.body, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                    onPressed: widget.onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
