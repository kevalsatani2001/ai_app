import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_ai_app/core/config/app_config.dart';
import 'package:my_ai_app/features/chat/data/models/chat_message_model.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_session.dart';

class ChatSessionModel extends ChatSession {
  const ChatSessionModel({
    required super.chatId,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    super.messages = const [],
  });

  factory ChatSessionModel.fromEntity(ChatSession entity) {
    return ChatSessionModel(
      chatId: entity.chatId,
      title: entity.title,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      messages: entity.messages
          .map((m) => ChatMessageModel.fromEntity(m))
          .toList(),
    );
  }

  ChatSession toEntity() {
    return ChatSession(
      chatId: chatId,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      messages: messages
          .map(
            (m) => m is ChatMessageModel ? m.toEntity() : m,
          )
          .toList(),
    );
  }

  ChatSessionSummary toSummary() {
    return ChatSessionSummary(
      chatId: chatId,
      title: title,
      updatedAt: updatedAt,
    );
  }
}

class ChatSessionAdapter extends TypeAdapter<ChatSessionModel> {
  @override
  final int typeId = AppConfig.chatSessionTypeId;

  @override
  ChatSessionModel read(BinaryReader reader) {
    final chatId = reader.readString();
    final title = reader.readString();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final messageCount = reader.readInt();
    final messages = <ChatMessageModel>[];

    for (var i = 0; i < messageCount; i++) {
      messages.add(_readMessage(reader));
    }

    return ChatSessionModel(
      chatId: chatId,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      messages: messages,
    );
  }

  ChatMessageModel _readMessage(BinaryReader reader) {
    final id = reader.readString();
    final role = reader.readString();
    final text = reader.readString();
    final timestamp = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final mediaCount = reader.readInt();
    final mediaPaths = List<String>.generate(
      mediaCount,
      (_) => reader.readString(),
    );

    return ChatMessageModel(
      id: id,
      role: role,
      text: text,
      timestamp: timestamp,
      mediaPaths: mediaPaths,
    );
  }

  void _writeMessage(BinaryWriter writer, ChatMessageModel message) {
    writer.writeString(message.id);
    writer.writeString(message.role);
    writer.writeString(message.text);
    writer.writeInt(message.timestamp.millisecondsSinceEpoch);
    writer.writeInt(message.mediaPaths.length);
    for (final path in message.mediaPaths) {
      writer.writeString(path);
    }
  }

  @override
  void write(BinaryWriter writer, ChatSessionModel obj) {
    writer.writeString(obj.chatId);
    writer.writeString(obj.title);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
    writer.writeInt(obj.messages.length);
    for (final message in obj.messages) {
      _writeMessage(writer, message as ChatMessageModel);
    }
  }
}
