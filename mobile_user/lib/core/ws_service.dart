import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'config.dart';

/// HTTP → WebSocket URL konvertori
String _wsBase() => AppConfig.apiBaseUrl
    .replaceFirst('http://', 'ws://')
    .replaceFirst('https://', 'wss://');

// ══════════════════════════════════════════════════════════════
// RIDE WS SERVICE — sayohat tracking
// ══════════════════════════════════════════════════════════════

class RideWsService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final void Function(double lat, double lng)? onDriverLocation;
  final void Function(String status)? onStatusChange;

  RideWsService({this.onDriverLocation, this.onStatusChange});

  Future<void> connect(int rideId, FlutterSecureStorage storage) async {
    final token = await storage.read(key: AppConfig.accessTokenKey);
    if (token == null) return;

    final uri = Uri.parse('${_wsBase()}/ws/ride/$rideId?token=$token');

    try {
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            final type = msg['type'] as String?;
            if (type == 'location') {
              final lat = (msg['lat'] as num?)?.toDouble();
              final lng = (msg['lng'] as num?)?.toDouble();
              if (lat != null && lng != null) {
                onDriverLocation?.call(lat, lng);
              }
            } else if (type == 'status') {
              final status = msg['status'] as String?;
              if (status != null) onStatusChange?.call(status);
            }
          } catch (e) {
            debugPrint('WS parse xato: $e');
          }
        },
        onError: (e) => debugPrint('Ride WS error: $e'),
        onDone: () => debugPrint('Ride WS yopildi'),
      );
      debugPrint('Ride WS ulandi: ride/$rideId');
    } catch (e) {
      debugPrint('Ride WS ulanishda xato: $e');
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    debugPrint('Ride WS uzildi');
  }

  void sendLocation(double lat, double lng) {
    _channel?.sink.add(jsonEncode({
      'type': 'location',
      'lat': lat,
      'lng': lng,
    }));
  }
}

// ══════════════════════════════════════════════════════════════
// CHAT / USER WS SERVICE — chat xabarlar + user-scoped eventlar
// ══════════════════════════════════════════════════════════════

/// Chat xabari — WebSocket orqali keladi
class ChatMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final String text;
  final String createdAt;
  final bool isMine;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    required this.isMine,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as int,
        senderId: j['sender_id'] as int,
        receiverId: (j['receiver_id'] as int?) ?? 0,
        text: j['text'] as String,
        createdAt: j['created_at'] as String,
        isMine: j['is_mine'] == true,
      );
}

/// Chat va user-scoped eventlar uchun WebSocket xizmati.
/// Server /ws/chat endpoint orqali bir nechta event turini yuboradi:
///   - message: chat xabari
///   - typing: raqib yozyapti
///   - order_status: buyurtma holati o'zgardi
///   - ride_status: sayohat holati o'zgardi
///   - notification: yangi bildirishnoma
class ChatWsService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _closed = false;
  Timer? _reconnectTimer;
  FlutterSecureStorage? _storage;

  /// Callbacklar
  final void Function(ChatMessage msg)? onMessage;
  final void Function(int senderId)? onTyping;
  final void Function(Map<String, dynamic> payload)? onOrderStatus;
  final void Function(Map<String, dynamic> payload)? onRideStatus;
  final void Function(Map<String, dynamic> payload)? onNotification;

  ChatWsService({
    this.onMessage,
    this.onTyping,
    this.onOrderStatus,
    this.onRideStatus,
    this.onNotification,
  });

  Future<void> connect(FlutterSecureStorage storage) async {
    _storage = storage;
    _closed = false;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_closed) return;
    final token = await _storage?.read(key: AppConfig.accessTokenKey);
    if (token == null) return;

    final uri = Uri.parse('${_wsBase()}/ws/chat?token=$token');
    try {
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: (e) {
          debugPrint('Chat WS error: $e');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('Chat WS yopildi');
          _scheduleReconnect();
        },
      );
      debugPrint('Chat WS ulandi');
    } catch (e) {
      debugPrint('Chat WS ulanishda xato: $e');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final msg = jsonDecode(data as String) as Map<String, dynamic>;
      final type = msg['type'] as String?;
      switch (type) {
        case 'message':
          onMessage?.call(ChatMessage.fromJson(msg));
          break;
        case 'typing':
          final sid = msg['sender_id'] as int?;
          if (sid != null) onTyping?.call(sid);
          break;
        case 'order_status':
          onOrderStatus?.call(msg);
          break;
        case 'ride_status':
          onRideStatus?.call(msg);
          break;
        case 'notification':
          onNotification?.call(msg);
          break;
      }
    } catch (e) {
      debugPrint('Chat WS parse xato: $e');
    }
  }

  void _scheduleReconnect() {
    if (_closed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_closed) _doConnect();
    });
  }

  /// Xabar yuborish
  void sendMessage({required int receiverId, required String text}) {
    _channel?.sink.add(jsonEncode({
      'type': 'message',
      'receiver_id': receiverId,
      'text': text,
    }));
  }

  /// Yozyapti event
  void sendTyping({required int receiverId}) {
    _channel?.sink.add(jsonEncode({
      'type': 'typing',
      'receiver_id': receiverId,
    }));
  }

  void disconnect() {
    _closed = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    debugPrint('Chat WS uzildi (manual)');
  }
}
