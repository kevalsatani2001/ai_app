import 'package:equatable/equatable.dart';
import 'package:my_ai_app/features/chat/domain/entities/attachment_pick_type.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Loads every session summary for the navigation drawer.
final class FetchAllSessions extends ChatEvent {
  const FetchAllSessions();
}

/// Starts a blank conversation (ChatGPT "New chat").
final class CreateNewChat extends ChatEvent {
  const CreateNewChat();
}

/// Switches the active thread and loads its messages from Hive.
final class LoadChatSession extends ChatEvent {
  const LoadChatSession(this.chatId);

  final String chatId;

  @override
  List<Object?> get props => [chatId];
}

final class PickAttachment extends ChatEvent {
  const PickAttachment(this.type);

  final AttachmentPickType type;

  @override
  List<Object?> get props => [type];
}

final class RemoveSelectedAttachment extends ChatEvent {
  const RemoveSelectedAttachment(this.filePath);

  final String filePath;

  @override
  List<Object?> get props => [filePath];
}

/// Sends text and/or attachments in the active session.
final class SendMessage extends ChatEvent {
  const SendMessage(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

final class ClearChatError extends ChatEvent {
  const ClearChatError();
}

/// Deletes the active session and opens a new empty chat.
final class DeleteActiveSession extends ChatEvent {
  const DeleteActiveSession();
}

final class ReceiveStreamChunk extends ChatEvent {
  const ReceiveStreamChunk(this.chunk);

  final String chunk;

  @override
  List<Object?> get props => [chunk];
}
