import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/push_service.dart';
import '../auth/auth_providers.dart';

const _notifPrefKey = 'notifications_enabled';

const _chevronIconSvg =
    '<svg viewBox="0 0 8 14"><path d="m1 1 6 6-6 6" stroke="#1C1C22" stroke-width="2" stroke-linecap="round" fill="none"/></svg>';

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
        content: Text('Hisobingizdan chiqmoqchimisiz?', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ScreenFadeIn(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  BackCircleButton(onTap: () => Navigator.maybePop(context)),
                  const SizedBox(width: 12),
                  Text('Sozlamalar', style: AppTypography.h2),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _Row(
                      label: 'Til',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('O\'zbek', style: AppTypography.cardTitleSm.copyWith(fontSize: 13.5, color: AppColors.textMuted)),
                          const SizedBox(width: 8),
                          SvgPicture.string(_chevronIconSvg, width: 8, height: 14),
                        ],
                      ),
                    ),
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
                      opacity: 0.6,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(7)),
                        child: Text('Tez orada', style: AppTypography.small.copyWith(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textMuted)),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _Row(
                      label: 'Ilova haqida',
                      trailing: FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snap) => Text('v${snap.data?.version ?? '1.0'}', style: AppTypography.cardTitleSm.copyWith(fontSize: 13.5, color: AppColors.textMuted)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  onTap: _confirmLogout,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(child: Text('Chiqish', style: AppTypography.rowTitle.copyWith(color: AppColors.textMuted, fontSize: 15))),
                  ),
                ),
              ),
            ],
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTypography.cardTitleSm.copyWith(fontSize: 15))),
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
      width: 46,
      height: 28,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: value ? AppColors.primaryDeep : AppColors.border, borderRadius: BorderRadius.circular(14)),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 3)]),
      ),
    );
  }
}
