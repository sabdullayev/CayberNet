import 'dart:io' show HttpClient;
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  /// Primary Cloudflare Public Tunnel host (accessible by any friend over internet)
  static const String publicTunnelHost = 'movers-continuous-numeric-dividend.trycloudflare.com';

  static String host = publicTunnelHost;

  static bool get isSecure =>
      host.contains('trycloudflare.com') ||
      host.contains('ngrok') ||
      host.startsWith('https://');

  static String get protocol => isSecure ? 'https' : 'http';
  static String get wsProtocol => isSecure ? 'wss' : 'ws';

  static String get cleanHost {
    var h = host;
    if (h.startsWith('http://')) h = h.substring(7);
    if (h.startsWith('https://')) h = h.substring(8);
    if (h.endsWith('/')) h = h.substring(0, h.length - 1);
    return h;
  }

  static String get baseUrl => '$protocol://$cleanHost/api/v1';

  /// Automatically discovers the active backend server
  /// First prioritizes public tunnel (so friends anywhere can connect immediately),
  /// then falls back to local candidates for development.
  static Future<void> initHost() async {
    if (kIsWeb) {
      host = 'localhost:8000';
      return;
    }

    final candidates = [
      publicTunnelHost,     // Public Cloudflare Tunnel (accessible from any phone over internet)
      '127.0.0.1:8000',     // Physical device over USB reverse OR localhost
      '10.0.2.2:8000',      // Android emulator virtual bridge
      '192.168.1.41:8000',  // Local WiFi LAN host
      '192.168.0.100:8000', // Local WiFi LAN fallback
    ];

    for (final candidate in candidates) {
      try {
        final isHttps = candidate.contains('trycloudflare.com') || candidate.contains('ngrok');
        final scheme = isHttps ? 'https' : 'http';
        final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1500);
        final request = await client.getUrl(Uri.parse('$scheme://$candidate/health'));
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
