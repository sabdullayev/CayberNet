import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import 'auth_interceptor.dart';
import '../storage/auth_storage.dart';

class DioClient {
  final Dio dio;

  DioClient({required AuthStorage authStorage})
      : dio = Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(AuthInterceptor(authStorage: authStorage));
  }
}
