class AppConfig {
  AppConfig._();

  static const String geminiModel = 'gemini-2.5-flash';

  /// New box for multimodal messages (avoids corrupting old text-only data).
  static const String hiveChatBoxName = 'chat_multimodal_v1';

  static const int chatMessageTypeId = 1;

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
