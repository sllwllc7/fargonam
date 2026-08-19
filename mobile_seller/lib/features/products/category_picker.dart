import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fargonam_ui/fargonam_ui.dart';
import 'products_providers.dart';

/// Kategoriya tanlash bottom sheet'ini ochadi. Tanlangan (yoki shu yerdan
/// yangi yaratilgan) kategoriyani qaytaradi, bekor qilinsa `null`.
Future<Category?> showCategoryPicker(
  BuildContext context,
  WidgetRef ref, {
  int? selectedId,
}) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<Category>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CategoryPickerSheet(ref: ref, selectedId: selectedId),
  );
}

class _CategoryPickerSheet extends ConsumerWidget {
  const _CategoryPickerSheet({required this.ref, this.selectedId});
  final WidgetRef ref;
  final int? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: [
                    Text(
                      'Kategoriya',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              _CreateCategoryTile(
                ref: ref,
                onCreated: (c) => Navigator.pop(context, c),
              ),
              const Divider(height: 1, color: AppColors.border),
              Flexible(
                child: categoriesAsync.when(
                  data: (cats) => cats.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'Hali kategoriya yo\'q',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: cats.length,
                          itemBuilder: (context, i) {
                            final c = cats[i];
                            final selected = c.id == selectedId;
                            return ListTile(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.pop(context, c);
                              },
                              title: Text(
                                c.name,
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500),
                              ),
                              trailing: selected
                                  ? const Icon(Icons.check_circle,
                                      color: AppColors.sellerAccent)
                                  : null,
                            );
                          },
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.sellerAccent, strokeWidth: 2.5),
                    ),
                  ),
                  error: (e, _) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('Yuklab bo\'lmadi',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateCategoryTile extends StatelessWidget {
  const _CreateCategoryTile({required this.ref, required this.onCreated});
  final WidgetRef ref;
  final ValueChanged<Category> onCreated;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        final created = await _promptCreateCategory(context, ref);
        if (created != null) onCreated(created);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.sellerAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: AppColors.sellerAccent, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Yangi kategoriya qo\'shish',
              style: TextStyle(
                  color: AppColors.sellerAccent, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

Future<Category?> _promptCreateCategory(
    BuildContext context, WidgetRef ref) async {
  final ctrl = TextEditingController();
  try {
    return await showDialog<Category>(
      context: context,
      builder: (ctx) {
        String? error;
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Yangi kategoriya'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nomi',
                      hintText: 'Masalan: Ruchka',
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        error!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: const Text('Bekor'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = ctrl.text.trim();
                          if (name.isEmpty) {
                            setState(() => error = 'Nom kiriting');
                            return;
                          }
                          setState(() {
                            saving = true;
                            error = null;
                          });
                          try {
                            final cat =
                                await createCategory(ref, name: name);
                            HapticFeedback.lightImpact();
                            if (ctx.mounted) Navigator.pop(ctx, cat);
                          } on DioException catch (e) {
                            HapticFeedback.heavyImpact();
                            setState(() {
                              saving = false;
                              error =
                                  e.response?.data['detail']?.toString() ??
                                      'Xato';
                            });
                          } catch (e) {
                            HapticFeedback.heavyImpact();
                            setState(() {
                              saving = false;
                              error = e.toString();
                            });
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white),
                        )
                      : const Text('Yaratish'),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    ctrl.dispose();
  }
}
