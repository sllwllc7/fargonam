import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../auth/auth_providers.dart';

class Shop {
  final int id;
  final int ownerId;
  final String name;
  final String? description;
  final bool isActive;
  Shop({required this.id, required this.ownerId, required this.name, this.description, required this.isActive});
  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
        id: j['id'] as int,
        ownerId: j['owner_id'] as int,
        name: j['name'] as String,
        description: j['description'] as String?,
        isActive: j['is_active'] as bool,
      );
}

/// Joriy sotuvchining do'koni (birinchi topilgani). Yo'q bo'lsa null.
final myShopProvider = FutureProvider<Shop?>((ref) async {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return null;
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/shops');
  final list = (res.data as List).cast<Map<String, dynamic>>();
  final mine = list.where((s) => s['owner_id'] == user.id).toList();
  if (mine.isEmpty) return null;
  return Shop.fromJson(mine.first);
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
