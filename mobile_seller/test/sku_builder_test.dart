import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_seller/features/products/sku_builder.dart';

void main() {
  group('cartesianCombos', () {
    test('parametrsiz mahsulot — bitta bo\'sh kombinatsiya (Standart)', () {
      final combos = cartesianCombos([]);
      expect(combos, [{}]);
    });

    test('bitta parametr, 3 qiymat — 3 ta SKU', () {
      final combos = cartesianCombos([SkuAttribute(name: 'Varoq soni', values: ['12', '36', '48'])]);
      expect(combos.length, 3);
      expect(combos, [
        {'Varoq soni': '12'},
        {'Varoq soni': '36'},
        {'Varoq soni': '48'},
      ]);
    });

    test('ikkita parametr (2x3) — 6 ta kombinatsiya', () {
      final combos = cartesianCombos([
        SkuAttribute(name: 'Varoq soni', values: ['12', '36']),
        SkuAttribute(name: 'Muqova', values: ['Klassik', 'Geometrik', 'Pastel']),
      ]);
      expect(combos.length, 6);
      expect(combos.first, {'Varoq soni': '12', 'Muqova': 'Klassik'});
      expect(combos.last, {'Varoq soni': '36', 'Muqova': 'Pastel'});
    });

    test('qiymati bo\'sh parametr e\'tiborga olinmaydi', () {
      final combos = cartesianCombos([
        SkuAttribute(name: 'Bo\'sh', values: []),
        SkuAttribute(name: 'Rang', values: ['Ko\'k', 'Qora']),
      ]);
      expect(combos.length, 2);
    });
  });

  group('comboSignature', () {
    test('bir xil kombinatsiya bir xil signature beradi', () {
      final a = comboSignature({'Rang': 'Ko\'k', 'Hajm': 'M'});
      final b = comboSignature({'Rang': 'Ko\'k', 'Hajm': 'M'});
      expect(a, b);
    });

    test('turli kombinatsiya turli signature beradi', () {
      final a = comboSignature({'Rang': 'Ko\'k'});
      final b = comboSignature({'Rang': 'Qora'});
      expect(a, isNot(b));
    });
  });

  group('SkuRow', () {
    test('label — attributesiz "Standart"', () {
      final row = SkuRow(attrs: const {});
      expect(row.label, 'Standart');
      row.dispose();
    });

    test('label — attributlar qiymatlarini birlashtiradi', () {
      final row = SkuRow(attrs: const {'Varoq soni': '48', 'Muqova': 'Klassik'});
      expect(row.label, '48 · Klassik');
      row.dispose();
    });
  });
}
