import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_user/features/home/home_feed_screen.dart';
import 'package:mobile_user/features/notifications/notifications_providers.dart';
import 'package:mobile_user/features/orders/orders_screen.dart';
import 'package:mobile_user/features/cart/cart_screen.dart';

import 'test_utils.dart';

void main() {
  Widget host(List<Map<String, dynamic>> cart) => wrapScreenWithProviders(
        (child) => ProviderScope(
          overrides: [
            cartProvider.overrideWith((ref) async => cart),
            unreadCountProvider.overrideWith((ref) async => 0),
            myOrdersProvider.overrideWith((ref) async => <Map<String, dynamic>>[]),
            newsProvider.overrideWith((ref) async => <Map<String, dynamic>>[]),
          ],
          child: child,
        ),
        const HomeFeedScreen(),
      );

  testWidgets('render bo\'ladi — salom, brend nomi va bo\'limlar ko\'rinadi', (tester) async {
    useDeviceSize(tester);
    await tester.pumpWidget(host([]));
    await tester.pumpAndSettle();

    expect(find.text('Fargonam'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Yetkazib berish — bepul'), findsOneWidget);
  });

  testWidgets('savat bo\'sh bo\'lsa Savat FAB ko\'rinmaydi', (tester) async {
    useDeviceSize(tester);
    await tester.pumpWidget(host([]));
    await tester.pumpAndSettle();

    expect(find.byType(CartFab), findsNothing);
  });

  testWidgets('savatda mahsulot bo\'lsa Savat FAB soni bilan ko\'rinadi', (tester) async {
    useDeviceSize(tester);
    await tester.pumpWidget(host([
      {'id': 1, 'quantity': 2},
      {'id': 2, 'quantity': 1},
    ]));
    await tester.pumpAndSettle();

    expect(find.byType(CartFab), findsOneWidget);
    // Sarlavhadagi savat ikonkasi va Savat FAB ikkalasi ham sonini ko'rsatadi (dc.html).
    expect(find.text('3'), findsNWidgets(2)); // 2+1 dona
  });
}
