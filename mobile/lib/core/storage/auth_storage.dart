import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class AuthStorage {
  static const String boxName = 'ronin_auth_box';
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserData = 'user_data';

  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(boxName);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _box.put(keyAccessToken, accessToken);
    await _box.put(keyRefreshToken, refreshToken);
  }

  String? getAccessToken() {
    return _box.get(keyAccessToken) as String?;
  }

  String? getRefreshToken() {
    return _box.get(keyRefreshToken) as String?;
  }

  bool hasToken() {
    final token = getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveUserData(Map<String, dynamic> userMap) async {
    await _box.put(keyUserData, jsonEncode(userMap));
  }

  Map<String, dynamic>? getUserData() {
    final raw = _box.get(keyUserData) as String?;
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
