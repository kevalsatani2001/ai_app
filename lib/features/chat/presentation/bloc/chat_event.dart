import 'package:equatable/equatable.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

final class LoadChatHistory extends ChatEvent {
  const LoadChatHistory();
}

final class SendPrompt extends ChatEvent {
  const SendPrompt(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

final class ReceiveStreamChunk extends ChatEvent {
  const ReceiveStreamChunk(this.chunk);

  final String chunk;

  @override
  List<Object?> get props => [chunk];
}

final class ChatStreamError extends ChatEvent {
  const ChatStreamError(this.error);

  final String error;

  @override
  List<Object?> get props => [error];
}

final class ClearChatError extends ChatEvent {
  const ClearChatError();
}

final class ClearChatHistory extends ChatEvent {
  const ClearChatHistory();
}

final class StreamCompleted extends ChatEvent {
  const StreamCompleted();
}

final class StreamStarted extends ChatEvent {
  const StreamStarted({
    required this.userMessage,
    required this.modelMessageId,
  });

  final ChatMessage userMessage;
  final String modelMessageId;

  @override
  List<Object?> get props => [userMessage, modelMessageId];
}
