import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_ai_app/core/theme/app_theme.dart';

class MarkdownMessageBody extends StatelessWidget {
  const MarkdownMessageBody({
    super.key,
    required this.data,
    this.isStreaming = false,
  });

  final String data;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final displayData = data.isEmpty && isStreaming ? '...' : data;

    return MarkdownBody(
      data: displayData,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 15,
          height: 1.5,
        ),
        h1: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        h2: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
        h3: GoogleFonts.inter(
          color: AppTheme.accentColor,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        strong: GoogleFonts.inter(
          color: const Color(0xFFE9D5FF),
          fontWeight: FontWeight.w700,
        ),
        em: GoogleFonts.inter(
          color: const Color(0xFFBFDBFE),
          fontStyle: FontStyle.italic,
        ),
        a: GoogleFonts.inter(
          color: AppTheme.accentColor,
          decoration: TextDecoration.underline,
        ),
        blockquote: GoogleFonts.inter(
          color: Colors.white70,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: AppTheme.accentColor, width: 3),
          ),
        ),
        code: GoogleFonts.jetBrainsMono(
          color: const Color(0xFF86EFAC),
          fontSize: 13,
          backgroundColor: Colors.transparent,
        ),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.accentColor.withValues(alpha: 0.25),
          ),
        ),
        codeblockPadding: const EdgeInsets.all(14),
        tableHead: GoogleFonts.inter(
          color: AppTheme.accentColor,
          fontWeight: FontWeight.w700,
        ),
        tableBody: GoogleFonts.inter(color: Colors.white),
        tableBorder: TableBorder.all(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(8),
        ),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        listBullet: GoogleFonts.inter(color: AppTheme.accentColor),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
        ),
      ),
    );
  }
}
