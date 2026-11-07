import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user_entity.dart';

class LastMessagePreview extends Equatable {
  final String id;
  final String senderId;
  final String content;
  final bool isDeleted;
  final DateTime createdAt;
  final String? senderUsername;

  const LastMessagePreview({
    required this.id,
    required this.senderId,
    required this.content,
    required this.isDeleted,
    required this.createdAt,
    this.senderUsername,
  });

  @override
  List<Object?> get props => [
        id,
        senderId,
        content,
        isDeleted,
        createdAt,
        senderUsername,
      ];
}

class RoomEntity extends Equatable {
  final String id;
  final String name;
  final String type;
  final int onlineCount;
  final UserEntity? interlocutor;
  final LastMessagePreview? lastMessage;
  final DateTime? createdAt;

  const RoomEntity({
    required this.id,
    required this.name,
    required this.type,
    this.onlineCount = 0,
    this.interlocutor,
    this.lastMessage,
    this.createdAt,
  });

  bool get isDirect => type == 'direct';
  bool get isGlobal => type == 'global';
  bool get isGroup => type == 'group';
  bool get isChannel => type == 'channel';

  RoomEntity copyWith({
    String? id,
    String? name,
    String? type,
    int? onlineCount,
    UserEntity? interlocutor,
    LastMessagePreview? lastMessage,
    DateTime? createdAt,
  }) {
    return RoomEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      onlineCount: onlineCount ?? this.onlineCount,
      interlocutor: interlocutor ?? this.interlocutor,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        onlineCount,
        interlocutor,
        lastMessage,
        createdAt,
      ];
}
