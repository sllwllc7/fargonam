import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_user/features/cart/cart_screen.dart';

import 'test_utils.dart';

void main() {
  testWidgets('Savat bo\'sh bo\'lsa "Savat bo\'sh" holati ko\'rsatiladi', (tester) async {
    useDeviceSize(tester);
    await tester.pumpWidget(wrapScreen(
      ProviderScope(
        overrides: [cartProvider.overrideWith((ref) async => <Map<String, dynamic>>[])],
        child: const CartScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Savat bo\'sh'), findsOneWidget);
    expect(find.text('Buyurtmani rasmiylashtirish'), findsNothing);
  });

  testWidgets('Savatda mahsulot bo\'lsa jami narx va checkout tugmasi ko\'rsatiladi', (tester) async {
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
                  'quantity': 2,
                },
                {
                  'id': 2,
                  'product_id': 11,
                  'product_name': 'Yozuvli daftar',
                  'variant_name': '48 varoq',
                  'product_price': '5500',
                  'quantity': 1,
                },
              ]),
        ],
        child: const CartScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    // (2500*2) + (5500*1) = 10500
    expect(find.textContaining('10 500'), findsOneWidget);
    expect(find.text('Buyurtmani rasmiylashtirish'), findsOneWidget);
    expect(find.text('Alfa ruchka'), findsOneWidget);
    expect(find.text('Yozuvli daftar'), findsOneWidget);
  });

  testWidgets('Miqdor 1 bo\'lganda "-" bosilsa 0 ga tushmaydi (tarmoqqa so\'rov yubormaydi)', (tester) async {
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
        ],
        child: const CartScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    // `_changeQty` next<1 bo'lsa erta qaytadi — tarmoq so'rovi yuborilmaydi,
    // shuning uchun qiymat hali ham "1" (0 emas).
    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });
}
