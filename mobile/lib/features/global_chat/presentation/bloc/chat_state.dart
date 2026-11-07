import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/room_entity.dart';

class ChatState extends Equatable {
  final List<ChatMessageEntity> messages;
  final RoomEntity? room;
  final int onlineCount;
  final List<String> typingUsers;
  final ChatMessageEntity? replyTarget;
  final bool isLoadingHistory;
  final String? errorMessage;

  const ChatState({
    this.messages = const [],
    this.room,
    this.onlineCount = 0,
    this.typingUsers = const [],
    this.replyTarget,
    this.isLoadingHistory = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatMessageEntity>? messages,
    RoomEntity? room,
    int? onlineCount,
    List<String>? typingUsers,
    ChatMessageEntity? Function()? replyTarget,
    bool? isLoadingHistory,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      room: room ?? this.room,
      onlineCount: onlineCount ?? this.onlineCount,
      typingUsers: typingUsers ?? this.typingUsers,
      replyTarget: replyTarget != null ? replyTarget() : this.replyTarget,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        room,
        onlineCount,
        typingUsers,
        replyTarget,
        isLoadingHistory,
        errorMessage,
      ];
}
