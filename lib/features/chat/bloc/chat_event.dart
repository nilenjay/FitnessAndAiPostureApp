part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatSendMessage extends ChatEvent {
  final String message;

  ChatSendMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatClearHistory extends ChatEvent {}
