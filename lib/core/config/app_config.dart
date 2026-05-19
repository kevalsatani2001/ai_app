class AppConfig {
  AppConfig._();

  static const String geminiModel = 'gemini-2.5-flash';

  static const String hiveChatBoxName = 'chat_messages_box';

  static const int chatMessageTypeId = 0;

  /// Prefer passing the key at build time:
  /// flutter run --dart-define=GEMINI_API_KEY=your_key
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyCU9qKHiLIpVJU_mcOkJs0RKAnWwRC8MVU',
  );
}
