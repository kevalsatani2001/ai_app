import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_ai_app/core/theme/app_theme.dart';
import 'package:my_ai_app/features/chat/domain/entities/attachment_pick_type.dart';
import 'package:my_ai_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:my_ai_app/features/chat/presentation/bloc/chat_event.dart';

class ChatInputPanel extends StatelessWidget {
  const ChatInputPanel({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isStreaming,
    required this.canSend,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isStreaming;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        decoration: BoxDecoration(
          color: AppTheme.scaffoldBackground.withValues(alpha: 0.96),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            PopupMenuButton<AttachmentPickType>(
              enabled: !isStreaming,
              tooltip: 'Attach',
              color: AppTheme.surfaceColor,
              icon: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: isStreaming ? Colors.white38 : AppTheme.accentColor,
                ),
              ),
              onSelected: (type) {
                context.read<ChatBloc>().add(PickAttachment(type));
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: AttachmentPickType.image,
                  child: Row(
                    children: [
                      const Icon(Icons.image_rounded,
                          color: AppTheme.accentColor),
                      const SizedBox(width: 10),
                      Text('Image', style: GoogleFonts.inter(color: Colors.white)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: AttachmentPickType.pdf,
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded,
                          color: Color(0xFFF87171)),
                      const SizedBox(width: 10),
                      Text('PDF', style: GoogleFonts.inter(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: !isStreaming,
                minLines: 1,
                maxLines: 6,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Message, image, or PDF...',
                ),
                onSubmitted: (_) {
                  if (canSend) {
                    onSend();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: canSend
                    ? const LinearGradient(
                        colors: [
                          AppTheme.userGradientStart,
                          AppTheme.userGradientEnd,
                        ],
                      )
                    : null,
                color: canSend ? null : AppTheme.surfaceColor,
                shape: BoxShape.circle,
                boxShadow: canSend
                    ? [
                        BoxShadow(
                          color: AppTheme.accentColor.withValues(alpha: 0.4),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
              child: IconButton(
                onPressed: canSend ? onSend : null,
                icon: Icon(
                  isStreaming
                      ? Icons.hourglass_top_rounded
                      : Icons.arrow_upward_rounded,
                  color: canSend ? Colors.white : Colors.white38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
