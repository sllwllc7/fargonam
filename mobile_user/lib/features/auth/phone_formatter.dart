import 'package:flutter/services.dart';

/// O'zbekiston telefon raqami formatlovchisi.
///
/// Foydalanuvchi raqam tersa: +998 (90) 123-45-67
/// `toRaw()` qaytaradi: +998901234567
class PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Faqat raqamlarni olamiz
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    // Doim 998 prefiks
    String body;
    if (digits.startsWith('998')) {
      body = digits.substring(3);
    } else if (digits.length <= 9) {
      body = digits;
    } else {
      body = digits.substring(digits.length - 9);
    }
    if (body.length > 9) body = body.substring(0, 9);

    final buf = StringBuffer('+998');
    if (body.isNotEmpty) {
      buf.write(' (');
      buf.write(body.substring(0, body.length.clamp(0, 2)));
      if (body.length >= 2) buf.write(')');
      if (body.length > 2) {
        buf.write(' ');
        buf.write(body.substring(2, body.length.clamp(0, 5)));
      }
      if (body.length > 5) {
        buf.write('-');
        buf.write(body.substring(5, body.length.clamp(0, 7)));
      }
      if (body.length > 7) {
        buf.write('-');
        buf.write(body.substring(7));
      }
    }

    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Formatdagi matnni serverga yuboriladigan formatga o'giradi: +998901234567
  static String toRaw(String formatted) {
    final digits = formatted.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('998')) return '+$digits';
    return '+998$digits';
  }
}
