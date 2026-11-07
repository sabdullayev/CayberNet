import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message_entity.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatStarted extends ChatEvent {
  final String roomId;
  final String token;

  const ChatStarted({required this.roomId, required this.token});

  @override
  List<Object?> get props => [roomId, token];
}

class ChatMessageReceived extends ChatEvent {
  final ChatMessageEntity message;

  const ChatMessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatMessageDeleted extends ChatEvent {
  final String messageId;

  const ChatMessageDeleted(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class ChatOnlineCountUpdated extends ChatEvent {
  final int count;

  const ChatOnlineCountUpdated(this.count);

  @override
  List<Object?> get props => [count];
}

class ChatTypingUpdated extends ChatEvent {
  final String username;
  final String cyberTag;
  final bool isTyping;

  const ChatTypingUpdated({
    required this.username,
    required this.cyberTag,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [username, cyberTag, isTyping];
}

class ChatSendMessageSubmitted extends ChatEvent {
  final String content;
  final String? replyToId;

  const ChatSendMessageSubmitted({
    required this.content,
    this.replyToId,
  });

  @override
  List<Object?> get props => [content, replyToId];
}

class ChatTypingSubmitted extends ChatEvent {
  final bool isTyping;

  const ChatTypingSubmitted({required this.isTyping});

  @override
  List<Object?> get props => [isTyping];
}

class ChatDeleteMessageSubmitted extends ChatEvent {
  final String messageId;

  const ChatDeleteMessageSubmitted({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

class ChatReplyTargetSelected extends ChatEvent {
  final ChatMessageEntity? replyTarget;

  const ChatReplyTargetSelected(this.replyTarget);

  @override
  List<Object?> get props => [replyTarget];
}

class ChatGiveHonorRequested extends ChatEvent {
  final String targetUserId;

  const ChatGiveHonorRequested(this.targetUserId);

  @override
  List<Object?> get props => [targetUserId];
}

class ChatHonorUpdated extends ChatEvent {
  final String targetUserId;
  final int honorPoints;
  final String fromUsername;

  const ChatHonorUpdated({
    required this.targetUserId,
    required this.honorPoints,
    required this.fromUsername,
  });

  @override
  List<Object?> get props => [targetUserId, honorPoints, fromUsername];
}

class ChatClosed extends ChatEvent {}
