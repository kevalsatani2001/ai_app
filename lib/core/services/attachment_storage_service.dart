import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:my_ai_app/core/config/app_config.dart';
import 'package:my_ai_app/core/error/failures.dart';
import 'package:my_ai_app/features/chat/domain/entities/attachment_pick_type.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AttachmentStorageService {
  AttachmentStorageService({
    ImagePicker? imagePicker,
    Uuid? uuid,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        _uuid = uuid ?? const Uuid();

  final ImagePicker _imagePicker;
  final Uuid _uuid;

  Future<List<File>> pickAttachments(AttachmentPickType type) async {
    try {
      return switch (type) {
        AttachmentPickType.image => await _pickImages(),
        AttachmentPickType.pdf => await _pickPdfs(),
      };
    } catch (error) {
      throw UnknownFailure('Failed to pick attachment: $error');
    }
  }

  Future<List<File>> _pickImages() async {
    final picked = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) {
      return const [];
    }

    final stored = <File>[];
    for (final xfile in picked) {
      stored.add(await persistFile(File(xfile.path)));
    }
    return stored;
  }

  Future<List<File>> _pickPdfs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConfig.allowedPdfExtensions,
      allowMultiple: true,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return const [];
    }

    final stored = <File>[];
    for (final platformFile in result.files) {
      final path = platformFile.path;
      if (path == null) {
        continue;
      }
      stored.add(await persistFile(File(path)));
    }
    return stored;
  }

  Future<File> persistFile(File source) async {
    await _validateFile(source);

    final attachmentsDir = await _attachmentsDirectory();
    final extension = p.extension(source.path).toLowerCase();
    final fileName = '${_uuid.v4()}$extension';
    final destination = File(p.join(attachmentsDir.path, fileName));

    return source.copy(destination.path);
  }

  Future<void> _validateFile(File file) async {
    if (!await file.exists()) {
      throw const UnknownFailure('Selected file no longer exists.');
    }

    final size = await file.length();
    if (size > AppConfig.maxAttachmentBytes) {
      throw UnknownFailure(
        'File exceeds ${AppConfig.maxAttachmentBytes ~/ (1024 * 1024)} MB limit.',
      );
    }

    final extension = p.extension(file.path).toLowerCase().replaceFirst('.', '');
    final isImage = AppConfig.allowedImageExtensions.contains(extension);
    final isPdf = AppConfig.allowedPdfExtensions.contains(extension);

    if (!isImage && !isPdf) {
      throw const UnknownFailure(
        'Unsupported file type. Use images (JPG, PNG, WEBP) or PDF.',
      );
    }
  }

  Future<Directory> _attachmentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'chat_attachments'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String mimeTypeForPath(String path) {
    return lookupMimeType(path) ??
        (path.toLowerCase().endsWith('.pdf')
            ? 'application/pdf'
            : 'application/octet-stream');
  }

  static bool isImagePath(String path) {
    final mime = mimeTypeForPath(path);
    return mime.startsWith('image/');
  }

  static bool isPdfPath(String path) {
    return mimeTypeForPath(path) == 'application/pdf' ||
        path.toLowerCase().endsWith('.pdf');
  }
}
