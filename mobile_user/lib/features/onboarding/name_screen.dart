import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/user_name_provider.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_input.dart';

/// Ism so'rash ekrani — ilova birinchi marta ochilganda (auth'dan keyin,
/// hali ismi saqlanmagan bo'lsa) va Profil'dan "ismni tahrirlash" orqali.
/// Prototipda (dc.html) bu qadam yo'q — foydalanuvchi so'rovi bilan
/// qo'shildi (PROGRESS.md → Qarorlar).
class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key, required this.onDone, this.initialName});

  /// Saqlangandan keyin chaqiriladi.
  final VoidCallback onDone;

  /// Profil'dan tahrirlash uchun — mavjud ism oldindan to'ldiriladi.
  final String? initialName;

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  late final _ctrl = TextEditingController(text: widget.initialName ?? '');
  bool _canContinue = false;

  @override
  void initState() {
    super.initState();
    _canContinue = _ctrl.text.trim().isNotEmpty;
    _ctrl.addListener(() {
      final can = _ctrl.text.trim().isNotEmpty;
      if (can != _canContinue) setState(() => _canContinue = can);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    await ref.read(userNameProvider.notifier).save(_ctrl.text);
    if (!mounted) return;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialName != null;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isEdit)
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  color: AppColors.text,
                ),
              SizedBox(height: isEdit ? 8.h : 60.h),
              Text('Tanishib olaylik', style: AppTextStyles.h1),
              SizedBox(height: 8.h),
              Text(
                'Sizga qanday murojaat qilishimizni bilishni xohlaymiz',
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              ),
              SizedBox(height: 32.h),
              AppInput(
                label: 'Ismingiz',
                hint: 'Masalan: Aziz',
                controller: _ctrl,
                keyboardType: TextInputType.name,
                onChanged: (_) {},
              ),
              const Spacer(),
              AppButton(
                label: 'Davom etish',
                onPressed: _canContinue ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
