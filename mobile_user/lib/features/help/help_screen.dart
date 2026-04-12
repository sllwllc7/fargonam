import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    (
      q: 'Buyurtma qanday beriladi?',
      a: 'Marketplace bo\'limidan mahsulotni tanlang, savatchaga qo\'shing va "Buyurtma berish" tugmasini bosing.',
    ),
    (
      q: 'Buyurtmani bekor qilsa bo\'ladimi?',
      a: 'Ha, buyurtma "Kutilmoqda" holatida bo\'lsa bekor qilish mumkin. Buyurtmalarim bo\'limiga kiring.',
    ),
    (
      q: 'Taksi qanday chaqiriladi?',
      a: 'Pastdagi "Taksi" tabini bosing, manzillarni kiriting va "Taksi chaqirish" tugmasini bosing.',
    ),
    (
      q: 'Parolni unutdim, nima qilaman?',
      a: 'Hozircha qo\'llab-quvvatlash xizmatiga murojaat qiling. Tez orada parolni tiklash funksiyasi qo\'shiladi.',
    ),
    (
      q: 'Do\'kon qanday ochiladi?',
      a: 'Fargonam Biznes ilovasini yuklab oling va sotuvchi sifatida ro\'yxatdan o\'ting.',
    ),
    (
      q: 'Yetkazib berish qancha turadi?',
      a: 'Yetkazib berish narxi buyurtma summasiga qarab farq qiladi. Buyurtma berishdan oldin aniq narx ko\'rsatiladi.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Yordam'),
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Aloqa kartochkasi ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.surface, AppColors.surfaceHigh],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.cream.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent,
                      size: 40, color: AppColors.cream),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Qo\'llab-quvvatlash',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Savolingiz bormi? Biz yordam beramiz!',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _launchUrl('tel:+998901234567');
                          },
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text(
                            'Qo\'ng\'iroq',
                            style: TextStyle(
                                fontWeight: FontWeight.w800),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _launchUrl(
                                'https://t.me/fargonam_support');
                          },
                          icon: const Icon(Icons.send, size: 18),
                          label: const Text(
                            'Telegram',
                            style: TextStyle(
                                fontWeight: FontWeight.w800),
                          ),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── FAQ ──
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 0, 12),
            child: Text(
              'KO\'P SO\'RALADIGAN SAVOLLAR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 1.5,
              ),
            ),
          ),
          for (final faq in _faqs)
            _FaqTile(question: faq.q, answer: faq.a),
          const SizedBox(height: 24),

          const Center(
            child: Text(
              'Fargonam v0.1.0',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppColors.cream,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: _expanded
                ? Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      widget.answer,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
