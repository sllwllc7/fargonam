import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';

/// Bildirishnomalar ro'yxati — barcha ekranlar shu providerdan foydalanadi.
final notificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get('/notifications');
  return (res.data as List).cast<Map<String, dynamic>>();
});

/// O'qilmagan bildirishnomalar soni — badge uchun.
final unreadCountProvider = FutureProvider<int>((ref) async {
  final res = await ref.watch(dioProvider).get('/notifications/unread-count');
  return (res.data['count'] as int?) ?? 0;
});
