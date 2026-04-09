import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';

class Product {
  final int id;
  final int shopId;
  final String name;
  final String? description;
  final String price; // string sifatida (Decimal)
  final int stock;
  final String? imageUrl;
  final bool isActive;
  Product({
    required this.id,
    required this.shopId,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
    required this.isActive,
  });
  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as int,
        shopId: j['shop_id'] as int,
        name: j['name'] as String,
        description: j['description'] as String?,
        price: j['price'].toString(),
        stock: j['stock'] as int,
        imageUrl: j['image_url'] as String?,
        isActive: j['is_active'] as bool,
      );
}

/// Berilgan do'kon mahsulotlari.
final shopProductsProvider =
    FutureProvider.family<List<Product>, int>((ref, shopId) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/products', queryParameters: {'shop_id': shopId, 'limit': 100});
  final items = (res.data['items'] as List).cast<Map<String, dynamic>>();
  return items.map(Product.fromJson).toList();
});

Future<Product> createProduct(
  WidgetRef ref, {
  required int shopId,
  required String name,
  String? description,
  required String price,
  required int stock,
}) async {
  final dio = ref.read(dioProvider);
  final res = await dio.post('/products', data: {
    'shop_id': shopId,
    'name': name,
    if (description != null && description.isNotEmpty) 'description': description,
    'price': price,
    'stock': stock,
  });
  ref.invalidate(shopProductsProvider(shopId));
  return Product.fromJson(res.data as Map<String, dynamic>);
}

Future<Product> uploadProductImage(WidgetRef ref, {required int productId, required String filePath}) async {
  final dio = ref.read(dioProvider);
  final form = FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
  final res = await dio.post('/products/$productId/image', data: form);
  return Product.fromJson(res.data as Map<String, dynamic>);
}
