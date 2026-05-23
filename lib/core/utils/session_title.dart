import 'package:my_ai_app/core/config/app_config.dart';

String deriveSessionTitle(String prompt) {
  final trimmed = prompt.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (trimmed.isEmpty) {
    return AppConfig.defaultSessionTitle;
  }

  if (trimmed.length <= AppConfig.sessionTitleMaxLength) {
    return trimmed;
  }

  return '${trimmed.substring(0, AppConfig.sessionTitleMaxLength).trim()}…';
}

bool isDefaultSessionTitle(String title) =>
    title.trim().isEmpty || title == AppConfig.defaultSessionTitle;
