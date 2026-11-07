import 'package:get_it/get_it.dart';
import '../network/api_endpoints.dart';
import '../network/dio_client.dart';
import '../network/websocket_service.dart';
import '../storage/auth_storage.dart';
import '../storage/message_cache_storage.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/global_chat/data/datasources/chat_local_datasource.dart';
import '../../features/global_chat/data/datasources/chat_remote_datasource.dart';
import '../../features/global_chat/data/repositories/chat_repository_impl.dart';
import '../../features/global_chat/domain/repositories/chat_repository.dart';
import '../../features/global_chat/presentation/bloc/chat_bloc.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // 1. Storage
  final authStorage = AuthStorage();
  await authStorage.init();
  sl.registerSingleton<AuthStorage>(authStorage);

  final messageCache = MessageCacheStorage();
  await messageCache.init();
  sl.registerSingleton<MessageCacheStorage>(messageCache);

  // 2. Network
  await ApiEndpoints.initHost();
  final dioClient = DioClient(authStorage: sl<AuthStorage>());
  sl.registerSingleton<DioClient>(dioClient);

  final wsService = WebSocketService();
  sl.registerSingleton<WebSocketService>(wsService);

  // 3. Remote & Local Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl<DioClient>().dio),
  );

  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(
      dio: sl<DioClient>().dio,
      wsService: sl<WebSocketService>(),
    ),
  );

  sl.registerLazySingleton<ChatLocalDataSource>(
    () => ChatLocalDataSourceImpl(cacheStorage: sl<MessageCacheStorage>()),
  );

  // 4. Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      authStorage: sl<AuthStorage>(),
    ),
  );

  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      remoteDataSource: sl<ChatRemoteDataSource>(),
      localDataSource: sl<ChatLocalDataSource>(),
    ),
  );

  // 5. BLoCs
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );

  sl.registerFactory<ChatBloc>(
    () => ChatBloc(chatRepository: sl<ChatRepository>()),
  );
}
