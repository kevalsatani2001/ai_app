import 'dart:convert';
import 'dart:typed_data';

/// Multimodal content types aligned with the official Google GenAI SDK surface.
///
/// The `google_genai` pub package is still a placeholder; this module provides
/// the same API shape and is consumed by [GeminiRemoteService].

abstract class GenAiPart {
  Map<String, Object?> toJsonPart();
}

final class GenAiTextPart implements GenAiPart {
  GenAiTextPart(this.text);

  final String text;

  @override
  Map<String, Object?> toJsonPart() => {'text': text};
}

final class GenAiDataPart implements GenAiPart {
  GenAiDataPart({
    required this.mimeType,
    required this.bytes,
  });

  final String mimeType;
  final Uint8List bytes;

  @override
  Map<String, Object?> toJsonPart() => {
        'inlineData': {
          'mimeType': mimeType,
          'data': GenAiData.encodeBase64(bytes),
        },
      };
}

final class GenAiContent {
  GenAiContent({
    required this.role,
    required this.parts,
  });

  final String role;
  final List<GenAiPart> parts;

  factory GenAiContent.text(String text, {String role = 'user'}) {
    return GenAiContent(
      role: role,
      parts: [GenAiTextPart(text)],
    );
  }

  factory GenAiContent.multi(List<GenAiPart> parts, {String role = 'user'}) {
    return GenAiContent(role: role, parts: parts);
  }

  factory GenAiContent.modelText(String text) {
    return GenAiContent(
      role: 'model',
      parts: [GenAiTextPart(text)],
    );
  }

  Map<String, Object?> toJson() => {
        'role': role,
        'parts': parts.map((part) => part.toJsonPart()).toList(),
      };
}

/// MIME helpers matching `Data.mime(...)` from the GenAI SDK.
final class GenAiData {
  GenAiData._();

  static GenAiDataPart mime(String mimeType, Uint8List bytes) {
    return GenAiDataPart(mimeType: mimeType, bytes: bytes);
  }

  static GenAiDataPart image(Uint8List bytes, {String mimeType = 'image/jpeg'}) {
    return GenAiDataPart(mimeType: mimeType, bytes: bytes);
  }

  static GenAiDataPart pdf(Uint8List bytes) {
    return GenAiDataPart(mimeType: 'application/pdf', bytes: bytes);
  }

  static String encodeBase64(Uint8List bytes) => base64Encode(bytes);
}
