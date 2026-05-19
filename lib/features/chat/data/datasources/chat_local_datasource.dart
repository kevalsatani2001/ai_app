import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_ai_app/core/config/app_config.dart';
import 'package:my_ai_app/core/error/failures.dart';
import 'package:my_ai_app/features/chat/data/models/chat_message_model.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';

class ChatLocalDataSource {
  ChatLocalDataSource({required Box<ChatMessageModel> chatBox})
      : _chatBox = chatBox;

  final Box<ChatMessageModel> _chatBox;

  Future<List<ChatMessage>> fetchAllMessagesSorted() async {
    try {
      final messages = _chatBox.values.toList(growable: false)
        ..sort(
          (ChatMessageModel a, ChatMessageModel b) =>
              a.timestamp.compareTo(b.timestamp),
        );
      return messages.map((message) => message.toEntity()).toList();
    } catch (error) {
      throw CacheFailure('Failed to load chat history: $error');
    }
  }

  Future<void> saveMessage(ChatMessage message) async {
    try {
      await _chatBox.put(message.id, ChatMessageModel.fromEntity(message));
    } catch (error) {
      throw CacheFailure('Failed to save message: $error');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _chatBox.delete(messageId);
    } catch (error) {
      throw CacheFailure('Failed to delete message: $error');
    }
  }

  Future<void> clearAllMessages() async {
    try {
      await _chatBox.clear();
    } catch (error) {
      throw CacheFailure('Failed to clear chat history: $error');
    }
  }

  Future<bool> messageExists(String messageId) async {
    try {
      return _chatBox.containsKey(messageId);
    } catch (error) {
      throw CacheFailure('Failed to check message existence: $error');
    }
  }

  static Future<Box<ChatMessageModel>> openBox() async {
    try {
      if (!Hive.isBoxOpen(AppConfig.hiveChatBoxName)) {
        return Hive.openBox<ChatMessageModel>(AppConfig.hiveChatBoxName);
      }
      return Hive.box<ChatMessageModel>(AppConfig.hiveChatBoxName);
    } catch (error) {
      throw CacheFailure('Failed to open Hive chat box: $error');
    }
  }
}
