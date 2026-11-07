import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_endpoints.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String? _roomId;
  String? _token;
  bool _manualDisconnect = false;

  static String getWsUrl(String roomId, String token) {
    return '${ApiEndpoints.wsProtocol}://${ApiEndpoints.cleanHost}/api/v1/ws/$roomId?token=$token';
  }

  Future<void> connect(String roomId, String token) async {
    _roomId = roomId;
    _token = token;
    _manualDisconnect = false;

    _cleanup();

    final url = getWsUrl(roomId, token);

    try {
      final uri = Uri.parse(url);
      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        (data) {
          _isConnected = true;
          try {
            final decoded = jsonDecode(data.toString()) as Map<String, dynamic>;
            _eventController.add(decoded);
          } catch (_) {}
        },
        onError: (error) {
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          _isConnected = false;
          _scheduleReconnect();
        },
      );

      _startPingTimer();
    } catch (_) {
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_isConnected) {
        send({'type': 'ping'});
      }
    });
  }

  void _scheduleReconnect() {
    if (_manualDisconnect) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_roomId != null && _token != null && !_manualDisconnect) {
        connect(_roomId!, _token!);
      }
    });
  }

  void send(Map<String, dynamic> data) {
    if (_channel != null) {
      try {
        _channel!.sink.add(jsonEncode(data));
      } catch (_) {}
    }
  }

  void sendNewMessage(String content, {String? replyToId}) {
    final payload = <String, dynamic>{
      'type': 'new_message',
      'content': content,
    };
    if (replyToId != null) {
      payload['reply_to_id'] = replyToId;
    }
    send(payload);
  }

  void sendTyping(bool isTyping) {
    send({
      'type': 'typing',
      'is_typing': isTyping,
    });
  }

  void sendDeleteMessage(String messageId) {
    send({
      'type': 'delete_message',
      'message_id': messageId,
    });
  }

  void sendGiveHonor(String targetUserId) {
    send({
      'type': 'give_honor',
      'target_user_id': targetUserId,
    });
  }

  void disconnect() {
    _manualDisconnect = true;
    _cleanup();
  }

  void _cleanup() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
