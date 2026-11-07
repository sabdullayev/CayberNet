import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String cyberTag;
  final String username;
  final String? email;
  final int? telegramId;
  final String? avatarUrl;
  final int honorPoints;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.cyberTag,
    required this.username,
    this.email,
    this.telegramId,
    this.avatarUrl,
    this.honorPoints = 0,
    required this.createdAt,
  });

  String get rank {
    if (honorPoints < 10) return "Скиталец Сетки";
    if (honorPoints < 50) return "Нетраннер";
    if (honorPoints < 100) return "Кибер-Агент";
    return "Архитектор Сетки";
  }

  bool get isDaimyo => honorPoints >= 100;

  UserEntity copyWith({
    String? id,
    String? cyberTag,
    String? username,
    String? email,
    int? telegramId,
    String? avatarUrl,
    int? honorPoints,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      cyberTag: cyberTag ?? this.cyberTag,
      username: username ?? this.username,
      email: email ?? this.email,
      telegramId: telegramId ?? this.telegramId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      honorPoints: honorPoints ?? this.honorPoints,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        cyberTag,
        username,
        email,
        telegramId,
        avatarUrl,
        honorPoints,
        createdAt,
      ];
}
