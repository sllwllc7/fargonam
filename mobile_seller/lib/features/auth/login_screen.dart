import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import 'auth_providers.dart';
import 'phone_formatter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  // 0 = telefon, 1 = OTP
  int _step = 0;
  bool _isNewUser = false;
  String _role = 'seller'; // yangi foydalanuvchi uchun rol tanlovi

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    HapticFeedback.mediumImpact();
    final raw = PhoneFormatter.toRaw(_phoneCtrl.text);
    if (raw.length < 10) return;

    final isNew = await ref.read(authControllerProvider.notifier).sendOtp(raw);
    if (isNew == null) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() {
      _isNewUser = isNew;
      _step = 1;
    });
  }

  Future<void> _verifyOtp() async {
    HapticFeedback.mediumImpact();
    if (_otpCtrl.text.length != 4) return;

    final raw = PhoneFormatter.toRaw(_phoneCtrl.text);
    await ref.read(authControllerProvider.notifier).verifyOtp(
          raw,
          _otpCtrl.text,
          fullName: _isNewUser ? _nameCtrl.text.trim() : null,
          role: _isNewUser ? _role : 'seller',
        );
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: _step == 0
                  ? _PhoneStep(
                      key: const ValueKey('phone'),
                      ctrl: _phoneCtrl,
                      loading: state.loading,
                      error: state.error,
                      onSubmit: _sendOtp,
                    )
                  : _OtpStep(
                      key: const ValueKey('otp'),
                      phone: _phoneCtrl.text,
                      otpCtrl: _otpCtrl,
                      nameCtrl: _nameCtrl,
                      isNewUser: _isNewUser,
                      role: _role,
                      loading: state.loading,
                      error: state.error,
                      onSubmit: _verifyOtp,
                      onRoleChanged: (r) => setState(() => _role = r),
                      onBack: () => setState(() {
                        _step = 0;
                        _otpCtrl.clear();
                      }),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Telefon bosqichi ───────────────────────────────────────────

class _PhoneStep extends StatelessWidget {
  final TextEditingController ctrl;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  const _PhoneStep({
    super.key,
    required this.ctrl,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.cream, AppColors.creamDim],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cream.withValues(alpha: 0.3),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.business_center,
                size: 42, color: AppColors.midnightIndigo),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Fargonam Biznes',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Telefon raqamingizni kiriting',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 36),
        TextFormField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Telefon raqam',
            hintText: '+998 (90) 123-45-67',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneFormatter()],
          onFieldSubmitted: (_) => onSubmit(),
        ),
        _ErrorBox(error: error),
        const SizedBox(height: 20),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: loading ? null : onSubmit,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.midnightIndigo),
                  )
                : const Text('Kod yuborish',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── OTP bosqichi ───────────────────────────────────────────────

class _OtpStep extends StatelessWidget {
  final String phone;
  final TextEditingController otpCtrl;
  final TextEditingController nameCtrl;
  final bool isNewUser;
  final String role;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onBack;

  const _OtpStep({
    super.key,
    required this.phone,
    required this.otpCtrl,
    required this.nameCtrl,
    required this.isNewUser,
    required this.role,
    required this.loading,
    required this.error,
    required this.onSubmit,
    required this.onRoleChanged,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.cream, AppColors.creamDim],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cream.withValues(alpha: 0.3),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.sms_outlined,
                size: 42, color: AppColors.midnightIndigo),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Kodni kiriting',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$phone raqamiga yuborilgan 4 xonali kodni kiriting',
          textAlign: TextAlign.center,
          style:
              const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        if (isNewUser) ...[
          // Ism
          TextFormField(
            controller: nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'To\'liq ismingiz',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
            onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 14),
          // Rol tanlovi
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.cream.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                _RoleTile(
                  value: 'seller',
                  groupValue: role,
                  icon: Icons.storefront_outlined,
                  title: 'Sotuvchi',
                  subtitle: 'Do\'kon ochib mahsulot sotish',
                  onChanged: onRoleChanged,
                ),
                Divider(
                    height: 1,
                    color: AppColors.cream.withValues(alpha: 0.1)),
                _RoleTile(
                  value: 'driver',
                  groupValue: role,
                  icon: Icons.local_taxi_outlined,
                  title: 'Haydovchi',
                  subtitle: 'Yuk va yo\'lovchi tashish',
                  onChanged: onRoleChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        TextFormField(
          controller: otpCtrl,
          autofocus: !isNewUser,
          decoration: const InputDecoration(
            labelText: 'SMS kod',
            hintText: '• • • •',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
          ),
          textAlign: TextAlign.center,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
              null,
          onFieldSubmitted: (_) => onSubmit(),
        ),
        _ErrorBox(error: error),
        const SizedBox(height: 20),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: loading ? null : onSubmit,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.midnightIndigo),
                  )
                : const Text('Tasdiqlash',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: loading ? null : onBack,
          child: const Text(
            'Raqamni o\'zgartirish',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String value;
  final String groupValue;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<String> onChanged;

  const _RoleTile({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.cream.withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 22,
                  color: selected
                      ? AppColors.cream
                      : AppColors.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      )),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.cream : AppColors.textSecondary,
                  width: 2,
                ),
                color: selected
                    ? AppColors.cream
                    : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: AppColors.midnightIndigo)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Xato widget ────────────────────────────────────────────────

class _ErrorBox extends StatelessWidget {
  final String? error;
  const _ErrorBox({required this.error});

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(error!,
                  style: const TextStyle(
                      color: AppColors.error, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
