import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/cyber_colors.dart';
import '../../../../core/theme/cyber_typography.dart';
import '../../domain/entities/chat_message_entity.dart';

class ChatInputBar extends StatefulWidget {
  final ChatMessageEntity? replyTarget;
  final VoidCallback onCancelReply;
  final Function(String text, String? replyToId) onSendMessage;
  final Function(bool isTyping) onTyping;

  const ChatInputBar({
    super.key,
    this.replyTarget,
    required this.onCancelReply,
    required this.onSendMessage,
    required this.onTyping,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      widget.onTyping(true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        widget.onTyping(false);
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _typingTimer?.cancel();
    if (_isTyping) {
      _isTyping = false;
      widget.onTyping(false);
    }
    widget.onSendMessage(text, widget.replyTarget?.id);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CyberColors.panel,
        border: Border(
          top: BorderSide(color: CyberColors.borderSubtle),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply Target Bar
            if (widget.replyTarget != null) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: ShapeDecoration(
                  color: CyberColors.inputFill,
                  shape: BeveledRectangleBorder(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                      topRight: Radius.circular(2),
                      bottomLeft: Radius.circular(2),
                    ),
                    side: BorderSide(
                      color: CyberColors.katanaGold.withValues(alpha: 0.7),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 28,
                      decoration: BoxDecoration(
                        color: CyberColors.katanaGold,
                        borderRadius: BorderRadius.circular(1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: CyberColors.katanaGold,
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.reply,
                      size: 16,
                      color: CyberColors.katanaGold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ОТВЕТ: ${widget.replyTarget!.sender.cyberTag} (${widget.replyTarget!.sender.username})',
                            style: CyberTypography.monoSmall.copyWith(
                              color: CyberColors.katanaGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            widget.replyTarget!.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CyberTypography.bodySmall.copyWith(
                              color: CyberColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: widget.onCancelReply,
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.close, size: 16, color: CyberColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Input Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: ShapeDecoration(
                        color: CyberColors.inputFill,
                        shape: BeveledRectangleBorder(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                            topRight: Radius.circular(2),
                            bottomLeft: Radius.circular(2),
                          ),
                          side: BorderSide(
                            color: CyberColors.cyberCyan.withValues(alpha: 0.5),
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // 3px Glowing Accent Bar on Left Border
                          Positioned(
                            left: 0,
                            top: 4,
                            bottom: 4,
                            child: Container(
                              width: 3,
                              decoration: BoxDecoration(
                                color: CyberColors.cyberCyan,
                                borderRadius: BorderRadius.circular(1.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: CyberColors.cyberCyan,
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: TextField(
                              controller: _controller,
                              onChanged: _onTextChanged,
                              onSubmitted: (_) => _send(),
                              style: CyberTypography.monoRegular.copyWith(
                                color: CyberColors.textPrimary,
                                fontSize: 13,
                              ),
                              cursorColor: CyberColors.cyberCyan,
                              decoration: InputDecoration(
                                hintText: 'Введи сообщение оператора...',
                                hintStyle: CyberTypography.monoRegular.copyWith(
                                  color: CyberColors.textMuted,
                                  fontSize: 12,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _send,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: ShapeDecoration(
                          color: CyberColors.neonCrimson.withValues(alpha: 0.25),
                          shape: const BeveledRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                              topRight: Radius.circular(2),
                              bottomLeft: Radius.circular(2),
                            ),
                            side: BorderSide(color: CyberColors.neonCrimson, width: 1.5),
                          ),
                          shadows: [
                            BoxShadow(
                              color: CyberColors.neonCrimson.withValues(alpha: 0.35),
                              blurRadius: 8,
                              spreadRadius: -1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: CyberColors.neonCrimson,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
