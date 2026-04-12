import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import 'auth_providers.dart';
import 'phone_formatter.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    final cleanPhone = PhoneFormatter.toRaw(_phoneCtrl.text);
    await ref
        .read(authControllerProvider.notifier)
        .login(cleanPhone, _passCtrl.text);
    if (ref.read(authControllerProvider).error != null) {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.cream, AppColors.creamDim],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.cream.withValues(alpha: 0.3),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          size: 42, color: AppColors.midnightIndigo),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Xush kelibsiz!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Fargonam hisobingizga kiring',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 36),

                  // Telefon
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Telefon raqam',
                      hintText: '+998 (90) 123-45-67',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneFormatter()],
                    validator: (v) {
                      final raw = PhoneFormatter.toRaw(v ?? '');
                      if (raw.length < 10) {
                        return 'To\'liq raqam kiriting';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Parol
                  TextFormField(
                    controller: _passCtrl,
                    decoration: InputDecoration(
                      labelText: 'Parol',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _obscure = !_obscure);
                        },
                      ),
                    ),
                    obscureText: _obscure,
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Kamida 6 belgi' : null,
                  ),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _showForgotPasswordDialog(context, ref,
                            initialPhone: _phoneCtrl.text);
                      },
                      style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8)),
                      child: const Text(
                        'Parolni unutdingizmi?',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  // Error
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: state.error == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.errorSoft,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.error
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: AppColors.error, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(state.error!,
                                        style: const TextStyle(
                                            color: AppColors.error,
                                            fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Kirish tugmasi
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: state.loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      child: state.loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.midnightIndigo),
                            )
                          : const Text(
                              'Kirish',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Hisobingiz yo\'qmi?',
                          style: TextStyle(
                              color: AppColors.textSecondary)),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, _, _) =>
                                  const RegisterScreen(),
                              transitionsBuilder:
                                  (_, anim, _, child) => SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                    parent: anim,
                                    curve: Curves.easeOutCubic)),
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Ro\'yxatdan o\'ting',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.cream),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Parolni unutgan foydalanuvchilar uchun dialog — telefon raqam so'raydi,
/// backend'ga yuboradi va tasdiqlov xabarini ko'rsatadi.
void _showForgotPasswordDialog(
  BuildContext context,
  WidgetRef ref, {
  String initialPhone = '',
}) {
  final phoneCtrl = TextEditingController(text: initialPhone);
  showDialog<void>(
    context: context,
    builder: (dialogCtx) {
      bool loading = false;
      String? error;
      String? success;

      return StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_reset,
                    color: AppColors.cream, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Parolni tiklash',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (success != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          success!,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Text(
                  'Telefon raqamingizni kiriting, qo\'llab-quvvatlash xizmati siz bilan bog\'lanadi:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneFormatter()],
                  decoration: const InputDecoration(
                    hintText: '+998 (90) 123-45-67',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    error!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12),
                  ),
                ],
              ],
            ],
          ),
          actions: [
            if (success != null)
              FilledButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Yopish'),
              )
            else ...[
              TextButton(
                onPressed:
                    loading ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Bekor qilish'),
              ),
              FilledButton(
                onPressed: loading
                    ? null
                    : () async {
                        final raw = PhoneFormatter.toRaw(phoneCtrl.text);
                        if (raw.length < 10) {
                          setDialogState(
                              () => error = 'To\'liq raqam kiriting');
                          return;
                        }
                        HapticFeedback.lightImpact();
                        setDialogState(() {
                          loading = true;
                          error = null;
                        });
                        try {
                          final res = await ref
                              .read(dioProvider)
                              .post('/auth/forgot-password',
                                  data: {'phone': raw});
                          setDialogState(() {
                            loading = false;
                            success = res.data['message']?.toString() ??
                                'So\'rov yuborildi';
                          });
                        } on DioException catch (e) {
                          setDialogState(() {
                            loading = false;
                            error = e.response?.data['detail']
                                    ?.toString() ??
                                'Tarmoq xatosi';
                          });
                        }
                      },
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.midnightIndigo),
                      )
                    : const Text('Yuborish'),
              ),
            ],
          ],
        ),
      );
    },
  );
}
