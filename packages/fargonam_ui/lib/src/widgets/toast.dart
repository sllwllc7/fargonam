import 'package:flutter/material.dart';

import '../app_motion.dart';

/// Toast — dc.html TOAST bo'limidan tasdiqlangan ko'rinish, lekin
/// `ScaffoldMessenger`/`SnackBar` orqali (floating, shaffof fon) —
/// qo'lda yozilgan `Overlay`+`Opacity` versiyasi bu loyihaning HarmonyOS
/// qurilmasida butun ekranni xiralashtirib yuborgani sabab olib
/// tashlandi (sababi aniqlanmadi, lekin SnackBar bunday muammo
/// ko'rsatmadi — xavfsizroq yo'l tanlandi). `ScaffoldMessenger` o'zi
/// navbatga qo'ymasin uchun har chaqiruvda avval joriy snackbar
/// tozalanadi (dc.html'dagi `clearTimeout(this._tt)` bilan bir xil
/// naqsh — bitta vaqtda faqat bitta toast).
void showAppToast(BuildContext context, String message, {VoidCallback? onCartTap}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: AppMotion.toastVisible,
      backgroundColor: const Color(0xF2171327),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      content: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const _CheckIcon(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          if (onCartTap != null)
            GestureDetector(
              onTap: () {
                messenger.hideCurrentSnackBar();
                onCartTap();
              },
              child: const Text(
                'Savat',
                style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    ),
  );
}

class _CheckIcon extends StatelessWidget {
  const _CheckIcon();
  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(11, 9), painter: _CheckPainter());
}

class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEEF1F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * 0.09, size.height * 0.5)
      ..lineTo(size.width * 0.41, size.height)
      ..lineTo(size.width, size.height * 0.1);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
