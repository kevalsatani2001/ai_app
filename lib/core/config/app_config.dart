class AppConfig {
  AppConfig._();

  static const String geminiModel = 'gemini-2.5-flash';

  /// Multi-chat sessions (each session holds its message list).
  static const String hiveSessionsBoxName = 'chat_sessions_v1';

  static const int chatMessageTypeId = 1;
  static const int chatSessionTypeId = 2;

  static const String defaultSessionTitle = 'New chat';
  static const int sessionTitleMaxLength = 48;

  static const int maxAttachmentBytes = 20 * 1024 * 1024;

  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'heic',
  ];

  static const List<String> allowedPdfExtensions = ['pdf'];

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'GEMINI_API_KEY',
  );
}
