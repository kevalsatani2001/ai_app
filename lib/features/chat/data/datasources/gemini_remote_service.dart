import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:my_ai_app/core/config/app_config.dart';
import 'package:my_ai_app/core/error/failures.dart';
import 'package:my_ai_app/core/genai/genai_content.dart';
import 'package:my_ai_app/core/services/attachment_storage_service.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';

/// Multimodal Gemini via REST SSE (same proven path as the working text chat).
/// Builds requests with [GenAiContent.multi] and [GenAiData.mime].
class GeminiRemoteService {
  GeminiRemoteService({
    required String apiKey,
    String modelName = AppConfig.geminiModel,
    Duration streamTimeout = const Duration(seconds: 120),
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

  void initializeSession(List<ChatMessage> history) {
    _sessionHistory = List<ChatMessage>.from(
      history.where((m) => m.text.trim().isNotEmpty || m.hasMedia),
    );
  }

  /// Equivalent to `chat.sendMessageStream` over REST SSE.
  Stream<String> sendMessageStream({
    required String prompt,
    List<String> attachmentPaths = const [],
  }) {
    final controller = StreamController<String>();

    Future<void> run() async {
      try {
        final contents = await _buildAllContents(
          prompt: prompt,
          attachmentPaths: attachmentPaths,
        );

        var received = false;

        await for (final delta in _streamContents(contents)) {
          received = true;
          controller.add(delta);
        }

        if (!received) {
          final full = await _generateContentOnce(contents);
          if (full.isEmpty) {
            throw const ApiFailure('Gemini returned an empty response.');
          }
          controller.add(full);
        }

        await controller.close();
      } catch (error) {
        if (!controller.isClosed) {
          controller.addError(_mapException(error));
          await controller.close();
        }
      }
    }

    unawaited(run());
    return controller.stream;
  }

  Stream<String> _streamContents(List<Map<String, Object?>> contents) async* {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$_modelName:streamGenerateContent?alt=sse&key=$_apiKey',
    );

    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.8,
          'topP': 0.95,
          'maxOutputTokens': 8192,
        },
      });

    final response = await _httpClient.send(request).timeout(_streamTimeout);

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw _mapHttpError(response.statusCode, body);
    }

    var lineBuffer = '';

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      lineBuffer += chunk;

      while (lineBuffer.contains('\n')) {
        final index = lineBuffer.indexOf('\n');
        final line = lineBuffer.substring(0, index).trim();
        lineBuffer = lineBuffer.substring(index + 1);

        if (line.isEmpty) {
          continue;
        }

        final text = _parseSseLine(line);
        if (text != null && text.isNotEmpty) {
          yield text;
        }
      }
    }

    final tail = lineBuffer.trim();
    if (tail.isNotEmpty) {
      final text = _parseSseLine(tail);
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }

  Future<String> _generateContentOnce(List<Map<String, Object?>> contents) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$_modelName:generateContent?key=$_apiKey',
    );

    final response = await _httpClient
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': contents,
            'generationConfig': {
              'temperature': 0.8,
              'topP': 0.95,
              'maxOutputTokens': 8192,
            },
          }),
        )
        .timeout(_streamTimeout);

    if (response.statusCode != 200) {
      throw _mapHttpError(response.statusCode, response.body);
    }

    final decoded = jsonDecode(response.body);
    return _extractTextFromResponse(decoded) ?? '';
  }

  Future<List<Map<String, Object?>>> _buildAllContents({
    required String prompt,
    required List<String> attachmentPaths,
  }) async {
    final contents = <Map<String, Object?>>[
      for (final message in _sessionHistory) await _historyToJson(message),
    ];

    contents.add(await _userTurnToJson(prompt: prompt, paths: attachmentPaths));
    return contents;
  }

  Future<Map<String, Object?>> _userTurnToJson({
    required String prompt,
    required List<String> paths,
  }) async {
    final parts = <GenAiPart>[];

    final trimmed = prompt.trim();
    if (trimmed.isNotEmpty) {
      parts.add(GenAiTextPart(trimmed));
    } else if (paths.isNotEmpty) {
      parts.add(
        GenAiTextPart(
          'Analyze the attached file(s) and respond in helpful detail.',
        ),
      );
    }

    for (final path in paths) {
      parts.add(await _fileToDataPart(path));
    }

    if (parts.isEmpty) {
      throw const UnknownFailure('Add text or an attachment.');
    }

    return GenAiContent.multi(parts).toJson();
  }

  Future<Map<String, Object?>> _historyToJson(ChatMessage message) async {
    if (message.isUser && message.hasMedia) {
      final parts = <GenAiPart>[];
      if (message.text.trim().isNotEmpty) {
        parts.add(GenAiTextPart(message.text));
      }
      for (final path in message.mediaPaths) {
        final file = File(path);
        if (file.existsSync()) {
          parts.add(await _fileToDataPart(path));
        }
      }
      if (parts.isEmpty) {
        return GenAiContent.text('[attachment]').toJson();
      }
      return GenAiContent.multi(parts).toJson();
    }

    if (message.isUser) {
      return GenAiContent.text(message.text).toJson();
    }

    return GenAiContent.modelText(message.text).toJson();
  }

  Future<GenAiDataPart> _fileToDataPart(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw UnknownFailure('File not found: $path');
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > AppConfig.maxAttachmentBytes) {
      throw UnknownFailure('File exceeds size limit.');
    }

    final mime = AttachmentStorageService.mimeTypeForPath(path);
    return GenAiData.mime(mime, bytes);
  }

  String? _parseSseLine(String line) {
    if (!line.startsWith('data:')) {
      return null;
    }

    final payload = line.substring(5).trim();
    if (payload.isEmpty || payload == '[DONE]') {
      return null;
    }

    try {
      return _extractTextFromResponse(jsonDecode(payload));
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

    final candidate = candidates.first;
    if (candidate is! Map) {
      return null;
    }

    final content = candidate['content'];
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
      if (part['thought'] == true) {
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
    final lower = body.toLowerCase();
    if (statusCode == 429 || lower.contains('quota')) {
      return const RateLimitFailure('Rate limit reached. Wait and retry.');
    }
    if (statusCode == 401 || statusCode == 403) {
      return const ApiFailure('Invalid API key.');
    }
    if (statusCode >= 500) {
      return const ApiFailure('Gemini server error. Try again.');
    }
    return ApiFailure('Gemini error ($statusCode): $body');
  }

  Failure _mapException(Object error) {
    if (error is Failure) {
      return error;
    }
    if (error is TimeoutException) {
      return const TimeoutFailure('Request timed out.');
    }
    if (error is SocketException) {
      return const NetworkFailure('No internet connection.');
    }
    return UnknownFailure('Gemini error: $error');
  }

  void dispose() {
    _httpClient.close();
  }
}
