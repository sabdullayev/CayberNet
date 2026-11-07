import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../models/chat_message_model.dart';
import '../models/room_model.dart';

abstract class ChatRemoteDataSource {
  Future<RoomModel> getGlobalRoom();

  Future<List<RoomModel>> getMyRooms();

  Future<RoomModel> createGroup(String name, {List<String>? memberIds});

  Future<RoomModel> createChannel(String name);

  Future<void> joinRoom(String roomId);

  Future<RoomModel> getOrCreateDirectRoom(String targetUserId);

  Future<List<UserModel>> searchUsers(String query);

  Future<int> giveHonor(String targetUserId);

  Future<List<ChatMessageModel>> getMessages(
    String roomId, {
    String? beforeId,
    int limit = 50,
  });

  Future<void> connectWebSocket(String roomId, String token);

  void sendMessage(String content, {String? replyToId});

  void sendTyping(bool isTyping);

  void sendDeleteMessage(String messageId);

  void sendGiveHonor(String targetUserId);

  Stream<Map<String, dynamic>> get wsEvents;

  void disconnectWebSocket();
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Dio dio;
  final WebSocketService wsService;

  ChatRemoteDataSourceImpl({
    required this.dio,
    required this.wsService,
  });

  @override
  Future<RoomModel> getGlobalRoom() async {
    try {
      final response = await dio.get(ApiEndpoints.globalRoom);
      return RoomModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Не удалось загрузить данные Таверны Нео-Токио');
    }
  }

  @override
  Future<List<RoomModel>> getMyRooms() async {
    try {
      final response = await dio.get(ApiEndpoints.myRooms);
      final list = response.data as List<dynamic>;
      return list
          .map((e) => RoomModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Ошибка загрузки списка каналов');
    }
  }

  @override
  Future<RoomModel> createGroup(String name, {List<String>? memberIds}) async {
    try {
      final response = await dio.post(
        ApiEndpoints.createGroup,
        data: {
          'name': name,
          if (memberIds != null && memberIds.isNotEmpty) 'member_ids': memberIds,
        },
      );
      return RoomModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      throw Exception(detail ?? 'Не удалось создать кибер-группу');
    } catch (e) {
      throw Exception('Не удалось создать кибер-группу');
    }
  }

  @override
  Future<RoomModel> createChannel(String name) async {
    try {
      final response = await dio.post(
        ApiEndpoints.createChannel,
        data: {'name': name},
      );
      return RoomModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      throw Exception(detail ?? 'Не удалось создать нейро-канал');
    } catch (e) {
      throw Exception('Не удалось создать нейро-канал');
    }
  }

  @override
  Future<void> joinRoom(String roomId) async {
    try {
      await dio.post(ApiEndpoints.joinRoom(roomId));
    } catch (_) {}
  }

  @override
  Future<RoomModel> getOrCreateDirectRoom(String targetUserId) async {
    try {
      final response = await dio.post(ApiEndpoints.directRoom(targetUserId));
      return RoomModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      throw Exception(detail ?? 'Не удалось открыть личный канал');
    } catch (e) {
      throw Exception('Не удалось открыть личный канал');
    }
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await dio.get(
        ApiEndpoints.userSearch,
        queryParameters: {'query': query},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Ошибка поиска пользователей');
    }
  }

  @override
  Future<int> giveHonor(String targetUserId) async {
    try {
      final response = await dio.post(ApiEndpoints.userHonor(targetUserId));
      final data = response.data as Map<String, dynamic>;
      return data['honor_points'] as int;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      throw Exception(detail ?? 'Ошибка начисления чести');
    } catch (e) {
      throw Exception('Ошибка начисления чести');
    }
  }

  @override
  Future<List<ChatMessageModel>> getMessages(
    String roomId, {
    String? beforeId,
    int limit = 50,
  }) async {
    try {
      final query = <String, dynamic>{'limit': limit};
      if (beforeId != null) query['before_id'] = beforeId;

      final response = await dio.get(
        '${ApiEndpoints.rooms}$roomId/messages',
        queryParameters: query,
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Ошибка загрузки радиоистории сообщений');
    }
  }

  @override
  Future<void> connectWebSocket(String roomId, String token) async {
    await wsService.connect(roomId, token);
  }

  @override
  void sendMessage(String content, {String? replyToId}) {
    wsService.sendNewMessage(content, replyToId: replyToId);
  }

  @override
  void sendTyping(bool isTyping) {
    wsService.sendTyping(isTyping);
  }

  @override
  void sendDeleteMessage(String messageId) {
    wsService.sendDeleteMessage(messageId);
  }

  @override
  void sendGiveHonor(String targetUserId) {
    wsService.sendGiveHonor(targetUserId);
  }

  @override
  Stream<Map<String, dynamic>> get wsEvents => wsService.events;

  @override
  void disconnectWebSocket() {
    wsService.disconnect();
  }
}
