import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';

final _newsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/news', queryParameters: {'limit': 20});
  return (res.data['items'] as List).cast<Map<String, dynamic>>();
});

/// Sotuvchi yangilik/e'lon joylashi — HANDOFF.md 4-bo'lim, 6-band.
class SellerNewsScreen extends ConsumerStatefulWidget {
  const SellerNewsScreen({super.key});

  @override
  ConsumerState<SellerNewsScreen> createState() => _SellerNewsScreenState();
}

class _SellerNewsScreenState extends ConsumerState<SellerNewsScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  XFile? _image;
  bool _posting = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _image = img);
  }

  Future<void> _post() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Sarlavha va matn kerak');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _posting = true;
      _error = null;
    });
    try {
      String? imageUrl;
      if (_image != null) {
        final dio = ref.read(dioProvider);
        final form = FormData.fromMap({'file': await MultipartFile.fromFile(_image!.path)});
        final res = await dio.post('/news/image', data: form);
        imageUrl = res.data['image_url'] as String?;
      }
      await ref.read(dioProvider).post('/news', data: {
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'image_url': ?imageUrl,
      });
      HapticFeedback.lightImpact();
      _titleCtrl.clear();
      _bodyCtrl.clear();
      setState(() => _image = null);
      ref.invalidate(_newsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E\'lon joylandi'), backgroundColor: AppColors.success),
        );
      }
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _error = e.response?.data['detail']?.toString() ?? 'Xato');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(_newsListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ScreenFadeIn(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    BackCircleButton(onTap: () => Navigator.maybePop(context)),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Yangiliklar', style: AppTypography.title)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Yangi e\'lon', style: AppTypography.cardTitleSm),
                          const SizedBox(height: 10),
                          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Sarlavha')),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _bodyCtrl,
                            decoration: const InputDecoration(labelText: 'Matn'),
                            maxLines: 4,
                          ),
                          const SizedBox(height: 10),
                          PressableScale(
                            onTap: _pickImage,
                            child: Container(
                              height: 90,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(AppRadius.input),
                              ),
                              child: _image != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(AppRadius.input),
                                      child: Image.file(File(_image!.path), fit: BoxFit.cover, width: double.infinity),
                                    )
                                  : Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.image_outlined, size: 18, color: AppColors.textMuted),
                                          const SizedBox(width: 6),
                                          Text('Rasm qo\'shish (ixtiyoriy)', style: AppTypography.caption),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.danger)),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed: _posting ? null : _post,
                              child: _posting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.ctaText),
                                    )
                                  : const Text('E\'lon qilish'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text('SO\'NGGI YANGILIKLAR', style: AppTypography.sectionLabel),
                    const SizedBox(height: 10),
                    newsAsync.when(
                      loading: () => Column(
                        children: List.generate(
                          3,
                          (_) => const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: ShimmerBox(width: double.infinity, height: 60, borderRadius: AppRadius.card),
                          ),
                        ),
                      ),
                      error: (_, _) => Text('Yuklanmadi', style: AppTypography.caption),
                      data: (items) {
                        if (items.isEmpty) return Text('Hali yangilik yo\'q', style: AppTypography.caption);
                        return Column(
                          children: [
                            for (final (i, n) in items.indexed)
                              FadeUpItem(delay: AppMotion.staggerStep * i, child: _NewsTile(item: n)),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final imgUrl = item['image_url'] != null ? '${AppConfig.apiBaseUrl}${item['image_url']}' : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (imgUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(imgUrl, width: 44, height: 44, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] as String? ?? '', style: AppTypography.cardTitleSm.copyWith(fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item['body'] as String? ?? '', style: AppTypography.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
