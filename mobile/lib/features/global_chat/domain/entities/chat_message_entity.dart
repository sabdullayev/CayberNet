import 'package:equatable/equatable.dart';

class MessageSenderEntity extends Equatable {
  final String id;
  final String username;
  final String cyberTag;
  final int honorPoints;
  final String? avatarUrl;

  const MessageSenderEntity({
    required this.id,
    required this.username,
    required this.cyberTag,
    this.honorPoints = 0,
    this.avatarUrl,
  });

  String get rank {
    if (honorPoints < 10) return "Скиталец Сетки";
    if (honorPoints < 50) return "Нетраннер";
    if (honorPoints < 100) return "Кибер-Агент";
    return "Архитектор Сетки";
  }

  bool get isDaimyo => honorPoints >= 100;

  MessageSenderEntity copyWith({
    String? id,
    String? username,
    String? cyberTag,
    int? honorPoints,
    String? avatarUrl,
  }) {
    return MessageSenderEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      cyberTag: cyberTag ?? this.cyberTag,
      honorPoints: honorPoints ?? this.honorPoints,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [id, username, cyberTag, honorPoints, avatarUrl];
}

class ReplyMessageEntity extends Equatable {
  final String id;
  final String content;
  final String senderUsername;
  final String senderCyberTag;

  const ReplyMessageEntity({
    required this.id,
    required this.content,
    required this.senderUsername,
    required this.senderCyberTag,
  });

  @override
  List<Object?> get props => [id, content, senderUsername, senderCyberTag];
}

class ChatMessageEntity extends Equatable {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final String? replyToId;
  final ReplyMessageEntity? replyTo;
  final MessageSenderEntity sender;
  final bool isDeleted;
  final DateTime createdAt;

  const ChatMessageEntity({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    this.replyToId,
    this.replyTo,
    required this.sender,
    this.isDeleted = false,
    required this.createdAt,
  });

  ChatMessageEntity copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? content,
    String? replyToId,
    ReplyMessageEntity? replyTo,
    MessageSenderEntity? sender,
    bool? isDeleted,
    DateTime? createdAt,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      replyToId: replyToId ?? this.replyToId,
      replyTo: replyTo ?? this.replyTo,
      sender: sender ?? this.sender,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        roomId,
        senderId,
        content,
        replyToId,
        replyTo,
        sender,
        isDeleted,
        createdAt,
      ];
}
