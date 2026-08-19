import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/push_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/auth_providers.dart';

const _notifPrefKey = 'notifications_enabled';

/// Sozlamalar — HANDOFF.md 2-bo'lim, 17-band.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifEnabled = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notifEnabled = prefs.getBool(_notifPrefKey) ?? true;
        _loaded = true;
      });
    }
  }

  Future<void> _toggleNotif() async {
    HapticFeedback.selectionClick();
    final next = !_notifEnabled;
    setState(() => _notifEnabled = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifPrefKey, next);
    if (next) {
      await ref.read(pushServiceProvider).init();
    } else {
      await ref.read(pushServiceProvider).unregister();
    }
  }

  Future<void> _confirmLogout() async {
    HapticFeedback.lightImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('Chiqishni tasdiqlang'),
        content: Text('Hisobingizdan chiqmoqchimisiz?', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Yo\'q')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.maybePop(context);
                  },
                  child: Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                    child: Icon(Icons.arrow_back_ios_new, size: 15.sp, color: AppColors.text),
                  ),
                ),
                SizedBox(width: 12.w),
                Text('Sozlamalar', style: AppTextStyles.h2.copyWith(fontSize: 23)),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  _Row(label: 'Til', trailing: Text('O\'zbek', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13.5, color: AppColors.textMuted))),
                  const Divider(height: 1, color: AppColors.border),
                  InkWell(
                    onTap: _loaded ? _toggleNotif : null,
                    child: _Row(
                      label: 'Bildirishnomalar',
                      trailing: _Switch(value: _notifEnabled),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _Row(
                    label: 'Tungi rejim',
                    opacity: 0.55,
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                      decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(7.r)),
                      child: Text('Tez orada', style: AppTextStyles.small.copyWith(fontSize: 11, color: AppColors.textMuted)),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _Row(
                    label: 'Ilova haqida',
                    trailing: FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snap) => Text('v${snap.data?.version ?? '1.0'}', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13.5, color: AppColors.textMuted)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                onTap: _confirmLogout,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  child: Center(child: Text('Chiqish', style: AppTextStyles.cardTitleSm.copyWith(color: AppColors.danger, fontSize: 15))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.trailing, this.opacity = 1});
  final String label;
  final Widget trailing;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.cardTitleSm.copyWith(fontSize: 15))),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 46.w,
      height: 28.h,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(color: value ? AppColors.text : const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(14.r)),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 22.w,
        height: 22.w,
        decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 3)]),
      ),
    );
  }
}
