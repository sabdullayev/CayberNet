import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.cyberTag,
    required super.username,
    super.email,
    super.telegramId,
    super.avatarUrl,
    super.honorPoints,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      cyberTag: json['cyber_tag'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      telegramId: json['telegram_id'] as int?,
      avatarUrl: json['avatar_url'] as String?,
      honorPoints: json['honor_points'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cyber_tag': cyberTag,
      'username': username,
      'email': email,
      'telegram_id': telegramId,
      'avatar_url': avatarUrl,
      'honor_points': honorPoints,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
