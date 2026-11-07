import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class MessageCacheStorage {
  static const String boxName = 'messages_cache';
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  Future<void> saveMessages(String roomId, List<Map<String, dynamic>> messages) async {
    // Keep at most 50 latest messages
    final trimmed = messages.length > 50
        ? messages.sublist(messages.length - 50)
        : messages;
    final jsonStr = jsonEncode(trimmed);
    await _box.put('room_$roomId', jsonStr);
  }

  List<Map<String, dynamic>> getCachedMessages(String roomId) {
    final raw = _box.get('room_$roomId') as String?;
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clear(String roomId) async {
    await _box.delete('room_$roomId');
  }
}
