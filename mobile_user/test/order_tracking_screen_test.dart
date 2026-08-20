import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_user/features/orders/order_tracking_screen.dart';
import 'package:mobile_user/features/orders/orders_screen.dart';

import 'test_utils.dart';

Map<String, dynamic> _order({String status = 'preparing'}) => {
      'id': 42,
      'status': status,
      'delivery_type': 'delivery',
      'created_at': '2026-08-20T10:00:00Z',
      'total': '25000',
      'items': [
        {'product_name': 'Daftar · 48 varoq', 'quantity': 2, 'price_at_purchase': '12500'},
      ],
    };

void main() {
  testWidgets('Buyurtma holati va mahsulotlar ko\'rsatiladi', (tester) async {
    useDeviceSize(tester);
    await tester.pumpWidget(wrapScreen(
      ProviderScope(
        overrides: [
          myOrdersProvider.overrideWith((ref) async => [_order()]),
        ],
        child: OrderTrackingScreen(order: _order()),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('FN-42'), findsOneWidget);
    expect(find.textContaining('Tayyorlanmoqda'), findsOneWidget);
    expect(find.textContaining('Daftar'), findsOneWidget);
  });

  testWidgets('Ekrandan chiqilganda poll timeri xatosiz to\'xtaydi', (tester) async {
    useDeviceSize(tester);
    await tester.pumpWidget(wrapScreen(
      ProviderScope(
        overrides: [
          myOrdersProvider.overrideWith((ref) async => [_order()]),
        ],
        child: OrderTrackingScreen(order: _order()),
      ),
    ));
    await tester.pumpAndSettle();

    // Ekranni boshqa widget bilan almashtiramiz — dispose() chaqiriladi,
    // Timer bekor qilinishi kerak (aks holda "used after being disposed" xatosi).
    await tester.pumpWidget(wrapScreen(const SizedBox()));
    await tester.pumpAndSettle();
  });
}
