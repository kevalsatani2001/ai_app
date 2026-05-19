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
      final staleIds = <String>[];
      final messages = <ChatMessageModel>[];

      for (final message in _chatBox.values) {
        if (message.isModel && message.text.trim().isEmpty) {
          staleIds.add(message.id);
          continue;
        }
        messages.add(message);
      }

      for (final id in staleIds) {
        await _chatBox.delete(id);
      }

      messages.sort(
        (a, b) => a.timestamp.compareTo(b.timestamp),
      );

      return messages.map((m) => m.toEntity()).toList();
    } catch (error) {
      throw CacheFailure('Failed to load chat history: $error');
    }
  }

  Future<void> saveMessage(ChatMessage message) async {
    if (message.isModel && message.text.trim().isEmpty) {
      return;
    }

    try {
      await _chatBox.put(message.id, ChatMessageModel.fromEntity(message));
    } catch (error) {
      throw CacheFailure('Failed to save message: $error');
    }
  }

  Future<void> clearAllMessages() async {
    try {
      await _chatBox.clear();
    } catch (error) {
      throw CacheFailure('Failed to clear chat history: $error');
    }
  }

  static Future<Box<ChatMessageModel>> openBox() async {
    try {
      if (!Hive.isBoxOpen(AppConfig.hiveChatBoxName)) {
        return Hive.openBox<ChatMessageModel>(AppConfig.hiveChatBoxName);
      }
      return Hive.box<ChatMessageModel>(AppConfig.hiveChatBoxName);
    } catch (error) {
      throw CacheFailure('Failed to open Hive box: $error');
    }
  }
}
