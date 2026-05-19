import 'package:my_ai_app/core/error/failures.dart';
import 'package:my_ai_app/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:my_ai_app/features/chat/data/datasources/gemini_remote_service.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';
import 'package:my_ai_app/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required ChatLocalDataSource localDataSource,
    required GeminiRemoteService remoteService,
  })  : _localDataSource = localDataSource,
        _remoteService = remoteService;

  final ChatLocalDataSource _localDataSource;
  final GeminiRemoteService _remoteService;

  @override
  Future<List<ChatMessage>> loadChatHistory() {
    return _localDataSource.fetchAllMessagesSorted();
  }

  @override
  Future<void> saveMessage(ChatMessage message) {
    return _localDataSource.saveMessage(message);
  }

  @override
  Future<void> clearChatHistory() {
    return _localDataSource.clearAllMessages();
  }

  @override
  Stream<String> sendPromptStream(
    String prompt,
    List<ChatMessage> history,
  ) {
    try {
      _remoteService.initializeSession(history);
      return _remoteService.sendMessageStream(prompt);
    } catch (error) {
      if (error is Failure) {
        return Stream<String>.error(error);
      }
      return Stream<String>.error(
        UnknownFailure('Failed to start Gemini stream: $error'),
      );
    }
  }
}
