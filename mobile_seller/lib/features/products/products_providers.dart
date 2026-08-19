import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';

class ProductVariant {
  final int id;
  final int productId;
  final String sku;
  final String variantName;
  final int price;
  final int? oldPrice;
  final int stock;
  final Map<String, dynamic> attributes;
  final String? imageUrl;
  final bool isActive;
  final int sortOrder;

  ProductVariant({
    required this.id,
    required this.productId,
    required this.sku,
    required this.variantName,
    required this.price,
    this.oldPrice,
    required this.stock,
    required this.attributes,
    this.imageUrl,
    required this.isActive,
    required this.sortOrder,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> j) => ProductVariant(
        id: j['id'] as int,
        productId: j['product_id'] as int,
        sku: j['sku'] as String,
        variantName: j['variant_name'] as String,
        price: (j['price'] as num).toInt(),
        oldPrice: (j['old_price'] as num?)?.toInt(),
        stock: j['stock'] as int,
        attributes: Map<String, dynamic>.from(j['attributes'] as Map? ?? {}),
        imageUrl: j['image_url'] as String?,
        isActive: j['is_active'] as bool,
        sortOrder: j['sort_order'] as int? ?? 0,
      );
}

class Product {
  final int id;
  final int shopId;
  final int? categoryId;
  final String name;
  final String? brand;
  final String? description;
  final String price; // "dan boshlab" narx — eski moslik (default variant)
  final int stock;
  final String? imageUrl;
  final bool isActive;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.shopId,
    this.categoryId,
    required this.name,
    this.brand,
    this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
    required this.isActive,
    this.variants = const [],
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as int,
        shopId: j['shop_id'] as int,
        categoryId: j['category_id'] as int?,
        name: j['name'] as String,
        brand: j['brand'] as String?,
        description: j['description'] as String?,
        price: j['price'].toString(),
        stock: j['stock'] as int? ?? 0,
        imageUrl: j['image_url'] as String?,
        isActive: j['is_active'] as bool,
        variants: (j['variants'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(ProductVariant.fromJson)
            .toList(),
      );
}

class Category {
  final int id;
  final String name;
  final String slug;
  final int? parentId;
  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
  });
  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as int,
        name: j['name'] as String,
        slug: j['slug'] as String,
        parentId: j['parent_id'] as int?,
      );
}

/// Barcha kategoriyalar — kamdan-kam o'zgaradi, keshda saqlanadi.
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  ref.keepAlive();
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/categories');
  return (res.data as List)
      .cast<Map<String, dynamic>>()
      .map(Category.fromJson)
      .toList();
});

String _slugify(String s) {
  return s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r"['’‘ʻʼ`]"), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

Future<Category> createCategory(WidgetRef ref, {required String name}) async {
  final dio = ref.read(dioProvider);
  final res = await dio.post('/categories', data: {
    'name': name,
    'slug': _slugify(name),
  });
  ref.invalidate(categoriesProvider);
  return Category.fromJson(res.data as Map<String, dynamic>);
}

/// Berilgan do'kon mahsulotlari.
final shopProductsProvider = FutureProvider.family<List<Product>, int>((ref, shopId) async {
  final dio = ref.watch(dioProvider);
  // Backend '/products' limit'ni 200 bilan cheklaydi (le=200) — undan oshsa 422 qaytadi.
  final res = await dio.get('/products', queryParameters: {'shop_id': shopId, 'limit': 200});
  final items = (res.data['items'] as List).cast<Map<String, dynamic>>();
  return items.map(Product.fromJson).toList();
});

final productDetailProvider = FutureProvider.family<Product, int>((ref, productId) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/products/$productId');
  return Product.fromJson(res.data as Map<String, dynamic>);
});

/// Mahsulot + birinchi SKU'ni bitta so'rovda yaratadi ("Standart" default
/// variant — backend avtomatik yaratadi, `price`/`stock` shundan olinadi).
Future<Product> createProduct(
  WidgetRef ref, {
  required int shopId,
  int? categoryId,
  required String name,
  String? brand,
  String? description,
  required int price,
  required int stock,
}) async {
  final dio = ref.read(dioProvider);
  final res = await dio.post('/products', data: {
    'shop_id': shopId,
    'category_id': ?categoryId,
    'name': name,
    if (brand != null && brand.isNotEmpty) 'brand': brand,
    if (description != null && description.isNotEmpty) 'description': description,
    'price': price,
    'stock': stock,
  });
  ref.invalidate(shopProductsProvider(shopId));
  return Product.fromJson(res.data as Map<String, dynamic>);
}

Future<void> updateProductBase(
  WidgetRef ref, {
  required int productId,
  required int shopId,
  String? name,
  String? brand,
  String? description,
  int? categoryId,
}) async {
  final dio = ref.read(dioProvider);
  await dio.patch('/products/$productId', data: {
    'name': ?name,
    'brand': brand,
    'description': description,
    'category_id': ?categoryId,
  });
  ref.invalidate(shopProductsProvider(shopId));
}

Future<ProductVariant> createProductVariant(
  WidgetRef ref, {
  required int productId,
  required String variantName,
  required int price,
  required int stock,
  Map<String, dynamic> attributes = const {},
  int sortOrder = 0,
}) async {
  final dio = ref.read(dioProvider);
  final res = await dio.post('/products/$productId/variants', data: {
    'variant_name': variantName,
    'price': price,
    'stock': stock,
    'attributes': attributes,
    'sort_order': sortOrder,
  });
  return ProductVariant.fromJson(res.data as Map<String, dynamic>);
}

Future<ProductVariant> updateProductVariant(
  WidgetRef ref, {
  required int productId,
  required int variantId,
  String? variantName,
  int? price,
  int? stock,
  Map<String, dynamic>? attributes,
}) async {
  final dio = ref.read(dioProvider);
  final res = await dio.patch('/products/$productId/variants/$variantId', data: {
    'variant_name': ?variantName,
    'price': ?price,
    'stock': ?stock,
    'attributes': ?attributes,
  });
  return ProductVariant.fromJson(res.data as Map<String, dynamic>);
}

Future<void> deleteProductVariant(WidgetRef ref, {required int productId, required int variantId}) async {
  final dio = ref.read(dioProvider);
  await dio.delete('/products/$productId/variants/$variantId');
}

Future<Product> uploadProductImage(WidgetRef ref, {required int productId, required String filePath}) async {
  final dio = ref.read(dioProvider);
  final form = FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
  final res = await dio.post('/products/$productId/image', data: form);
  return Product.fromJson(res.data as Map<String, dynamic>);
}
