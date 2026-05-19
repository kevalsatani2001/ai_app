import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_ai_app/core/theme/app_theme.dart';
import 'package:shimmer/shimmer.dart';

class StreamingShimmerBubble extends StatelessWidget {
  const StreamingShimmerBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 64, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.modelBubbleColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
          ),
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.white12,
          highlightColor: Colors.white24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerLine(width: 180),
              const SizedBox(height: 8),
              _shimmerLine(width: 140),
              const SizedBox(height: 8),
              _shimmerLine(width: 96),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerLine({required double width}) {
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class TypingCursor extends StatelessWidget {
  const TypingCursor({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      '▍',
      style: GoogleFonts.inter(
        color: AppTheme.accentColor,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
