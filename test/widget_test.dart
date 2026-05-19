import 'package:flutter_test/flutter_test.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';

void main() {
  test('ChatMessage identifies user and model roles', () {
    final userMessage = ChatMessage(
      id: '1',
      role: 'user',
      text: 'Hello',
      timestamp: DateTime(2026, 5, 19),
    );

    expect(userMessage.isUser, isTrue);
    expect(userMessage.isModel, isFalse);
  });
}
