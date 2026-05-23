import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_session.dart';

abstract class ChatRepository {
  Future<List<ChatSessionSummary>> fetchAllSessions();

  Future<ChatSession> createSession({required String chatId});

  Future<ChatSession?> loadSession(String chatId);

  Future<void> saveMessage({
    required String chatId,
    required ChatMessage message,
    String? titleOverride,
  });

  Future<void> deleteSession(String chatId);

  Future<void> clearAllSessions();

  Stream<String> sendMultimodalStream({
    required String prompt,
    required List<ChatMessage> history,
    required List<String> attachmentPaths,
  });
}
