import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_ai_app/core/config/app_config.dart';
import 'package:my_ai_app/core/error/failures.dart';
import 'package:my_ai_app/features/chat/data/models/chat_message_model.dart';
import 'package:my_ai_app/features/chat/data/models/chat_session_model.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_session.dart';

class ChatLocalDataSource {
  ChatLocalDataSource({required Box<ChatSessionModel> sessionsBox})
      : _sessionsBox = sessionsBox;

  final Box<ChatSessionModel> _sessionsBox;

  Future<List<ChatSessionSummary>> fetchAllSessionSummaries() async {
    try {
      final summaries = _sessionsBox.values
          .map((s) => s.toSummary())
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return summaries;
    } catch (error) {
      throw CacheFailure('Failed to load chat sessions: $error');
    }
  }

  Future<ChatSession?> fetchSession(String chatId) async {
    try {
      final model = _sessionsBox.get(chatId);
      return model?.toEntity();
    } catch (error) {
      throw CacheFailure('Failed to load chat session: $error');
    }
  }

  Future<ChatSession> createSession({
    required String chatId,
    String title = AppConfig.defaultSessionTitle,
  }) async {
    try {
      final now = DateTime.now();
      final session = ChatSessionModel(
        chatId: chatId,
        title: title,
        createdAt: now,
        updatedAt: now,
        messages: const [],
      );
      await _sessionsBox.put(chatId, session);
      return session.toEntity();
    } catch (error) {
      throw CacheFailure('Failed to create chat session: $error');
    }
  }

  Future<void> saveSession(ChatSession session) async {
    try {
      await _sessionsBox.put(
        session.chatId,
        ChatSessionModel.fromEntity(session),
      );
    } catch (error) {
      throw CacheFailure('Failed to save chat session: $error');
    }
  }

  Future<void> saveMessage({
    required String chatId,
    required ChatMessage message,
    String? titleOverride,
  }) async {
    if (message.isModel && message.text.trim().isEmpty) {
      return;
    }

    try {
      final existing = _sessionsBox.get(chatId);
      if (existing == null) {
        throw CacheFailure('Chat session $chatId not found.');
      }

      final messages = List<ChatMessageModel>.from(
        existing.messages.cast<ChatMessageModel>(),
      );

      final index = messages.indexWhere((m) => m.id == message.id);
      if (index >= 0) {
        messages[index] = ChatMessageModel.fromEntity(message);
      } else {
        messages.add(ChatMessageModel.fromEntity(message));
      }

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final cleaned = messages
          .where((m) => !(m.isModel && m.text.trim().isEmpty))
          .toList();

      var title = existing.title;
      if (titleOverride != null && titleOverride.isNotEmpty) {
        title = titleOverride;
      }

      final updated = ChatSessionModel(
        chatId: chatId,
        title: title,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
        messages: cleaned,
      );

      await _sessionsBox.put(chatId, updated);
    } catch (error) {
      if (error is Failure) {
        rethrow;
      }
      throw CacheFailure('Failed to save message: $error');
    }
  }

  Future<void> deleteSession(String chatId) async {
    try {
      await _sessionsBox.delete(chatId);
    } catch (error) {
      throw CacheFailure('Failed to delete chat session: $error');
    }
  }

  Future<void> clearAllSessions() async {
    try {
      await _sessionsBox.clear();
    } catch (error) {
      throw CacheFailure('Failed to clear sessions: $error');
    }
  }

  static Future<Box<ChatSessionModel>> openBox() async {
    try {
      if (!Hive.isBoxOpen(AppConfig.hiveSessionsBoxName)) {
        return Hive.openBox<ChatSessionModel>(AppConfig.hiveSessionsBoxName);
      }
      return Hive.box<ChatSessionModel>(AppConfig.hiveSessionsBoxName);
    } catch (error) {
      throw CacheFailure('Failed to open Hive sessions box: $error');
    }
  }
}
