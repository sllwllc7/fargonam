/// HANDOFF.md narx formati: minglik bo'shliq bilan, "so'm" ajralmas.
String formatSom(num value) {
  final s = value.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '$buf so\'m';
}
