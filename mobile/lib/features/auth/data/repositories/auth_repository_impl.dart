import '../../../../core/storage/auth_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthStorage authStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.authStorage,
  });

  @override
  Future<UserEntity?> getCurrentUser() async {
    if (!authStorage.hasToken()) {
      return null;
    }
    try {
      final user = await remoteDataSource.getMe();
      await authStorage.saveUserData(user.toJson());
      return user;
    } catch (_) {
      // Fallback to local storage cache if offline
      final cached = authStorage.getUserData();
      if (cached != null) {
        return UserModel.fromJson(cached);
      }
      return null;
    }
  }

  @override
  Future<RegisterResult> registerCyberId({
    required String username,
    required String password,
  }) async {
    final result = await remoteDataSource.registerCyberId(
      username: username,
      password: password,
    );
    await authStorage.saveTokens(
      accessToken: result.tokens.accessToken,
      refreshToken: result.tokens.refreshToken,
    );
    await authStorage.saveUserData(result.user.toJson());
    return RegisterResult(
      user: result.user,
      tokens: result.tokens,
      seedPhrase: result.seedPhrase,
    );
  }

  @override
  Future<AuthResult> loginCyberId({
    required String identifier,
    required String password,
  }) async {
    final result = await remoteDataSource.loginCyberId(
      identifier: identifier,
      password: password,
    );
    await authStorage.saveTokens(
      accessToken: result.tokens.accessToken,
      refreshToken: result.tokens.refreshToken,
    );
    await authStorage.saveUserData(result.user.toJson());
    return AuthResult(user: result.user, tokens: result.tokens);
  }

  @override
  Future<AuthResult> restoreCyberId({
    required String seedPhrase,
    String? newPassword,
  }) async {
    final result = await remoteDataSource.restoreCyberId(
      seedPhrase: seedPhrase,
      newPassword: newPassword,
    );
    await authStorage.saveTokens(
      accessToken: result.tokens.accessToken,
      refreshToken: result.tokens.refreshToken,
    );
    await authStorage.saveUserData(result.user.toJson());
    return AuthResult(user: result.user, tokens: result.tokens);
  }

  @override
  Future<String?> sendEmailOtp({required String email}) async {
    return await remoteDataSource.sendEmailOtp(email: email);
  }

  @override
  Future<AuthResult> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    final result = await remoteDataSource.verifyEmailOtp(
      email: email,
      code: code,
    );
    await authStorage.saveTokens(
      accessToken: result.tokens.accessToken,
      refreshToken: result.tokens.refreshToken,
    );
    await authStorage.saveUserData(result.user.toJson());
    return AuthResult(user: result.user, tokens: result.tokens);
  }

  @override
  Future<AuthResult> verifyTelegramCode({required String code}) async {
    final result = await remoteDataSource.verifyTelegramCode(code: code);
    await authStorage.saveTokens(
      accessToken: result.tokens.accessToken,
      refreshToken: result.tokens.refreshToken,
    );
    await authStorage.saveUserData(result.user.toJson());
    return AuthResult(user: result.user, tokens: result.tokens);
  }

  @override
  Future<UserEntity> updateProfile({
    String? username,
    String? cyberTag,
    String? avatarUrl,
  }) async {
    final updatedUser = await remoteDataSource.updateProfile(
      username: username,
      cyberTag: cyberTag,
      avatarUrl: avatarUrl,
    );
    await authStorage.saveUserData(updatedUser.toJson());
    return updatedUser;
  }

  @override
  Future<void> logout() async {
    await authStorage.clear();
  }
}
