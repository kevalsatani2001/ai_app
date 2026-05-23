import 'package:equatable/equatable.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';

/// One conversation thread (ChatGPT / Gemini style).
class ChatSession extends Equatable {
  const ChatSession({
    required this.chatId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  final String chatId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  bool get isEmpty => messages.isEmpty;

  ChatSession copyWith({
    String? chatId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) {
    return ChatSession(
      chatId: chatId ?? this.chatId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object?> get props => [chatId, title, createdAt, updatedAt, messages];
}

/// Lightweight row for the history drawer (no message bodies).
class ChatSessionSummary extends Equatable {
  const ChatSessionSummary({
    required this.chatId,
    required this.title,
    required this.updatedAt,
  });

  final String chatId;
  final String title;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [chatId, title, updatedAt];
}
