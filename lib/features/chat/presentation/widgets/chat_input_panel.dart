import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_ai_app/core/theme/app_theme.dart';

class ChatInputPanel extends StatelessWidget {
  const ChatInputPanel({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isStreaming,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isStreaming;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: AppTheme.scaffoldBackground.withValues(alpha: 0.96),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: !isStreaming,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: isStreaming
                          ? 'Gemini is responding...'
                          : 'Ask Gemini anything...',
                      suffixIcon: value.text.trim().isEmpty
                          ? null
                          : IconButton(
                              onPressed: isStreaming
                                  ? null
                                  : () {
                                      controller.clear();
                                    },
                              icon: Icon(
                                Icons.close_rounded,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 18,
                              ),
                            ),
                    ),
                    onSubmitted: (_) {
                      if (!isStreaming && value.text.trim().isNotEmpty) {
                        onSend();
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final canSend = !isStreaming && value.text.trim().isNotEmpty;
                return AnimatedContainer(
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
                              color: AppTheme.accentColor.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
