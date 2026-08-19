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
  final String name;
  final String? gradeLevel;
  final String? imageUrl;
  final List<KitItem> items;
  final int total;

  Kit({
    required this.id,
    required this.name,
    this.gradeLevel,
    this.imageUrl,
    required this.items,
    required this.total,
  });

  factory Kit.fromJson(Map<String, dynamic> j) => Kit(
        id: j['id'] as int,
        name: j['name'] as String,
        gradeLevel: j['grade_level'] as String?,
        imageUrl: j['image_url'] as String?,
        items: (j['items'] as List? ?? []).cast<Map<String, dynamic>>().map(KitItem.fromJson).toList(),
        total: (j['total'] as num?)?.toInt() ?? 0,
      );
}

/// "Sinf to'plamlari" — HANDOFF.md 2-bo'lim, 2-3-band. Sotuvchilar tuzgan
/// tayyor to'plamlar, real backend'dan (`GET /kits`).
final kitsProvider = FutureProvider<List<Kit>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/kits');
  final list = (res.data as List).cast<Map<String, dynamic>>().map(Kit.fromJson).toList();
  list.sort((a, b) => (int.tryParse(a.gradeLevel ?? '') ?? 99).compareTo(int.tryParse(b.gradeLevel ?? '') ?? 99));
  return list;
});
