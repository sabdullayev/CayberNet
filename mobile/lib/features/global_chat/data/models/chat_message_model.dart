import '../../domain/entities/chat_message_entity.dart';

class MessageSenderModel extends MessageSenderEntity {
  const MessageSenderModel({
    required super.id,
    required super.username,
    required super.cyberTag,
    super.honorPoints,
    super.avatarUrl,
  });

  factory MessageSenderModel.fromJson(Map<String, dynamic> json) {
    return MessageSenderModel(
      id: json['id'] as String,
      username: json['username'] as String,
      cyberTag: json['cyber_tag'] as String,
      honorPoints: json['honor_points'] as int? ?? 0,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'cyber_tag': cyberTag,
      'honor_points': honorPoints,
      'avatar_url': avatarUrl,
    };
  }
}

class ReplyMessageModel extends ReplyMessageEntity {
  const ReplyMessageModel({
    required super.id,
    required super.content,
    required super.senderUsername,
    required super.senderCyberTag,
  });

  factory ReplyMessageModel.fromJson(Map<String, dynamic> json) {
    return ReplyMessageModel(
      id: json['id'] as String,
      content: json['content'] as String,
      senderUsername: json['sender_username'] as String,
      senderCyberTag: json['sender_cyber_tag'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender_username': senderUsername,
      'sender_cyber_tag': senderCyberTag,
    };
  }
}

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.content,
    super.replyToId,
    super.replyTo,
    required super.sender,
    super.isDeleted,
    required super.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      replyToId: json['reply_to_id'] as String?,
      replyTo: json['reply_to'] != null
          ? ReplyMessageModel.fromJson(json['reply_to'] as Map<String, dynamic>)
          : null,
      sender: MessageSenderModel.fromJson(json['sender'] as Map<String, dynamic>),
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
      'reply_to_id': replyToId,
      'reply_to': replyTo != null
          ? (replyTo as ReplyMessageModel).toJson()
          : null,
      'sender': (sender as MessageSenderModel).toJson(),
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static ChatMessageModel fromEntity(ChatMessageEntity entity) {
    return ChatMessageModel(
      id: entity.id,
      roomId: entity.roomId,
      senderId: entity.senderId,
      content: entity.content,
      replyToId: entity.replyToId,
      replyTo: entity.replyTo != null
          ? ReplyMessageModel(
              id: entity.replyTo!.id,
              content: entity.replyTo!.content,
              senderUsername: entity.replyTo!.senderUsername,
              senderCyberTag: entity.replyTo!.senderCyberTag,
            )
          : null,
      sender: MessageSenderModel(
        id: entity.sender.id,
        username: entity.sender.username,
        cyberTag: entity.sender.cyberTag,
        honorPoints: entity.sender.honorPoints,
        avatarUrl: entity.sender.avatarUrl,
      ),
      isDeleted: entity.isDeleted,
      createdAt: entity.createdAt,
    );
  }
}
