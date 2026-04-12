import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';

/// Fargonam AI assistent — oddiy qoida asosida ishlovchi chatbot.
/// Kelajakda Claude/OpenAI API bilan yaxshilanadi.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Message> _messages = [];
  bool _typing = false;

  @override
  void initState() {
    super.initState();
    // Xush kelibsiz xabari
    _messages.add(_Message(
      text: 'Salom! Men Fargonam AI yordamchisiman. '
          'Sizga marketplace, taxi, buyurtmalar haqida yordam bera olaman.\n\n'
          'Qanday yordam kerak?',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _typing) return;
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _ctrl.clear();
      _typing = true;
    });
    _scrollToBottom();

    // Qoida asosidagi javob (100-500ms kechikish bilan tabiiy ko'rinadi)
    await Future.delayed(
        Duration(milliseconds: 400 + Random().nextInt(700)));
    final reply = _generateReply(text);
    if (!mounted) return;
    setState(() {
      _messages.add(_Message(text: reply, isUser: false));
      _typing = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Oddiy kalit so'z asosidagi javob — keyinroq LLM bilan almashtiriladi
  String _generateReply(String input) {
    final q = input.toLowerCase();

    // Taxi
    if (q.contains('taksi') ||
        q.contains('taxi') ||
        q.contains('mashina')) {
      return 'Taxi chaqirish uchun pastdagi "Taxi" tabini bosing. '
          'Keyin manzilni kiriting yoki xaritada tanlang. '
          'Narx avtomatik hisoblanadi.';
    }

    // Buyurtma
    if (q.contains('buyurtma') || q.contains('order')) {
      return 'Buyurtma berish uchun: Marketplace\'dan mahsulotni tanlang → '
          'savatga qo\'shing → "Buyurtma berish" tugmasini bosing. '
          'Buyurtmalar tarixini Profil > Buyurtmalarim bo\'limida ko\'rishingiz mumkin.';
    }

    // Do'kon / marketplace
    if (q.contains('do\'kon') ||
        q.contains('dokon') ||
        q.contains('marketplace') ||
        q.contains('mahsulot')) {
      return 'Marketplace tabida Farg\'ona vodiysining barcha do\'konlari bor. '
          'Qidiruvdan foydalaning yoki kategoriya tanlang. '
          'Yoqqan mahsulotni ❤ tugmasi bilan sevimlilarga qo\'shing.';
    }

    // Parol
    if (q.contains('parol') || q.contains('login')) {
      return 'Parolni Profil > "Parolni o\'zgartirish" bo\'limidan yangilashingiz mumkin. '
          'Agar parolni unutgan bo\'lsangiz, qo\'llab-quvvatlash xizmatiga murojaat qiling.';
    }

    // Yetkazib berish
    if (q.contains('yetkaz') || q.contains('delivery')) {
      return 'Yetkazib berish narxi va vaqti do\'konga bog\'liq. '
          'Buyurtma berishdan oldin aniq narx va vaqt ko\'rsatiladi. '
          'Yetkazib berish manzilini Profil > Manzillarim bo\'limida saqlab qo\'ying.';
    }

    // Sevimlilar
    if (q.contains('sevimli') || q.contains('favorite') || q.contains('yoqqan')) {
      return 'Mahsulot ustidagi ❤ tugmasini bosing — u sevimlilaringizga qo\'shiladi. '
          'Sevimlilaringizni Profil > Sevimlilar bo\'limida ko\'rishingiz mumkin.';
    }

    // Salomlashuv
    if (q.contains('salom') || q.contains('hey') || q.contains('hi')) {
      return 'Va alaykum assalom! Sizga qanday yordam berishim mumkin?';
    }

    // Rahmat
    if (q.contains('rahmat') || q.contains('tashakkur') || q.contains('thanks')) {
      return 'Sog\' bo\'ling! Yana savolingiz bo\'lsa, men shu yerdaman.';
    }

    // Default
    return 'Men hozir oddiy yordamchiman va barcha savollarga javob bera olmayman. '
        'Lekin quyidagi mavzularda yordam bera olaman:\n\n'
        '• 🛒 Marketplace va mahsulotlar\n'
        '• 🚖 Taxi va sayohatlar\n'
        '• 📦 Buyurtmalar\n'
        '• ❤️ Sevimlilar\n'
        '• 🔐 Parol va hisob\n'
        '• 📍 Manzillar\n\n'
        'Shulardan biri haqida so\'rang!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.cream, AppColors.creamDim],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cream.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome,
                  color: AppColors.midnightIndigo, size: 22),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Fargonam AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Yordamchi',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Xabarlar
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length && _typing) {
                  return const _TypingBubble();
                }
                return _MessageBubble(message: _messages[i]);
              },
            ),
          ),
          // Tez so'rov chiplar (birinchi xabarda ko'rinadi)
          if (_messages.length <= 1)
            Container(
              height: 44,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _QuickChip(
                    label: '🛒 Marketplace',
                    onTap: () {
                      _ctrl.text = 'Marketplace qanday ishlaydi?';
                      _send();
                    },
                  ),
                  _QuickChip(
                    label: '🚖 Taxi',
                    onTap: () {
                      _ctrl.text = 'Taxi qanday chaqiraman?';
                      _send();
                    },
                  ),
                  _QuickChip(
                    label: '📦 Buyurtmalar',
                    onTap: () {
                      _ctrl.text = 'Buyurtma qanday beriladi?';
                      _send();
                    },
                  ),
                  _QuickChip(
                    label: '📍 Manzil',
                    onTap: () {
                      _ctrl.text = 'Manzillarimni qanday saqlayman?';
                      _send();
                    },
                  ),
                ],
              ),
            ),
          // Input
          Container(
            padding: EdgeInsets.fromLTRB(
                12, 10, 8, MediaQuery.of(context).padding.bottom + 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.divider, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Savolingizni yozing...',
                      hintStyle:
                          const TextStyle(color: AppColors.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceHigh,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    maxLines: 4,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.cream, AppColors.creamDim],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cream.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send,
                        color: AppColors.midnightIndigo, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;
  _Message({required this.text, required this.isUser});
}

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({required this.message});
  final _Message message;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280))
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    return FadeTransition(
      opacity: _ctrl,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(isUser ? 0.2 : -0.2, 0),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic)),
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? AppColors.cream : AppColors.surfaceHigh,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.message.text,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: isUser
                    ? AppColors.midnightIndigo
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = (_ctrl.value + i * 0.3) % 1.0;
                final opacity = (sin(phase * pi * 2) + 1) / 2;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.cream
                          .withValues(alpha: 0.3 + opacity * 0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.cream.withValues(alpha: 0.2)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.cream,
            ),
          ),
        ),
      ),
    );
  }
}
