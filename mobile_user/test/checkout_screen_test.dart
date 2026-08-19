import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_user/features/addresses/addresses_screen.dart';
import 'package:mobile_user/features/cart/cart_screen.dart';
import 'package:mobile_user/features/checkout/checkout_screen.dart';

import 'test_utils.dart';

void main() {
  testWidgets('Manzil kiritilmagan bo\'lsa "Buyurtma berish" bosilganda ogohlantirish chiqadi', (tester) async {
    useDeviceSize(tester);
    await tester.pumpWidget(wrapScreen(
      ProviderScope(
        overrides: [
          cartProvider.overrideWith((ref) async => [
                {
                  'id': 1,
                  'product_id': 10,
                  'product_name': 'Alfa ruchka',
                  'variant_name': 'Ko\'k siyoh',
                  'product_price': '2500',
                  'quantity': 1,
                },
              ]),
          // Saqlangan manzil yo'q — foydalanuvchi ham qo'lda kiritmagan
          addressesProvider.overrideWith((ref) async => <Map<String, dynamic>>[]),
        ],
        child: const CheckoutScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Buyurtma berish · 2 500 so‘m'), findsOneWidget);

    await tester.tap(find.text('Buyurtma berish · 2 500 so‘m'));
    await tester.pump(); // SnackBar animatsiyasi boshlanishi uchun bitta freym

    expect(find.text('Manzilni kiriting'), findsOneWidget);
  });

  testWidgets('Saqlangan manzil bo\'lsa avtomatik tanlanadi va tugma faollashadi', (tester) async {
    useDeviceSize(tester);
    await tester.pumpWidget(wrapScreen(
      ProviderScope(
        overrides: [
          cartProvider.overrideWith((ref) async => [
                {
                  'id': 1,
                  'product_id': 10,
                  'product_name': 'Alfa ruchka',
                  'variant_name': 'Ko\'k siyoh',
                  'product_price': '2500',
                  'quantity': 1,
                },
              ]),
          addressesProvider.overrideWith((ref) async => [
                {
                  'id': 5,
                  'label': 'Uy',
                  'is_default': true,
                  'region': 'Farg\'ona',
                  'district': 'Farg\'ona sh.',
                  'address': 'Al-Farg\'oniy ko\'chasi 12',
                },
              ]),
        ],
        child: const CheckoutScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Uy'), findsOneWidget);
    expect(find.text('Do\'kondan olish'), findsOneWidget);
  });
}
