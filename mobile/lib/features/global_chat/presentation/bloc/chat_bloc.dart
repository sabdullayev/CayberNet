import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/chat_message_model.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  StreamSubscription? _wsSubscription;

  ChatBloc({required this.chatRepository}) : super(const ChatState()) {
    on<ChatStarted>(_onChatStarted);
    on<ChatMessageReceived>(_onMessageReceived);
    on<ChatMessageDeleted>(_onMessageDeleted);
    on<ChatOnlineCountUpdated>(_onOnlineCountUpdated);
    on<ChatTypingUpdated>(_onTypingUpdated);
    on<ChatSendMessageSubmitted>(_onSendMessageSubmitted);
    on<ChatTypingSubmitted>(_onTypingSubmitted);
    on<ChatDeleteMessageSubmitted>(_onDeleteMessageSubmitted);
    on<ChatReplyTargetSelected>(_onReplyTargetSelected);
    on<ChatGiveHonorRequested>(_onGiveHonorRequested);
    on<ChatHonorUpdated>(_onHonorUpdated);
    on<ChatClosed>(_onChatClosed);
  }

  Future<void> _onChatStarted(
    ChatStarted event,
    Emitter<ChatState> emit,
  ) async {
    // 1. Immediately show cached messages if available
    final cached = chatRepository.getCachedMessages(event.roomId);
    if (cached.isNotEmpty) {
      emit(state.copyWith(messages: cached));
    }

    emit(state.copyWith(isLoadingHistory: true));

    // 2. Fetch room info & fresh history from REST
    try {
      final remoteMessages = await chatRepository.getMessages(event.roomId);
      emit(state.copyWith(
        messages: remoteMessages,
        isLoadingHistory: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingHistory: false));
    }

    // 3. Connect WebSocket and subscribe to events
    await _wsSubscription?.cancel();
    await chatRepository.connectToRoom(event.roomId, event.token);

    _wsSubscription = chatRepository.wsEvents.listen((eventData) {
      final type = eventData['type'] as String?;
      if (type == 'online_count') {
        final count = eventData['count'] as int? ?? 0;
        add(ChatOnlineCountUpdated(count));
      } else if (type == 'new_message') {
        final msgData = eventData['message'] as Map<String, dynamic>;
        final message = ChatMessageModel.fromJson(msgData);
        add(ChatMessageReceived(message));
      } else if (type == 'message_deleted') {
        final messageId = eventData['message_id'] as String;
        add(ChatMessageDeleted(messageId));
      } else if (type == 'user_typing') {
        final username = eventData['username'] as String? ?? 'Оператор';
        final cyberTag = eventData['cyber_tag'] as String? ?? '';
        final isTyping = eventData['is_typing'] as bool? ?? false;
        add(ChatTypingUpdated(
          username: username,
          cyberTag: cyberTag,
          isTyping: isTyping,
        ));
      } else if (type == 'honor_updated') {
        final targetUserId = eventData['target_user_id'] as String? ?? '';
        final honorPoints = eventData['honor_points'] as int? ?? 0;
        final fromUsername = eventData['from_username'] as String? ?? '';
        add(ChatHonorUpdated(
          targetUserId: targetUserId,
          honorPoints: honorPoints,
          fromUsername: fromUsername,
        ));
      }
    });
  }

  void _onMessageReceived(
    ChatMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final existingIndex =
        state.messages.indexWhere((m) => m.id == event.message.id);
    List<ChatMessageModel> updated;
    if (existingIndex >= 0) {
      final list = List.of(state.messages);
      list[existingIndex] = event.message;
      updated = list.map((m) => ChatMessageModel.fromEntity(m)).toList();
    } else {
      updated = [
        ...state.messages.map((m) => ChatMessageModel.fromEntity(m)),
        ChatMessageModel.fromEntity(event.message),
      ];
    }
    emit(state.copyWith(messages: updated));
    if (state.room != null) {
      chatRepository.cacheMessages(state.room!.id, updated);
    }
  }

  void _onMessageDeleted(
    ChatMessageDeleted event,
    Emitter<ChatState> emit,
  ) {
    final updated = state.messages.map((m) {
      if (m.id == event.messageId) {
        return m.copyWith(isDeleted: true);
      }
      return m;
    }).toList();

    emit(state.copyWith(messages: updated));
    if (state.room != null) {
      chatRepository.cacheMessages(state.room!.id, updated);
    }
  }

  void _onOnlineCountUpdated(
    ChatOnlineCountUpdated event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(onlineCount: event.count));
  }

  void _onTypingUpdated(
    ChatTypingUpdated event,
    Emitter<ChatState> emit,
  ) {
    final current = List<String>.from(state.typingUsers);
    if (event.isTyping) {
      if (!current.contains(event.username)) {
        current.add(event.username);
      }
    } else {
      current.remove(event.username);
    }
    emit(state.copyWith(typingUsers: current));
  }

  void _onSendMessageSubmitted(
    ChatSendMessageSubmitted event,
    Emitter<ChatState> emit,
  ) {
    chatRepository.sendMessage(event.content, replyToId: event.replyToId);
    emit(state.copyWith(replyTarget: () => null));
  }

  void _onTypingSubmitted(
    ChatTypingSubmitted event,
    Emitter<ChatState> emit,
  ) {
    chatRepository.sendTyping(event.isTyping);
  }

  void _onDeleteMessageSubmitted(
    ChatDeleteMessageSubmitted event,
    Emitter<ChatState> emit,
  ) {
    chatRepository.sendDeleteMessage(event.messageId);
  }

  void _onReplyTargetSelected(
    ChatReplyTargetSelected event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(replyTarget: () => event.replyTarget));
  }

  void _onGiveHonorRequested(
    ChatGiveHonorRequested event,
    Emitter<ChatState> emit,
  ) {
    chatRepository.sendGiveHonor(event.targetUserId);
  }

  void _onHonorUpdated(
    ChatHonorUpdated event,
    Emitter<ChatState> emit,
  ) {
    final updated = state.messages.map((m) {
      if (m.sender.id == event.targetUserId) {
        return m.copyWith(
          sender: m.sender.copyWith(honorPoints: event.honorPoints),
        );
      }
      return m;
    }).toList();

    emit(state.copyWith(messages: updated));
    if (state.room != null) {
      chatRepository.cacheMessages(state.room!.id, updated);
    }
  }

  void _onChatClosed(
    ChatClosed event,
    Emitter<ChatState> emit,
  ) {
    _wsSubscription?.cancel();
    chatRepository.disconnect();
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    chatRepository.disconnect();
    return super.close();
  }
}
