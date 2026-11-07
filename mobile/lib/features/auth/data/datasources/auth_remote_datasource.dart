import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/user_model.dart';
import '../models/token_model.dart';

abstract class AuthRemoteDataSource {
  Future<({UserModel user, TokenModel tokens, List<String> seedPhrase})>
      registerCyberId({
    required String username,
    required String password,
  });

  Future<({UserModel user, TokenModel tokens})> loginCyberId({
    required String identifier,
    required String password,
  });

  Future<({UserModel user, TokenModel tokens})> restoreCyberId({
    required String seedPhrase,
    String? newPassword,
  });

  Future<String?> sendEmailOtp({required String email});

  Future<({UserModel user, TokenModel tokens})> verifyEmailOtp({
    required String email,
    required String code,
  });

  Future<({UserModel user, TokenModel tokens})> verifyTelegramCode({
    required String code,
  });

  Future<UserModel> getMe();

  Future<UserModel> updateProfile({
    String? username,
    String? cyberTag,
    String? avatarUrl,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  String _extractErrorMessage(dynamic e) {
    if (e is DioException) {
      if (e.response?.data != null && e.response?.data is Map) {
        final detail = e.response?.data['detail'];
        if (detail != null) return detail.toString();
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          (e.message?.contains('Connection refused') ?? false)) {
        return 'Отказ соединения: сервер недоступен (порт 8000). Проверь USB-связь (adb reverse) или работу бэкенда.';
      }
      return e.message ?? 'Ошибка нейросвязи с сервером';
    }
    return e.toString();
  }

  @override
  Future<({UserModel user, TokenModel tokens, List<String> seedPhrase})>
      registerCyberId({
    required String username,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.cyberIdRegister,
        data: {'username': username, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final tokens = TokenModel.fromJson(data['tokens'] as Map<String, dynamic>);
      final rawList = data['seed_phrase'] as List<dynamic>;
      final seedPhrase = rawList.map((e) => e.toString()).toList();
      return (user: user, tokens: tokens, seedPhrase: seedPhrase);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  @override
  Future<({UserModel user, TokenModel tokens})> loginCyberId({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.cyberIdLogin,
        data: {'identifier': identifier, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final tokens = TokenModel.fromJson(data['tokens'] as Map<String, dynamic>);
      return (user: user, tokens: tokens);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  @override
  Future<({UserModel user, TokenModel tokens})> restoreCyberId({
    required String seedPhrase,
    String? newPassword,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.cyberIdRestore,
        data: {
          'seed_phrase': seedPhrase,
          if (newPassword != null && newPassword.isNotEmpty)
            'new_password': newPassword,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final tokens = TokenModel.fromJson(data['tokens'] as Map<String, dynamic>);
      return (user: user, tokens: tokens);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  @override
  Future<String?> sendEmailOtp({required String email}) async {
    try {
      final response = await dio.post(
        ApiEndpoints.emailSendCode,
        data: {'email': email},
      );
      final data = response.data as Map<String, dynamic>;
      return data['dev_code'] as String?;
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  @override
  Future<({UserModel user, TokenModel tokens})> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.emailVerify,
        data: {'email': email, 'code': code},
      );
      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final tokens = TokenModel.fromJson(data['tokens'] as Map<String, dynamic>);
      return (user: user, tokens: tokens);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  @override
  Future<({UserModel user, TokenModel tokens})> verifyTelegramCode({
    required String code,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.telegramVerify,
        data: {'code': code},
      );
      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final tokens = TokenModel.fromJson(data['tokens'] as Map<String, dynamic>);
      return (user: user, tokens: tokens);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  @override
  Future<UserModel> getMe() async {
    try {
      final response = await dio.get(ApiEndpoints.authMe);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? username,
    String? cyberTag,
    String? avatarUrl,
  }) async {
    try {
      final response = await dio.patch(
        ApiEndpoints.updateProfile,
        data: {
          'username': ?username,
          'cyber_tag': ?cyberTag,
          'avatar_url': ?avatarUrl,
        },
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }
}
