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
