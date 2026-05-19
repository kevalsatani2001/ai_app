import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_ai_app/core/services/attachment_storage_service.dart';
import 'package:my_ai_app/core/theme/app_theme.dart';
import 'package:path/path.dart' as p;

class MessageMediaAttachments extends StatelessWidget {
  const MessageMediaAttachments({
    super.key,
    required this.mediaPaths,
    required this.isUserBubble,
  });

  final List<String> mediaPaths;
  final bool isUserBubble;

  @override
  Widget build(BuildContext context) {
    if (mediaPaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: mediaPaths.map((path) {
        if (AttachmentStorageService.isImagePath(path)) {
          return _ImageAttachment(path: path);
        }
        return _PdfAttachmentCard(
          fileName: p.basename(path),
          isUserBubble: isUserBubble,
        );
      }).toList(),
    );
  }
}

class _ImageAttachment extends StatelessWidget {
  const _ImageAttachment({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxHeight: 220, maxWidth: 260),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.file(
        file,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _PdfAttachmentCard extends StatelessWidget {
  const _PdfAttachmentCard({
    required this.fileName,
    required this.isUserBubble,
  });

  final String fileName;
  final bool isUserBubble;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isUserBubble
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUserBubble
              ? Colors.white30
              : AppTheme.accentColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Color(0xFFF87171),
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PDF Document',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
