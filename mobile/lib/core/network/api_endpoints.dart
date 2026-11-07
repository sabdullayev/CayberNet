import 'dart:io' show HttpClient;
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String host = '127.0.0.1:8000';

  static String get baseUrl => 'http://$host/api/v1';

  /// Automatically discovers the active backend server
  /// Works for physical Android devices (with adb reverse), emulators, and local network.
  static Future<void> initHost() async {
    if (kIsWeb) {
      host = 'localhost:8000';
      return;
    }

    final candidates = [
      '127.0.0.1:8000',     // Physical device over USB reverse OR localhost
      '10.0.2.2:8000',      // Android emulator virtual bridge
      '192.168.1.41:8000',  // Local WiFi LAN host
      '192.168.0.100:8000', // Local WiFi LAN fallback
    ];

    for (final candidate in candidates) {
      try {
        final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 700);
        final request = await client.getUrl(Uri.parse('http://$candidate/health'));
        final response = await request.close();
        if (response.statusCode == 200) {
          host = candidate;
          client.close();
          return;
        }
        client.close();
      } catch (_) {}
    }
  }

  // Auth endpoints
  static const String cyberIdRegister = '/auth/cyber-id/register';
  static const String cyberIdLogin = '/auth/cyber-id/login';
  static const String cyberIdRestore = '/auth/cyber-id/restore';
  static const String emailSendCode = '/auth/email/send-code';
  static const String emailVerify = '/auth/email/verify';
  static const String telegramVerify = '/auth/telegram/verify';
  static const String authMe = '/auth/me';
  static const String refresh = '/auth/refresh';

  // Rooms
  static const String rooms = '/rooms/';
  static const String myRooms = '/rooms/my';
  static const String globalRoom = '/rooms/global';
  static const String createGroup = '/rooms/group';
  static const String createChannel = '/rooms/channel';
  static String joinRoom(String roomId) => '/rooms/$roomId/join';
  static String directRoom(String targetUserId) => '/rooms/direct/$targetUserId';

  // Users & Honor
  static const String userSearch = '/users/search';
  static const String updateProfile = '/users/me';
  static String userHonor(String userId) => '/users/$userId/honor';
}
