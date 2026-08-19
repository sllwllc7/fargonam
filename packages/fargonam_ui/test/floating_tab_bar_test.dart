import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(int active, ValueChanged<int> onTap) => MaterialApp(
        home: Scaffold(
          body: Stack(children: [FloatingTabBar(activeIndex: active, onTap: onTap)]),
        ),
      );

  testWidgets('5 ta tab ko\'rsatiladi, aynan shu nomlar bilan', (tester) async {
    await tester.pumpWidget(host(2, (_) {}));
    await tester.pumpAndSettle();
    for (final label in ['Market', 'Taxi', 'Asosiy', 'AI', 'Profil']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('boshqa tabga bosilganda onTap to\'g\'ri index bilan chaqiriladi', (tester) async {
    int? tapped;
    await tester.pumpWidget(host(2, (i) => tapped = i));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Market'));
    await tester.pump();

    expect(tapped, 0);
  });

  testWidgets('faol tab bo\'rtmasi tepaga ko\'tariladi (translateY -24)', (tester) async {
    await tester.pumpWidget(host(0, (_) {})); // Market faol
    await tester.pumpAndSettle();

    final lifted = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .where((c) => c.transform?.getTranslation().y == -24);

    expect(lifted.length, 1);
  });
}
