import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../auth/auth_providers.dart';

/// KYC holati
enum ShopStatus { pending, approved, rejected }

class Shop {
  final int id;
  final int ownerId;
  final String name;
  final String? description;
  final bool isActive;
  final ShopStatus status;

  Shop({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.isActive,
    this.status = ShopStatus.pending,
  });

  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
        id: j['id'] as int,
        ownerId: j['owner_id'] as int,
        name: j['name'] as String,
        description: j['description'] as String?,
        isActive: j['is_active'] as bool,
        status: _parseStatus(j['status'] as String? ?? 'pending'),
      );

  static ShopStatus _parseStatus(String s) {
    switch (s) {
      case 'approved': return ShopStatus.approved;
      case 'rejected': return ShopStatus.rejected;
      default: return ShopStatus.pending;
    }
  }
}

/// Joriy sotuvchining do'konlari — `/seller/shops` dan, status'dan qat'iy nazar.
final myShopProvider = FutureProvider<Shop?>((ref) async {
  ref.watch(authControllerProvider).user; // auth o'zgarsa qayta yuklasin
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/seller/shops');
  final list = (res.data as List).cast<Map<String, dynamic>>();
  if (list.isEmpty) return null;
  return Shop.fromJson(list.first);
});

Future<Shop> createShop(WidgetRef ref, {required String name, String? description}) async {
  final dio = ref.read(dioProvider);
  final res = await dio.post('/shops', data: {
    'name': name,
    if (description != null && description.isNotEmpty) 'description': description,
  });
  ref.invalidate(myShopProvider);
  return Shop.fromJson(res.data as Map<String, dynamic>);
}
