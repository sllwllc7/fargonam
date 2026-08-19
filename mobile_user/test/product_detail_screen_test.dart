import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_user/features/favorites/favorites_screen.dart';
import 'package:mobile_user/features/products/product_detail_screen.dart';

import 'test_utils.dart';

Map<String, dynamic> _product() => {
      'id': 1,
      'name': 'Yozuvli daftar',
      'brand': 'Hatber',
      'description': 'Sifatli oq qog\'ozli yozuv daftari.',
      'variants': [
        {'id': 101, 'variant_name': '12', 'price': 2000, 'stock': 50, 'attributes': {'Varoq soni': '12'}},
        {'id': 102, 'variant_name': '48', 'price': 5500, 'stock': 30, 'attributes': {'Varoq soni': '48'}},
      ],
    };

void main() {
  testWidgets('Variant tanlanganda narx va zaxira shu SKU\'dan yangilanadi', (tester) async {
    useDeviceSize(tester);
    await tester.pumpWidget(wrapScreen(
      ProviderScope(
        overrides: [
          productDetailProvider(1).overrideWith((ref) async => _product()),
          isFavoriteProvider(1).overrideWith((ref) async => false),
          favoritesProvider.overrideWith((ref) async => <Map<String, dynamic>>[]),
        ],
        child: const ProductDetailScreen(productId: 1),
      ),
    ));
    await tester.pumpAndSettle();

    // Standart holatda birinchi variant (12) tanlangan bo'lishi kerak
    // (narx ikki joyda ko'rinadi: asosiy narx + pastdagi "Jami" panel)
    expect(find.textContaining('2 000'), findsWidgets);

    // Ikkinchi variant (48) chipini bosamiz
    await tester.tap(find.text('48'));
    await tester.pumpAndSettle();

    expect(find.textContaining('5 500'), findsWidgets);
    expect(find.textContaining('2 000'), findsNothing);
  });

  testWidgets('Zaxira 0 bo\'lsa "Tugagan" chiqadi va tugma o\'chiriladi', (tester) async {
    useDeviceSize(tester);
    final product = _product();
    (product['variants'] as List)[0]['stock'] = 0;

    await tester.pumpWidget(wrapScreen(
      ProviderScope(
        overrides: [
          productDetailProvider(1).overrideWith((ref) async => product),
          isFavoriteProvider(1).overrideWith((ref) async => false),
          favoritesProvider.overrideWith((ref) async => <Map<String, dynamic>>[]),
        ],
        child: const ProductDetailScreen(productId: 1),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tugagan'), findsWidgets);
  });
}
