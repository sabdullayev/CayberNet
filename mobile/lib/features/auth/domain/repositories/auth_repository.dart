import '../entities/user_entity.dart';
import '../entities/auth_tokens.dart';

class AuthResult {
  final UserEntity user;
  final AuthTokens tokens;

  const AuthResult({required this.user, required this.tokens});
}

class RegisterResult {
  final UserEntity user;
  final AuthTokens tokens;
  final List<String> seedPhrase;

  const RegisterResult({
    required this.user,
    required this.tokens,
    required this.seedPhrase,
  });
}

abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();

  Future<RegisterResult> registerCyberId({
    required String username,
    required String password,
  });

  Future<AuthResult> loginCyberId({
    required String identifier,
    required String password,
  });

  Future<AuthResult> restoreCyberId({
    required String seedPhrase,
    String? newPassword,
  });

  Future<String?> sendEmailOtp({required String email});

  Future<AuthResult> verifyEmailOtp({
    required String email,
    required String code,
  });

  Future<AuthResult> verifyTelegramCode({required String code});

  Future<UserEntity> updateProfile({
    String? username,
    String? cyberTag,
    String? avatarUrl,
  });

  Future<void> logout();
}
