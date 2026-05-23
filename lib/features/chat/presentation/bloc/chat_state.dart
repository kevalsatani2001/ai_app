import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_session.dart';

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
    required this.activeChatId,
    required this.sessionTitle,
    required this.messages,
    this.sessions = const [],
    this.selectedFiles = const [],
    this.isStreaming = false,
    this.errorMessage,
    this.streamingMessageId,
  });

  final String activeChatId;
  final String sessionTitle;
  final List<ChatSessionSummary> sessions;
  final List<ChatMessage> messages;
  final List<File> selectedFiles;
  final bool isStreaming;
  final String? errorMessage;
  final String? streamingMessageId;

  ChatStateActive copyWith({
    String? activeChatId,
    String? sessionTitle,
    List<ChatSessionSummary>? sessions,
    List<ChatMessage>? messages,
    List<File>? selectedFiles,
    bool? isStreaming,
    String? errorMessage,
    String? streamingMessageId,
    bool clearError = false,
    bool clearSelectedFiles = false,
    bool clearStreamingMessageId = false,
  }) {
    return ChatStateActive(
      activeChatId: activeChatId ?? this.activeChatId,
      sessionTitle: sessionTitle ?? this.sessionTitle,
      sessions: sessions ?? this.sessions,
      messages: messages ?? this.messages,
      selectedFiles:
          clearSelectedFiles ? const [] : selectedFiles ?? this.selectedFiles,
      isStreaming: isStreaming ?? this.isStreaming,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      streamingMessageId: clearStreamingMessageId
          ? null
          : streamingMessageId ?? this.streamingMessageId,
    );
  }

  @override
  List<Object?> get props => [
        activeChatId,
        sessionTitle,
        sessions,
        messages,
        selectedFiles,
        isStreaming,
        errorMessage,
        streamingMessageId,
      ];
}
