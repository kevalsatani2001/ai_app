import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final String role;
  final String text;
  final DateTime timestamp;

  bool get isUser => role == 'user';

  bool get isModel => role == 'model';

  ChatMessage copyWith({
    String? id,
    String? role,
    String? text,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [id, role, text, timestamp];
}
