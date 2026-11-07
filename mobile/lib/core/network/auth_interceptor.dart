import 'package:dio/dio.dart';
import '../storage/auth_storage.dart';

class AuthInterceptor extends Interceptor {
  final AuthStorage authStorage;

  AuthInterceptor({required this.authStorage});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = authStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired or invalid
      // In the future can trigger refresh flow or logout event
    }
    handler.next(err);
  }
}
