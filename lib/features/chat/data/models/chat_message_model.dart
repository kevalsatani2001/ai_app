import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_ai_app/core/config/app_config.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.role,
    required super.text,
    required super.timestamp,
  });

  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      role: entity.role,
      text: entity.text,
      timestamp: entity.timestamp,
    );
  }

  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      role: role,
      text: text,
      timestamp: timestamp,
    );
  }

  ChatMessageModel copyWithModel({
    String? id,
    String? role,
    String? text,
    DateTime? timestamp,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class ChatMessageAdapter extends TypeAdapter<ChatMessageModel> {
  @override
  final int typeId = AppConfig.chatMessageTypeId;

  @override
  ChatMessageModel read(BinaryReader reader) {
    final id = reader.readString();
    final role = reader.readString();
    final text = reader.readString();
    final timestamp = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    return ChatMessageModel(
      id: id,
      role: role,
      text: text,
      timestamp: timestamp,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessageModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.role);
    writer.writeString(obj.text);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
  }
}
