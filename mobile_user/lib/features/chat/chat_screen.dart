import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets.dart';
import '../../core/ws_service.dart';

/// Dastlabki xabarlarni HTTP orqali yuklash
final chatMessagesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>(
        (ref, userId) async {
  final res =
      await ref.watch(dioProvider).get('/chat/messages/$userId');
  return (res.data as List).cast<Map<String, dynamic>>();
});

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen(
      {super.key, required this.userId, required this.userName});
  final int userId;
  final String userName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // Barcha xabarlar (HTTP yuklangan + WS orqali kelgan)
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String? _error;
  bool _sending = false;

  // Yozyapti indikatori
  bool _otherTyping = false;
  Timer? _typingClearTimer;
  Timer? _typingSendTimer;

  ChatWsService? _ws;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1) Dastlabki xabarlarni HTTP orqali olish
    try {
      final res = await ref
          .read(dioProvider)
          .get('/chat/messages/${widget.userId}');
      if (!mounted) return;
      setState(() {
        _messages.addAll(
            (res.data as List).cast<Map<String, dynamic>>());
        _loading = false;
      });
      _scrollToBottom(animated: false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
      return;
    }

    // 2) WebSocket'ga ulanish
    _ws = ChatWsService(
      onMessage: _handleIncomingMessage,
      onTyping: _handleTyping,
    );
    await _ws!.connect(ref.read(secureStorageProvider));
  }

  void _handleIncomingMessage(ChatMessage msg) {
    // Faqat shu suhbatga tegishli xabarlarni qabul qilish
    final isForThisChat = (msg.isMine && msg.receiverId == widget.userId) ||
        (!msg.isMine && msg.senderId == widget.userId);
    if (!isForThisChat) return;
    if (!mounted) return;

    // Duplicate check — server echo back qilganda
    if (_messages.any((m) => m['id'] == msg.id)) return;

    setState(() {
      _messages.add({
        'id': msg.id,
        'sender_id': msg.senderId,
        'text': msg.text,
        'is_mine': msg.isMine,
        'is_read': false,
        'created_at': msg.createdAt,
      });
      // Xabar kelganda typing indikatori o'chadi
      if (!msg.isMine) _otherTyping = false;
    });
    _scrollToBottom();
    if (!msg.isMine) HapticFeedback.selectionClick();
  }

  void _handleTyping(int senderId) {
    if (senderId != widget.userId) return;
    if (!mounted) return;
    setState(() => _otherTyping = true);
    _typingClearTimer?.cancel();
    _typingClearTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _otherTyping = false);
    });
  }

  @override
  void dispose() {
    _typingClearTimer?.cancel();
    _typingSendTimer?.cancel();
    _ws?.disconnect();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onInputChanged(String _) {
    // Yozayotganimizni aks qilishi — 1 sekundda bir marta yuborish
    _typingSendTimer?.cancel();
    _typingSendTimer = Timer(const Duration(milliseconds: 500), () {
      _ws?.sendTyping(receiverId: widget.userId);
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    HapticFeedback.lightImpact();

    // WebSocket orqali yuborish (darhol)
    if (_ws != null) {
      setState(() => _sending = true);
      _ws!.sendMessage(receiverId: widget.userId, text: text);
      _msgCtrl.clear();
      // Server javobi tezda keladi va _handleIncomingMessage chaqiriladi
      // Agar 3 sekund ichida kelmasa — HTTP fallback
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _sending = false);
      });
      // Bu yerda hozir qoldirib qo'yamiz — UI darhol xabarni qo'shmaydi
      // chunki server WS echo'si bilan qo'shadi. Bu duplicate'ning oldini oladi.
      setState(() => _sending = false);
      return;
    }

    // Fallback: HTTP POST (WS yo'q bo'lsa)
    setState(() => _sending = true);
    try {
      await ref.read(dioProvider).post('/chat/send', data: {
        'receiver_id': widget.userId,
        'text': text,
      });
      _msgCtrl.clear();
      // HTTP fallback — qayta yuklash
      final res = await ref
          .read(dioProvider)
          .get('/chat/messages/${widget.userId}');
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll((res.data as List).cast<Map<String, dynamic>>());
      });
      _scrollToBottom();
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                e.response?.data['detail']?.toString() ?? 'Xato'),
            backgroundColor: AppColors.error,
            duration: const Duration(milliseconds: 1600),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollCtrl.hasClients) return;
      if (animated) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.userName.isNotEmpty
                      ? widget.userName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _ws != null
                              ? AppColors.success
                              : AppColors.textSecondary.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _otherTyping
                            ? 'yozyapti...'
                            : (_ws != null ? 'Onlayn' : 'Ulanmoqda...'),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Xabarlar ro'yxati
          Expanded(
            child: _loading
                ? const _ChatSkeleton()
                : _error != null
                    ? ErrorRetryWidget(
                        error: _error!,
                        onRetry: () {
                          setState(() {
                            _error = null;
                            _loading = true;
                            _messages.clear();
                          });
                          _init();
                        },
                      )
                    : _messages.isEmpty
                        ? const _EmptyChatState()
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding:
                                const EdgeInsets.fromLTRB(12, 16, 12, 8),
                            itemCount: _messages.length,
                            itemBuilder: (context, i) {
                              final m = _messages[i];
                              final isMine = m['is_mine'] == true;
                              final time = _formatTime(
                                  m['created_at'] as String);
                              return _MessageBubble(
                                key: ValueKey(m['id']),
                                text: m['text'] as String,
                                time: time,
                                isMine: isMine,
                                isRead: m['is_read'] == true,
                              );
                            },
                          ),
          ),

          // ── Xabar yozish paneli ──
          Container(
            padding: EdgeInsets.fromLTRB(12, 10, 8,
                MediaQuery.of(context).padding.bottom + 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                    color: AppColors.border, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    onChanged: _onInputChanged,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Xabar yozing...',
                      hintStyle: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceAlt,
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
                  onTap: _sending ? null : _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: _sending
                          ? null
                          : LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withValues(alpha: 0.7)
                              ],
                            ),
                      color: _sending ? AppColors.surfaceAlt : null,
                      shape: BoxShape.circle,
                      boxShadow: _sending
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(13),
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary),
                          )
                        : const Icon(Icons.send,
                            color: AppColors.primary,
                            size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isMine,
    required this.isRead,
  });
  final String text;
  final String time;
  final bool isMine;
  final bool isRead;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280))
      ..forward();
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _fade,
        child: Align(
          alignment: widget.isMine
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
                maxWidth:
                    MediaQuery.of(context).size.width * 0.78),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: BoxDecoration(
              color: widget.isMine
                  ? AppColors.primary
                  : AppColors.surfaceAlt,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(widget.isMine ? 20 : 4),
                bottomRight: Radius.circular(widget.isMine ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: widget.isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: widget.isMine
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.time,
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isMine
                            ? AppColors.primary
                                .withValues(alpha: 0.5)
                            : AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                    if (widget.isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        widget.isRead
                            ? Icons.done_all
                            : Icons.done,
                        size: 14,
                        color: widget.isRead
                            ? AppColors.primary
                            : AppColors.primary
                                .withValues(alpha: 0.5),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.waving_hand,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Salom deng!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Birinchi xabarni yozib suhbatni boshlang',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        for (int i = 0; i < 6; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment:
                  i.isEven ? Alignment.centerLeft : Alignment.centerRight,
              child: ShimmerBox(
                width: 180.0 + (i * 20).toDouble() % 80,
                height: 40,
                borderRadius: 18,
              ),
            ),
          ),
      ],
    );
  }
}
