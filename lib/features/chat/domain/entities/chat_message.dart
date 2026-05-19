import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.mediaPaths = const [],
  });

  final String id;
  final String role;
  final String text;
  final DateTime timestamp;
  final List<String> mediaPaths;

  bool get isUser => role == 'user';

  bool get isModel => role == 'model';

  bool get hasMedia => mediaPaths.isNotEmpty;

  ChatMessage copyWith({
    String? id,
    String? role,
    String? text,
    DateTime? timestamp,
    List<String>? mediaPaths,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      mediaPaths: mediaPaths ?? this.mediaPaths,
    );
  }

  @override
  List<Object?> get props => [id, role, text, timestamp, mediaPaths];
}
