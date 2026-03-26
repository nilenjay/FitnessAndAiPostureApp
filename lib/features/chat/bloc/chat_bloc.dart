import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../data/chat_message_model.dart';
import '../data/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;
  final _uuid = const Uuid();

  ChatBloc({required ChatRepository repository})
      : _repository = repository,
        super(const ChatLoaded(messages: [], isTyping: false)) {
    on<ChatSendMessage>(_onSendMessage);
    on<ChatClearHistory>(_onClearHistory);
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final current = state as ChatLoaded;

    // Add user message
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: event.message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...current.messages, userMsg];
    emit(ChatLoaded(messages: updatedMessages, isTyping: true));

    try {
      // Build conversation history for the API
      final history = updatedMessages
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      final reply = await _repository.sendMessage(
        conversationHistory: history,
      );

      final aiMsg = ChatMessage(
        id: _uuid.v4(),
        content: reply,
        isUser: false,
        timestamp: DateTime.now(),
      );

      emit(ChatLoaded(
        messages: [...updatedMessages, aiMsg],
        isTyping: false,
      ));
    } catch (e) {
      final errorMsg = ChatMessage(
        id: _uuid.v4(),
        content: 'Sorry, something went wrong. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      emit(ChatLoaded(
        messages: [...updatedMessages, errorMsg],
        isTyping: false,
      ));
    }
  }

  void _onClearHistory(
    ChatClearHistory event,
    Emitter<ChatState> emit,
  ) {
    emit(const ChatLoaded(messages: [], isTyping: false));
  }
}
