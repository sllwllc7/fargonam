import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_update_service.dart';

/// Pastdan chiqadigan yangilanish paneli — yangi versiya bo'lganda ko'rsatiladi.
/// `force=true` bo'lsa "Keyinroq" tugmasi yo'q va sheet yopilmaydi.
void showAppUpdateSheet(BuildContext context, AppUpdateInfo info) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: !info.force,
    enableDrag: !info.force,
    backgroundColor: Colors.transparent,
    builder: (ctx) => PopScope(
      canPop: !info.force,
      child: _AppUpdateSheetContent(info: info),
    ),
  );
}

class _AppUpdateSheetContent extends StatelessWidget {
  const _AppUpdateSheetContent({required this.info});
  final AppUpdateInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!info.force)
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(2))),
              ),
            const SizedBox(height: 20),
            Text('Yangi versiya: ${info.version}', style: AppTypography.h1),
            if (info.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(info.notes, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => launchUrl(Uri.parse(info.apkUrl), mode: LaunchMode.externalApplication),
                child: Text('Yuklab olish', style: AppTypography.button),
              ),
            ),
            if (!info.force) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text('Keyinroq'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
