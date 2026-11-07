import '../../../../core/storage/message_cache_storage.dart';
import '../models/chat_message_model.dart';

abstract class ChatLocalDataSource {
  List<ChatMessageModel> getCachedMessages(String roomId);
  Future<void> cacheMessages(String roomId, List<ChatMessageModel> messages);
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  final MessageCacheStorage cacheStorage;

  ChatLocalDataSourceImpl({required this.cacheStorage});

  @override
  List<ChatMessageModel> getCachedMessages(String roomId) {
    final list = cacheStorage.getCachedMessages(roomId);
    return list.map((json) => ChatMessageModel.fromJson(json)).toList();
  }

  @override
  Future<void> cacheMessages(
    String roomId,
    List<ChatMessageModel> messages,
  ) async {
    final jsonList = messages.map((m) => m.toJson()).toList();
    await cacheStorage.saveMessages(roomId, jsonList);
  }
}
