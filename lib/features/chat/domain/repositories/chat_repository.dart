import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';

abstract class ChatRepository {
  Future<List<ChatMessage>> loadChatHistory();

  Future<void> saveMessage(ChatMessage message);

  Future<void> clearChatHistory();

  Stream<String> sendMultimodalStream({
    required String prompt,
    required List<ChatMessage> history,
    required List<String> attachmentPaths,
  });
}
