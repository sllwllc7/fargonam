import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';

/// Sotuvchi statistikasi — `GET /seller/stats` (shops/products/orders/revenue).
/// `seller_home_screen.dart` va `seller_stats_screen.dart` shu providerdan foydalanadi.
final sellerStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.watch(dioProvider).get('/seller/stats');
  return res.data as Map<String, dynamic>;
});
