import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// PushService orqali "Buyurtmalar" tabiga o'tish kerak bo'lganda chaqiriladi
/// (main.dart'dagi _BiznesShellState o'rnatadi — onTokenExpired bilan bir xil naqsh).
void Function()? onSellerOrderPushTapped;

/// Background message handler (top-level funksiya bo'lishi shart)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background (seller): ${message.notification?.title}');
}

/// Push notification xizmati — mobile_seller uchun.
///
/// mobile_user/core/push_service.dart'dan farqlari:
///  - Sotuvchiga faqat 'seller_order' turi keladi (yangi buyurtma, xaridor
///    bekor qildi) — chat/ride/order (xaridorga) turlari sotuvchiga
///    yuborilmaydi, shuning uchun tap-handler bitta case bilan cheklangan.
///  - Navigatsiya: mobile_user yangi ekran push qiladi, bu yerda esa
///    "Buyurtmalar" allaqachon pastki tab (IndexedStack) — shuning uchun
///    yangi ekran ochish o'rniga tabga o'tkaziladi (onSellerOrderPushTapped).
///  - Foreground xabar uchun maxsus overlay banner o'rniga oddiy SnackBar
///    ishlatiladi (seller_orders_screen.dart'da allaqachon shu naqsh bor).
class PushService {
  final Ref _ref;
  PushService(this._ref);

  Future<void> init() async {
    try {
      await _doInit();
    } catch (e) {
      debugPrint('Push init xato: $e');
    }
  }

  Future<void> _doInit() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Push notification ruxsat berilmadi');
      return;
    }

    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }
    messaging.onTokenRefresh.listen(_registerToken);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

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

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    debugPrint('FCM foreground (seller): ${notification.title} — ${notification.body}');

    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${notification.title}: ${notification.body}'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Ko\'rish',
          onPressed: () => _handleMessageTap(message),
        ),
      ),
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    final type = message.data['type'];
    debugPrint('FCM tap (seller): type=$type');
    if (type == 'seller_order') {
      onSellerOrderPushTapped?.call();
    }
  }
}

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));
