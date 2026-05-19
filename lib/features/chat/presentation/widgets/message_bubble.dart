import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:my_ai_app/core/theme/app_theme.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';
import 'package:my_ai_app/features/chat/presentation/widgets/markdown_message_body.dart';
import 'package:my_ai_app/features/chat/presentation/widgets/message_media_attachments.dart';
import 'package:my_ai_app/features/chat/presentation/widgets/streaming_shimmer_bubble.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isStreaming,
    required this.showShimmer,
  });

  final ChatMessage message;
  final bool isStreaming;
  final bool showShimmer;

  @override
  Widget build(BuildContext context) {
    if (showShimmer) {
      return const StreamingShimmerBubble();
    }

    final isUser = message.isUser;
    final timeLabel = DateFormat('h:mm a').format(message.timestamp);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isUser ? 48 : 16,
          right: isUser ? 16 : 48,
          bottom: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [
                    AppTheme.userGradientStart,
                    AppTheme.userGradientEnd,
                  ],
                )
              : null,
          color: isUser ? null : AppTheme.modelBubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.hasMedia)
              MessageMediaAttachments(
                mediaPaths: message.mediaPaths,
                isUserBubble: isUser,
              ),
            if (isUser && message.text.trim().isNotEmpty)
              SelectableText(
                message.text,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.45,
                ),
              )
            else if (!isUser && message.text.trim().isNotEmpty)
              MarkdownMessageBody(
                key: ValueKey('md_${message.id}_${message.text.length}'),
                data: message.text,
                isStreaming: isStreaming,
              )
            else if (isStreaming)
              Text(
                '...',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 15),
              ),
            if (isStreaming && !isUser && message.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: TypingCursor(),
              ),
            const SizedBox(height: 6),
            Text(
              timeLabel,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
