part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;

  const ChatLoaded({required this.messages, required this.isTyping});

  @override
  List<Object?> get props => [messages, isTyping];
}
