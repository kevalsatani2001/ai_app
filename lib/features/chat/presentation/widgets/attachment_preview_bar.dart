import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_ai_app/core/services/attachment_storage_service.dart';
import 'package:my_ai_app/core/theme/app_theme.dart';
import 'package:path/path.dart' as p;

class AttachmentPreviewBar extends StatelessWidget {
  const AttachmentPreviewBar({
    super.key,
    required this.files,
    required this.onRemove,
  });

  final List<File> files;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 108,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.85),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: files.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final file = files[index];
          final path = file.path;

          if (AttachmentStorageService.isImagePath(path)) {
            return _ImagePreviewTile(
              file: file,
              onRemove: () => onRemove(path),
            );
          }

          return _PdfPreviewTile(
            fileName: p.basename(path),
            onRemove: () => onRemove(path),
          );
        },
      ),
    );
  }
}

class _ImagePreviewTile extends StatelessWidget {
  const _ImagePreviewTile({
    required this.file,
    required this.onRemove,
  });

  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.4)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.file(file, fit: BoxFit.cover),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: _RemoveBadge(onTap: onRemove),
        ),
      ],
    );
  }
}

class _PdfPreviewTile extends StatelessWidget {
  const _PdfPreviewTile({
    required this.fileName,
    required this.onRemove,
  });

  final String fileName;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 120,
          height: 88,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.scaffoldBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.picture_as_pdf_rounded,
                color: Color(0xFFF87171),
                size: 28,
              ),
              const Spacer(),
              Text(
                fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: _RemoveBadge(onTap: onRemove),
        ),
      ],
    );
  }
}

class _RemoveBadge extends StatelessWidget {
  const _RemoveBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 6,
            ),
          ],
        ),
        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
      ),
    );
  }
}
