import 'package:equatable/equatable.dart';
import 'package:my_ai_app/features/chat/domain/entities/attachment_pick_type.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

final class LoadChatHistory extends ChatEvent {
  const LoadChatHistory();
}

/// [type] maps to image vs PDF picker (FileType.custom for PDF).
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

final class SendMultimodalPrompt extends ChatEvent {
  const SendMultimodalPrompt(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

final class ReceiveStreamChunk extends ChatEvent {
  const ReceiveStreamChunk(this.chunk);

  final String chunk;

  @override
  List<Object?> get props => [chunk];
}

final class ChatStreamError extends ChatEvent {
  const ChatStreamError(this.error);

  final String error;

  @override
  List<Object?> get props => [error];
}

final class ClearChatError extends ChatEvent {
  const ClearChatError();
}

final class ClearChatHistory extends ChatEvent {
  const ClearChatHistory();
}

final class StreamCompleted extends ChatEvent {
  const StreamCompleted();
}
