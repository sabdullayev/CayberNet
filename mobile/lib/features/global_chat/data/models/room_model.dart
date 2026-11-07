import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/room_entity.dart';

class RoomModel extends RoomEntity {
  const RoomModel({
    required super.id,
    required super.name,
    required super.type,
    super.onlineCount,
    super.interlocutor,
    super.lastMessage,
    super.createdAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    UserModel? interlocutor;
    if (json['interlocutor'] != null) {
      interlocutor = UserModel.fromJson(json['interlocutor'] as Map<String, dynamic>);
    }

    LastMessagePreview? lastMessage;
    if (json['last_message'] != null) {
      final lm = json['last_message'] as Map<String, dynamic>;
      lastMessage = LastMessagePreview(
        id: lm['id'] as String,
        senderId: lm['sender_id'] as String,
        content: lm['content'] as String,
        isDeleted: lm['is_deleted'] as bool? ?? false,
        createdAt: lm['created_at'] != null
            ? DateTime.parse(lm['created_at'] as String)
            : DateTime.now(),
        senderUsername: lm['sender_username'] as String?,
      );
    }

    return RoomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      onlineCount: json['online_count'] as int? ?? 0,
      interlocutor: interlocutor,
      lastMessage: lastMessage,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'online_count': onlineCount,
    };
  }
}
