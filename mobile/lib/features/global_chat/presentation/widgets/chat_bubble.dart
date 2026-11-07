import 'package:flutter/material.dart';
import '../../../../core/theme/cyber_colors.dart';
import '../../../../core/theme/cyber_typography.dart';
import '../../../../core/widgets/cyber_badge.dart';
import '../../domain/entities/chat_message_entity.dart';
import 'katana_slash_dismissible.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isMe;
  final VoidCallback onSwipeReply;
  final VoidCallback onSlashDelete;
  final Function(MessageSenderEntity sender)? onOpenDossier;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onSwipeReply,
    required this.onSlashDelete,
    this.onOpenDossier,
  });

  @override
  Widget build(BuildContext context) {
    Widget bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: ShapeDecoration(
        color: isMe
            ? const Color(0xFF1E080F) // Deep Obsidian Crimson
            : CyberColors.panel,      // Panel #0F141F
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMe ? 10 : 2),
            topRight: Radius.circular(isMe ? 2 : 10),
            bottomLeft: const Radius.circular(10),
            bottomRight: const Radius.circular(10),
          ),
          side: BorderSide(
            color: isMe
                ? CyberColors.neonCrimson.withValues(alpha: 0.65)
                : CyberColors.cyberCyan.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
        shadows: [
          BoxShadow(
            color: isMe
                ? CyberColors.neonCrimson.withValues(alpha: 0.18)
                : CyberColors.cyberCyan.withValues(alpha: 0.12),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sender Header (for other users)
            if (!isMe) ...[
              GestureDetector(
                onTap: () => onOpenDossier?.call(message.sender),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CyberBadge(
                      label: message.sender.cyberTag,
                      color: CyberColors.cyberCyan,
                      cutRadius: 3,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      message.sender.username,
                      style: CyberTypography.headerSmall.copyWith(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    if (message.sender.honorPoints > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '⚡${message.sender.honorPoints}',
                        style: CyberTypography.monoSmall.copyWith(
                          color: CyberColors.katanaGold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: CyberColors.textMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Quoted Reply Preview
            if (message.replyTo != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: ShapeDecoration(
                  color: CyberColors.inputFill,
                  shape: const BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                    side: BorderSide(color: CyberColors.borderSubtle, width: 0.8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 2.5,
                      height: 26,
                      decoration: BoxDecoration(
                        color: CyberColors.katanaGold,
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: const [
                          BoxShadow(
                            color: CyberColors.katanaGold,
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.replyTo!.senderCyberTag,
                            style: CyberTypography.monoSmall.copyWith(
                              color: CyberColors.katanaGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            message.replyTo!.content,
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
                  ],
                ),
              ),
            ],

            // Message Body or Katana Slashed Notice
            if (message.isDeleted) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.flash_on,
                    color: CyberColors.neonCrimson,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '⚡ [СООБЩЕНИЕ УНИЧТОЖЕНО]',
                    style: CyberTypography.monoSmall.copyWith(
                      color: CyberColors.neonCrimson,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                message.content,
                style: CyberTypography.bodyLarge.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],

            const SizedBox(height: 4),
            // Timestamp
            Text(
              _formatTime(message.createdAt),
              style: CyberTypography.monoSmall.copyWith(
                color: CyberColors.textMuted,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );

    // Apply swipe to reply for other messages
    if (!isMe && !message.isDeleted) {
      bubble = Dismissible(
        key: ValueKey('reply_${message.id}'),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (_) async {
          onSwipeReply();
          return false;
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Icon(Icons.reply, color: CyberColors.cyberCyan, size: 22),
        ),
        child: bubble,
      );
    }

    // Apply Katana Slash for own messages
    if (isMe && !message.isDeleted) {
      bubble = KatanaSlashDismissible(
        messageId: message.id,
        onSlash: onSlashDelete,
        child: bubble,
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
