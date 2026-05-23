import 'package:my_ai_app/core/error/failures.dart';
import 'package:my_ai_app/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:my_ai_app/features/chat/data/datasources/gemini_remote_service.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_session.dart';
import 'package:my_ai_app/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required ChatLocalDataSource localDataSource,
    required GeminiRemoteService remoteService,
  })  : _local = localDataSource,
        _remote = remoteService;

  final ChatLocalDataSource _local;
  final GeminiRemoteService _remote;

  @override
  Future<List<ChatSessionSummary>> fetchAllSessions() =>
      _local.fetchAllSessionSummaries();

  @override
  Future<ChatSession> createSession({required String chatId}) =>
      _local.createSession(chatId: chatId);

  @override
  Future<ChatSession?> loadSession(String chatId) =>
      _local.fetchSession(chatId);

  @override
  Future<void> saveMessage({
    required String chatId,
    required ChatMessage message,
    String? titleOverride,
  }) =>
      _local.saveMessage(
        chatId: chatId,
        message: message,
        titleOverride: titleOverride,
      );

  @override
  Future<void> deleteSession(String chatId) => _local.deleteSession(chatId);

  @override
  Future<void> clearAllSessions() => _local.clearAllSessions();

  @override
  Stream<String> sendMultimodalStream({
    required String prompt,
    required List<ChatMessage> history,
    required List<String> attachmentPaths,
  }) {
    try {
      _remote.initializeSession(history);
      return _remote.sendMessageStream(
        prompt: prompt,
        attachmentPaths: attachmentPaths,
      );
    } catch (error) {
      if (error is Failure) {
        return Stream<String>.error(error);
      }
      return Stream<String>.error(UnknownFailure('$error'));
    }
  }
}
