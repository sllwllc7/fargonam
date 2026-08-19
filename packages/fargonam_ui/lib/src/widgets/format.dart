/// Narxni "UZS" bilan formatlash: 1250000 -> "1 250 000 UZS" (ichki/dashboard ekranlar).
String formatPrice(num value) {
  final intStr = value.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(' ');
    buf.write(intStr[i]);
  }
  return '$buf UZS';
}

/// HANDOFF.md narx formati: minglik buzilmas bo'shliq (NBSP, U+00A0) bilan,
/// "so'm" ajralmas — 2500 -> "2 500 so'm" (mahsulot narxi, savat, checkout).
String formatSom(num value) {
  const nbsp = ' ';
  final intStr = value.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(nbsp);
    buf.write(intStr[i]);
  }
  buf.write('$nbsp' 'so‘m');
  return buf.toString();
}
