import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'config.dart';

/// Sayohat kuzatish uchun WebSocket — haydovchi joylashuvini yuboradi
class DriverRideWsService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  int? _rideId;

  /// Yo'lovchi tomondan kelgan status o'zgarishi callback'i (agar kerak bo'lsa)
  final void Function(String status)? onStatusChange;

  DriverRideWsService({this.onStatusChange});

  /// WebSocket'ga ulanish
  Future<bool> connect(int rideId, FlutterSecureStorage storage) async {
    final token = await storage.read(key: 'access_token');
    if (token == null) return false;

    final wsBase = AppConfig.apiBaseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    final uri = Uri.parse('$wsBase/ws/ride/$rideId?token=$token');

    try {
      _channel = WebSocketChannel.connect(uri);
      _rideId = rideId;
      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            if (msg['type'] == 'status') {
              final status = msg['status'] as String?;
              if (status != null) onStatusChange?.call(status);
            }
          } catch (e) {
            debugPrint('Driver WS parse xato: $e');
          }
        },
        onError: (e) => debugPrint('Driver WS error: $e'),
        onDone: () => debugPrint('Driver WS yopildi'),
      );
      debugPrint('Driver WS ulandi: ride/$rideId');
      return true;
    } catch (e) {
      debugPrint('Driver WS ulanishda xato: $e');
      return false;
    }
  }

  /// Haydovchi joylashuvini yuborish
  void sendLocation(double lat, double lng) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'location',
      'lat': lat,
      'lng': lng,
    }));
  }

  /// Sayohat holatini yuborish (arrived, in_progress, completed)
  void sendStatus(String status) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'status',
      'status': status,
    }));
  }

  /// Ulanishni yopish
  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _rideId = null;
    debugPrint('Driver WS uzildi');
  }

  bool get isConnected => _channel != null;
  int? get rideId => _rideId;
}

/// Buyurtma holati o'zgarishlarini real-time olish uchun — backend'ning
/// umumiy /ws/chat kanaliga ulanadi (mobile_user'dagi ChatWsService bilan
/// bir xil kanal, lekin bu yerda faqat 'order_status' turi kerak —
/// sotuvchiga chat/typing/ride eventlari kelmaydi).
class SellerOrderEventsWsService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _closed = false;
  Timer? _reconnectTimer;
  FlutterSecureStorage? _storage;

  final void Function(Map<String, dynamic> payload)? onOrderStatus;

  SellerOrderEventsWsService({this.onOrderStatus});

  Future<void> connect(FlutterSecureStorage storage) async {
    _storage = storage;
    _closed = false;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_closed) return;
    final token = await _storage?.read(key: AppConfig.accessTokenKey);
    if (token == null) return;

    final wsBase = AppConfig.apiBaseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    final uri = Uri.parse('$wsBase/ws/chat?token=$token');

    try {
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: (e) {
          debugPrint('Seller order WS error: $e');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('Seller order WS yopildi');
          _scheduleReconnect();
        },
      );
      debugPrint('Seller order WS ulandi');
    } catch (e) {
      debugPrint('Seller order WS ulanishda xato: $e');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final msg = jsonDecode(data as String) as Map<String, dynamic>;
      if (msg['type'] == 'order_status') {
        onOrderStatus?.call(msg);
      }
    } catch (e) {
      debugPrint('Seller order WS parse xato: $e');
    }
  }

  void _scheduleReconnect() {
    if (_closed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_closed) _doConnect();
    });
  }

  /// Ilova fonga o'tganda chaqiriladi — qayta ulanish rejalashtirilmaydi,
  /// lekin `_closed=false` qoladi, chunki reconnect() chaqirilganda
  /// state avtomatik tozalanadi.
  void pause() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  /// Ilova oldinga qaytganda — qayta ulanish.
  Future<void> resume() async {
    if (_closed || _storage == null) return;
    await _doConnect();
  }

  void disconnect() {
    _closed = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    debugPrint('Seller order WS uzildi (manual)');
  }
}
