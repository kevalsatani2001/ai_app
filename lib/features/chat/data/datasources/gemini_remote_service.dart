import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:my_ai_app/core/config/app_config.dart';
import 'package:my_ai_app/core/error/failures.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';

/// Gemini chat via REST `streamGenerateContent`.
///
/// The deprecated `google_generative_ai` SDK cannot parse some
/// `gemini-2.5-flash` stream chunks that only contain `{role: model}` without
/// `parts`, which triggers "Unhandled format for Content".
class GeminiRemoteService {
  GeminiRemoteService({
    required String apiKey,
    String modelName = AppConfig.geminiModel,
    Duration streamTimeout = const Duration(seconds: 90),
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _modelName = modelName,
        _streamTimeout = streamTimeout,
        _httpClient = httpClient ?? http.Client();

  final String _apiKey;
  final String _modelName;
  final Duration _streamTimeout;
  final http.Client _httpClient;

  List<ChatMessage> _sessionHistory = const [];

  static final Uri _baseUri = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta',
  );

  /// Equivalent to `_model.startChat(history: ...)` — stores prior turns only.
  void initializeSession(List<ChatMessage> history) {
    _sessionHistory = List<ChatMessage>.unmodifiable(
      history.where((message) => message.text.trim().isNotEmpty).toList(),
    );
  }

  /// Equivalent to `chat.sendMessageStream` for the latest user prompt.
  Stream<String> sendMessageStream(String prompt) {
    final controller = StreamController<String>();
    final contents = _buildRequestContents(prompt);

    Future<void> runStream() async {
      final uri = _baseUri.replace(
        path:
            '/v1beta/models/$_modelName:streamGenerateContent',
        queryParameters: const {'alt': 'sse'},
      );

      final request = http.Request('POST', uri)
        ..headers.addAll({
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey,
        })
        ..body = jsonEncode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.8,
            'topP': 0.95,
            'maxOutputTokens': 8192,
          },
        });

      try {
        final streamedResponse = await _httpClient
            .send(request)
            .timeout(_streamTimeout);

        if (streamedResponse.statusCode != 200) {
          final body = await streamedResponse.stream.bytesToString();
          throw _mapHttpError(streamedResponse.statusCode, body);
        }

        final buffer = StringBuffer();
        await for (final line
            in streamedResponse.stream.transform(utf8.decoder).transform(
                  const LineSplitter(),
                )) {
          final chunkText = _extractTextFromSseLine(line);
          if (chunkText != null && chunkText.isNotEmpty) {
            buffer.write(chunkText);
            controller.add(chunkText);
          }
        }

        if (!controller.isClosed) {
          await controller.close();
        }
      } catch (error) {
        if (!controller.isClosed) {
          controller.addError(_mapException(error));
          await controller.close();
        }
      }
    }

    unawaited(runStream());
    return controller.stream;
  }

  List<Map<String, Object?>> _buildRequestContents(String prompt) {
    final contents = <Map<String, Object?>>[];

    for (final message in _sessionHistory) {
      contents.add(_messageToContentMap(message));
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': prompt},
      ],
    });

    return contents;
  }

  Map<String, Object?> _messageToContentMap(ChatMessage message) {
    return {
      'role': message.isUser ? 'user' : 'model',
      'parts': [
        {'text': message.text},
      ],
    };
  }

  String? _extractTextFromSseLine(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('data:')) {
      return null;
    }

    final payload = trimmed.substring(5).trim();
    if (payload.isEmpty || payload == '[DONE]') {
      return null;
    }

    try {
      final decoded = jsonDecode(payload);
      return _extractTextFromResponse(decoded);
    } catch (_) {
      return null;
    }
  }

  String? _extractTextFromResponse(Object? decoded) {
    if (decoded is! Map) {
      return null;
    }

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return null;
    }

    final firstCandidate = candidates.first;
    if (firstCandidate is! Map) {
      return null;
    }

    final content = firstCandidate['content'];
    if (content is! Map) {
      return null;
    }

    final parts = content['parts'];
    if (parts is! List) {
      return null;
    }

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is! Map) {
        continue;
      }
      final text = part['text'];
      if (text is String && text.isNotEmpty) {
        buffer.write(text);
      }
    }

    return buffer.isEmpty ? null : buffer.toString();
  }

  Failure _mapHttpError(int statusCode, String body) {
    final lowerBody = body.toLowerCase();

    if (statusCode == 429 ||
        lowerBody.contains('quota') ||
        lowerBody.contains('rate limit')) {
      return const RateLimitFailure(
        'API rate limit reached. Please wait a moment and try again.',
      );
    }

    if (statusCode == 401 || statusCode == 403) {
      return const ApiFailure(
        'Invalid or unauthorized API key. Verify your Gemini credentials.',
      );
    }

    if (statusCode == 408 || lowerBody.contains('timeout')) {
      return const TimeoutFailure(
        'The request timed out before Gemini could respond.',
      );
    }

    if (statusCode >= 500) {
      return const ApiFailure(
        'Gemini service is temporarily unavailable. Try again shortly.',
      );
    }

    return ApiFailure('Gemini API error ($statusCode): $body');
  }

  Failure _mapException(Object error) {
    if (error is Failure) {
      return error;
    }

    final message = error.toString().toLowerCase();

    if (error is TimeoutException ||
        message.contains('timeout') ||
        message.contains('deadline')) {
      return const TimeoutFailure(
        'Gemini response timed out. Please try again.',
      );
    }

    if (error is SocketException ||
        message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection') ||
        message.contains('failed host lookup')) {
      return const NetworkFailure(
        'Network connection lost. Check your internet and retry.',
      );
    }

    return UnknownFailure('Unexpected Gemini error: $error');
  }

  void dispose() {
    _httpClient.close();
    _sessionHistory = const [];
  }
}
