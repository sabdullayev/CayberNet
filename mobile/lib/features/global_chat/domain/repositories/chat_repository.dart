import '../../../auth/domain/entities/user_entity.dart';
import '../entities/chat_message_entity.dart';
import '../entities/room_entity.dart';

abstract class ChatRepository {
  Future<RoomEntity> getGlobalRoom();

  Future<List<RoomEntity>> getMyRooms();

  Future<RoomEntity> createGroup(String name, {List<String>? memberIds});

  Future<RoomEntity> createChannel(String name);

  Future<void> joinRoom(String roomId);

  Future<RoomEntity> getOrCreateDirectRoom(String targetUserId);

  Future<List<UserEntity>> searchUsers(String query);

  Future<int> giveHonor(String targetUserId);

  Future<List<ChatMessageEntity>> getMessages(
    String roomId, {
    String? beforeId,
    int limit = 50,
  });

  List<ChatMessageEntity> getCachedMessages(String roomId);

  Future<void> cacheMessages(String roomId, List<ChatMessageEntity> messages);

  Future<void> connectToRoom(String roomId, String token);

  void sendMessage(String content, {String? replyToId});

  void sendTyping(bool isTyping);

  void sendDeleteMessage(String messageId);

  void sendGiveHonor(String targetUserId);

  Stream<Map<String, dynamic>> get wsEvents;

  void disconnect();
}
