import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import 'auth_providers.dart';
import 'phone_formatter.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _termsAccepted = false;
  bool _termsError = false;
  double _passwordStrength = 0;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  double _calcStrength(String pass) {
    if (pass.isEmpty) return 0;
    double score = 0;
    if (pass.length >= 6) score += 0.2;
    if (pass.length >= 8) score += 0.15;
    if (pass.length >= 12) score += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(pass)) score += 0.15;
    if (RegExp(r'[a-z]').hasMatch(pass)) score += 0.1;
    if (RegExp(r'[0-9]').hasMatch(pass)) score += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pass)) score += 0.1;
    return score.clamp(0.0, 1.0);
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    final formOk = _formKey.currentState!.validate();
    setState(() => _termsError = !_termsAccepted);
    if (!formOk || !_termsAccepted) {
      HapticFeedback.heavyImpact();
      return;
    }
    final cleanPhone = PhoneFormatter.toRaw(_phoneCtrl.text);
    await ref.read(authControllerProvider.notifier).register(
          cleanPhone,
          _passCtrl.text,
          _nameCtrl.text.trim(),
        );
    final state = ref.read(authControllerProvider);
    if (state.user != null && mounted) {
      HapticFeedback.lightImpact();
      Navigator.pop(context);
    } else if (state.error != null) {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Yangi hisob',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Fargonam\'ga qo\'shiling',
                style: TextStyle(
                    fontSize: 15, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ismingiz',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().length < 2) {
                    return 'Kamida 2 belgi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
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
                  if (raw.length < 10) return 'To\'liq raqam kiriting';
                  return null;
                },
              ),
              const SizedBox(height: 14),
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
                onChanged: (v) =>
                    setState(() => _passwordStrength = _calcStrength(v)),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Kamida 6 belgi' : null,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                child: _passCtrl.text.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(
                                      begin: 0, end: _passwordStrength),
                                  duration:
                                      const Duration(milliseconds: 300),
                                  builder: (_, value, _) =>
                                      LinearProgressIndicator(
                                    value: value,
                                    backgroundColor:
                                        AppColors.surfaceHigh,
                                    color: _passwordStrength < 0.4
                                        ? AppColors.error
                                        : _passwordStrength < 0.7
                                            ? AppColors.warning
                                            : AppColors.success,
                                    minHeight: 5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _passwordStrength < 0.4
                                  ? 'Zaif'
                                  : _passwordStrength < 0.7
                                      ? 'O\'rtacha'
                                      : 'Kuchli',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _passwordStrength < 0.4
                                    ? AppColors.error
                                    : _passwordStrength < 0.7
                                        ? AppColors.warning
                                        : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              // Terms checkbox
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _termsAccepted = !_termsAccepted;
                    if (_termsAccepted) _termsError = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _termsError
                        ? AppColors.errorSoft
                        : AppColors.surfaceHigh.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _termsError
                          ? AppColors.error.withValues(alpha: 0.5)
                          : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _termsAccepted
                              ? AppColors.cream
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _termsAccepted
                                ? AppColors.cream
                                : AppColors.textMuted,
                            width: 2,
                          ),
                        ),
                        child: _termsAccepted
                            ? const Icon(Icons.check,
                                size: 16,
                                color: AppColors.midnightIndigo)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(text: 'Men '),
                              TextSpan(
                                text: 'foydalanish shartlari',
                                style: TextStyle(
                                  color: AppColors.cream
                                      .withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(
                                  text: ' va maxfiylik siyosatini qabul qilaman'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                child: state.error == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 14),
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
              const SizedBox(height: 24),

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
                          'Ro\'yxatdan o\'tish',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
