import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testlar uchun umumiy o'rovchi — ScreenUtil (`.w`/`.h`/`.sp`/`.r`) va
/// MaterialApp'ni ta'minlaydi. `scopedChild` chaqiruvchi tomonidan
/// ProviderScope bilan allaqachon o'ralgan bo'lishi kerak.
Widget wrapScreen(Widget scopedChild) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (context, _) => MaterialApp(home: scopedChild),
  );
}

/// `wrapScreen`dan farqi: keladigan `scope` funksiyasi (odatda
/// `(child) => ProviderScope(overrides: [...], child: child)`) `MaterialApp`
/// TASHQARISIGA qo'yiladi — shuning uchun `Navigator.push` bilan ochilgan
/// yangi ekranlar ham xuddi shu override'larni ko'radi (navigatsiya testlari
/// uchun). `Override` turini bu faylda nomlash shart emas — chaqiruvchi
/// tomonda avtomatik xulosa qilinadi.
Widget wrapScreenWithProviders(Widget Function(Widget child) scope, Widget child) {
  return scope(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(home: child),
    ),
  );
}

/// `flutter_test`ning standart oyna o'lchami (800x600, landshaft) ScreenUtil
/// masshtabini buzib, haqiqiy telefonda bo'lmaydigan overflow'lar keltirib
/// chiqaradi. Shu funksiya test oynasini haqiqiy telefon o'lchamiga
/// (393x852, iPhone bazasi — HANDOFF.md) o'rnatadi, keyin avtomatik tozalaydi.
void useDeviceSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(393, 852) * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
}
