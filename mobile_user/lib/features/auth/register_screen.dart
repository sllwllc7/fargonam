// Ro'yxatdan o'tish endi login ekraniga birlashtirildi (OTP flow).
// Bu fayl backwards compatibility uchun saqlanadi.
import 'package:flutter/material.dart';
import 'login_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}
