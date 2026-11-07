import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/cyber_colors.dart';
import '../../../../core/theme/cyber_typography.dart';
import '../../../../core/widgets/cyber_badge.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/cyber_dossier_modal.dart';

typedef GlobalChatScreen = ChatScreen;

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String token;
  final String currentUserId;
  final String roomTitle;
  final bool isDirect;
  final UserEntity? interlocutor;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.token,
    required this.currentUserId,
    this.roomTitle = 'НЕО-ТОКИО СЕКТОР 01',
    this.isDirect = false,
    this.interlocutor,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(
          ChatStarted(roomId: widget.roomId, token: widget.token),
        );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  void _openDossier(BuildContext context, MessageSenderEntity sender) {
    final user = UserEntity(
      id: sender.id,
      cyberTag: sender.cyberTag,
      username: sender.username,
      avatarUrl: sender.avatarUrl,
      honorPoints: sender.honorPoints,
      createdAt: DateTime.now(),
    );

    CyberDossierModal.show(
      context,
      user: user,
      currentUserId: widget.currentUserId,
      token: widget.token,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberColors.voidBackground,
      appBar: AppBar(
        backgroundColor: CyberColors.voidBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: CyberColors.borderSubtle,
            height: 1.0,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 10, bottom: 10),
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: const ShapeDecoration(
                color: CyberColors.panel,
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                  side: BorderSide(color: CyberColors.cyberCyan, width: 1.2),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: CyberColors.cyberCyan,
                size: 14,
              ),
            ),
          ),
        ),
        title: BlocBuilder<ChatBloc, ChatState>(
          buildWhen: (prev, curr) =>
              prev.onlineCount != curr.onlineCount ||
              prev.typingUsers != curr.typingUsers,
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: CyberColors.cyberCyan,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: CyberColors.cyberCyan,
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.roomTitle,
                        style: CyberTypography.headerSmall.copyWith(
                          fontSize: 14,
                          color: CyberColors.textPrimary,
                          letterSpacing: 1.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                if (state.typingUsers.isNotEmpty) ...[
                  Text(
                    '⚡ ${state.typingUsers.join(', ')} передает данные...',
                    style: CyberTypography.monoSmall.copyWith(
                      color: CyberColors.katanaGold,
                      fontSize: 10,
                    ),
                  ),
                ] else ...[
                  Text(
                    widget.isDirect
                        ? 'ЗАЩИЩЕННЫЙ P2P КАНАЛ'
                        : '${state.onlineCount} ОПЕРАТОРОВ В СЕТИ',
                    style: CyberTypography.monoSmall.copyWith(
                      color: CyberColors.matrixGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: widget.isDirect
                ? (widget.interlocutor != null
                    ? GestureDetector(
                        onTap: () => CyberDossierModal.show(
                          context,
                          user: widget.interlocutor!,
                          currentUserId: widget.currentUserId,
                          token: widget.token,
                        ),
                        child: CyberBadge(
                          label: widget.interlocutor!.rank,
                          color: widget.interlocutor!.isDaimyo
                              ? CyberColors.katanaGold
                              : CyberColors.neonCrimson,
                          cutRadius: 3,
                        ),
                      )
                    : const CyberBadge(
                        label: 'DIRECT',
                        color: CyberColors.neonCrimson,
                        cutRadius: 3,
                      ))
                : const CyberBadge(
                    label: 'SECTOR 01',
                    color: CyberColors.cyberCyan,
                    cutRadius: 3,
                  ),
          ),
        ],
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listenWhen: (prev, curr) => prev.messages.length != curr.messages.length,
        listener: (context, state) {
          _scrollToBottom();
        },
        builder: (context, state) {
          final messages = state.messages;

          return Column(
            children: [
              // Message list
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const ShapeDecoration(
                                  color: CyberColors.panel,
                                  shape: BeveledRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                    side: BorderSide(color: CyberColors.cyberCyan, width: 1.2),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.radar,
                                  color: CyberColors.cyberCyan,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                state.isLoadingHistory
                                    ? 'СКАНИРОВАНИЕ ЧАСТОТЫ...'
                                    : (widget.isDirect
                                        ? 'КАНАЛ ЧИСТ. НАЧНИ ДИАЛОГ.'
                                        : 'ТИШИНА В ХАБЕ. БУДЬ ПЕРВЫМ.'),
                                style: CyberTypography.monoBold.copyWith(
                                  color: CyberColors.cyberCyan,
                                  fontSize: 12,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Шина защищенной передачи данных активна',
                                style: CyberTypography.monoSmall.copyWith(
                                  color: CyberColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg.senderId == widget.currentUserId;

                          return ChatBubble(
                            message: msg,
                            isMe: isMe,
                            onSwipeReply: () {
                              context
                                  .read<ChatBloc>()
                                  .add(ChatReplyTargetSelected(msg));
                            },
                            onSlashDelete: () {
                              context
                                  .read<ChatBloc>()
                                  .add(ChatDeleteMessageSubmitted(messageId: msg.id));
                            },
                            onOpenDossier: (sender) => _openDossier(context, sender),
                          );
                        },
                      ),
              ),

              // Chat Input Bar
              ChatInputBar(
                replyTarget: state.replyTarget,
                onCancelReply: () {
                  context
                      .read<ChatBloc>()
                      .add(const ChatReplyTargetSelected(null));
                },
                onSendMessage: (text, replyToId) {
                  context.read<ChatBloc>().add(
                        ChatSendMessageSubmitted(
                          content: text,
                          replyToId: replyToId,
                        ),
                      );
                },
                onTyping: (isTyping) {
                  context
                      .read<ChatBloc>()
                      .add(ChatTypingSubmitted(isTyping: isTyping));
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
