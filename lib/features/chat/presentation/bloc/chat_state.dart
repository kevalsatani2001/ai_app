import 'package:equatable/equatable.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';

sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

final class ChatInitial extends ChatState {
  const ChatInitial();
}

final class ChatHistoryLoading extends ChatState {
  const ChatHistoryLoading();
}

final class ChatStateActive extends ChatState {
  const ChatStateActive({
    required this.messages,
    this.isStreaming = false,
    this.errorMessage,
    this.streamingMessageId,
  });

  final List<ChatMessage> messages;
  final bool isStreaming;
  final String? errorMessage;
  final String? streamingMessageId;

  ChatStateActive copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    String? errorMessage,
    String? streamingMessageId,
    bool clearError = false,
    bool clearStreamingMessageId = false,
  }) {
    return ChatStateActive(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      streamingMessageId: clearStreamingMessageId
          ? null
          : streamingMessageId ?? this.streamingMessageId,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        isStreaming,
        errorMessage,
        streamingMessageId,
      ];
}
