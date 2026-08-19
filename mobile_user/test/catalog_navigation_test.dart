import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_user/features/cart/cart_screen.dart';
import 'package:mobile_user/features/favorites/favorites_screen.dart';
import 'package:mobile_user/features/kits/kit_providers.dart';
import 'package:mobile_user/features/marketplace/catalog_screen.dart';
import 'package:mobile_user/features/marketplace/category_products_screen.dart';

import 'test_utils.dart';

void main() {
  testWidgets('Kategoriya qatoriga bosilganda Kategoriya ekraniga o\'tiladi', (tester) async {
    useDeviceSize(tester);
    await tester.pumpWidget(wrapScreenWithProviders(
      (child) => ProviderScope(
        overrides: [
          categoriesProvider.overrideWith((ref) async => [
                CategoryItem(id: 1, name: 'Ruchka', slug: 'ruchka', productCount: 12),
                CategoryItem(id: 2, name: 'Daftar', slug: 'daftar', productCount: 8),
              ]),
          kitsProvider.overrideWith((ref) async => <Kit>[]),
          cartProvider.overrideWith((ref) async => <Map<String, dynamic>>[]),
          favoritesProvider.overrideWith((ref) async => <Map<String, dynamic>>[]),
          categoryProductsProvider(1).overrideWith((ref) async => [
                {'id': 100, 'name': 'Alfa ruchka', 'brand': 'Flair', 'min_price': 2500, 'max_price': 2500, 'total_stock': 10, 'variants': []},
                {'id': 101, 'name': 'Gamma ruchka', 'brand': 'Gamma', 'min_price': 2000, 'max_price': 2000, 'total_stock': 5, 'variants': []},
              ]),
        ],
        child: child,
      ),
      const CatalogScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Kategoriyalar'), findsOneWidget);
    expect(find.text('Ruchka'), findsOneWidget);

    await tester.tap(find.text('Ruchka'));
    await tester.pumpAndSettle();

    // Kategoriya ekraniga o'tildi — sarlavha va mahsulot soni ko'rinadi
    expect(find.text('Ruchka'), findsOneWidget);
    expect(find.text('2 ta mahsulot'), findsOneWidget);
    expect(find.text('Alfa ruchka'), findsOneWidget);
    expect(find.text('Gamma ruchka'), findsOneWidget);
  });
}
