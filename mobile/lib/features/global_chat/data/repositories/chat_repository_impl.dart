import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_local_datasource.dart';
import '../datasources/chat_remote_datasource.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final ChatLocalDataSource localDataSource;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<RoomEntity> getGlobalRoom() async {
    return await remoteDataSource.getGlobalRoom();
  }

  @override
  Future<List<RoomEntity>> getMyRooms() async {
    return await remoteDataSource.getMyRooms();
  }

  @override
  Future<RoomEntity> createGroup(String name, {List<String>? memberIds}) async {
    return await remoteDataSource.createGroup(name, memberIds: memberIds);
  }

  @override
  Future<RoomEntity> createChannel(String name) async {
    return await remoteDataSource.createChannel(name);
  }

  @override
  Future<void> joinRoom(String roomId) async {
    await remoteDataSource.joinRoom(roomId);
  }

  @override
  Future<RoomEntity> getOrCreateDirectRoom(String targetUserId) async {
    return await remoteDataSource.getOrCreateDirectRoom(targetUserId);
  }

  @override
  Future<List<UserEntity>> searchUsers(String query) async {
    return await remoteDataSource.searchUsers(query);
  }

  @override
  Future<int> giveHonor(String targetUserId) async {
    return await remoteDataSource.giveHonor(targetUserId);
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(
    String roomId, {
    String? beforeId,
    int limit = 50,
  }) async {
    final messages = await remoteDataSource.getMessages(
      roomId,
      beforeId: beforeId,
      limit: limit,
    );
    if (beforeId == null) {
      // Update local cache with latest 50 messages
      await localDataSource.cacheMessages(roomId, messages);
    }
    return messages;
  }

  @override
  List<ChatMessageEntity> getCachedMessages(String roomId) {
    return localDataSource.getCachedMessages(roomId);
  }

  @override
  Future<void> cacheMessages(
    String roomId,
    List<ChatMessageEntity> messages,
  ) async {
    final models = messages.map((e) => ChatMessageModel.fromEntity(e)).toList();
    await localDataSource.cacheMessages(roomId, models);
  }

  @override
  Future<void> connectToRoom(String roomId, String token) async {
    await remoteDataSource.connectWebSocket(roomId, token);
  }

  @override
  void sendMessage(String content, {String? replyToId}) {
    remoteDataSource.sendMessage(content, replyToId: replyToId);
  }

  @override
  void sendTyping(bool isTyping) {
    remoteDataSource.sendTyping(isTyping);
  }

  @override
  void sendDeleteMessage(String messageId) {
    remoteDataSource.sendDeleteMessage(messageId);
  }

  @override
  void sendGiveHonor(String targetUserId) {
    remoteDataSource.sendGiveHonor(targetUserId);
  }

  @override
  Stream<Map<String, dynamic>> get wsEvents => remoteDataSource.wsEvents;

  @override
  void disconnect() {
    remoteDataSource.disconnectWebSocket();
  }
}
