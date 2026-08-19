import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';

class KitItem {
  final int id;
  final int variantId;
  final int quantity;
  final String? productName;
  final String? variantName;
  final int? price;
  final int? lineTotal;

  KitItem({
    required this.id,
    required this.variantId,
    required this.quantity,
    this.productName,
    this.variantName,
    this.price,
    this.lineTotal,
  });

  factory KitItem.fromJson(Map<String, dynamic> j) => KitItem(
        id: j['id'] as int,
        variantId: j['variant_id'] as int,
        quantity: j['quantity'] as int,
        productName: j['product_name'] as String?,
        variantName: j['variant_name'] as String?,
        price: (j['price'] as num?)?.toInt(),
        lineTotal: (j['line_total'] as num?)?.toInt(),
      );

  String get label => [productName, variantName].where((s) => s != null && s.isNotEmpty).join(' · ');
}

class Kit {
  final int id;
  final int? shopId;
  final String name;
  final String? gradeLevel;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final List<KitItem> items;
  final int total;

  Kit({
    required this.id,
    this.shopId,
    required this.name,
    this.gradeLevel,
    this.description,
    this.imageUrl,
    required this.isActive,
    required this.items,
    required this.total,
  });

  factory Kit.fromJson(Map<String, dynamic> j) => Kit(
        id: j['id'] as int,
        shopId: j['shop_id'] as int?,
        name: j['name'] as String,
        gradeLevel: j['grade_level'] as String?,
        description: j['description'] as String?,
        imageUrl: j['image_url'] as String?,
        isActive: j['is_active'] as bool,
        items: (j['items'] as List? ?? []).cast<Map<String, dynamic>>().map(KitItem.fromJson).toList(),
        total: (j['total'] as num?)?.toInt() ?? 0,
      );
}

final shopKitsProvider = FutureProvider.family<List<Kit>, int>((ref, shopId) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/kits', queryParameters: {'shop_id': shopId});
  return (res.data as List).cast<Map<String, dynamic>>().map(Kit.fromJson).toList();
});

Future<Kit> createKit(
  WidgetRef ref, {
  required int shopId,
  required String name,
  String? gradeLevel,
  String? description,
  required List<({int variantId, int quantity})> items,
}) async {
  final dio = ref.read(dioProvider);
  final res = await dio.post('/kits', data: {
    'shop_id': shopId,
    'name': name,
    if (gradeLevel != null) 'grade_level': gradeLevel,
    if (description != null && description.isNotEmpty) 'description': description,
    'items': [for (final it in items) {'variant_id': it.variantId, 'quantity': it.quantity}],
  });
  ref.invalidate(shopKitsProvider(shopId));
  return Kit.fromJson(res.data as Map<String, dynamic>);
}

Future<void> updateKit(
  WidgetRef ref, {
  required int kitId,
  required int shopId,
  String? name,
  String? gradeLevel,
  String? description,
  bool? isActive,
  List<({int variantId, int quantity})>? items,
}) async {
  final dio = ref.read(dioProvider);
  await dio.put('/kits/$kitId', data: {
    if (name != null) 'name': name,
    if (gradeLevel != null) 'grade_level': gradeLevel,
    if (description != null) 'description': description,
    if (isActive != null) 'is_active': isActive,
    if (items != null) 'items': [for (final it in items) {'variant_id': it.variantId, 'quantity': it.quantity}],
  });
  ref.invalidate(shopKitsProvider(shopId));
}

Future<void> deleteKit(WidgetRef ref, {required int kitId, required int shopId}) async {
  final dio = ref.read(dioProvider);
  await dio.delete('/kits/$kitId');
  ref.invalidate(shopKitsProvider(shopId));
}
