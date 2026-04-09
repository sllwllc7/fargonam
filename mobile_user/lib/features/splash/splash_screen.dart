import 'package:flutter/material.dart';
import '../../core/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.storefront_rounded, size: 56, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Fargonam',
              style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1),
            ),
            const SizedBox(height: 6),
            Text(
              'Farg\'ona vodiysi super-app',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
