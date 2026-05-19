import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_ai_app/core/theme/app_theme.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';
import 'package:my_ai_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:my_ai_app/features/chat/presentation/bloc/chat_event.dart';
import 'package:my_ai_app/features/chat/presentation/bloc/chat_state.dart';
import 'package:my_ai_app/features/chat/presentation/widgets/ai_status_badge.dart';
import 'package:my_ai_app/features/chat/presentation/widgets/attachment_preview_bar.dart';
import 'package:my_ai_app/features/chat/presentation/widgets/chat_input_panel.dart';
import 'package:my_ai_app/features/chat/presentation/widgets/error_banner.dart';
import 'package:my_ai_app/features/chat/presentation/widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(const LoadChatHistory());
    _textController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text;
    final state = context.read<ChatBloc>().state;
    if (state is! ChatStateActive) {
      return;
    }
    final canSend = !state.isStreaming &&
        (text.trim().isNotEmpty || state.selectedFiles.isNotEmpty);
    if (!canSend) {
      return;
    }
    context.read<ChatBloc>().add(SendMultimodalPrompt(text));
    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.userGradientStart,
                    AppTheme.userGradientEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gemini Multimodal',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 17)),
                Text(
                  'Text · Images · PDF · Markdown',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
        actions: [
          BlocSelector<ChatBloc, ChatState, bool>(
            selector: (s) => s is ChatStateActive && s.isStreaming,
            builder: (_, streaming) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AiStatusBadge(isStreaming: streaming),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surfaceColor,
                  title: Text('Clear chat?',
                      style: GoogleFonts.inter(color: Colors.white)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear')),
                  ],
                ),
              );
              if (ok == true) {
                if (!context.mounted) {
                  return;
                }
                context.read<ChatBloc>().add(const ClearChatHistory());
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listenWhen: (p, c) =>
            c is ChatStateActive &&
            c.errorMessage != null &&
            (p is! ChatStateActive || p.errorMessage != c.errorMessage),
        listener: (context, state) {
          if (state is ChatStateActive && state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  action: SnackBarAction(
                    label: 'Dismiss',
                    onPressed: () =>
                        context.read<ChatBloc>().add(const ClearChatError()),
                  ),
                ),
              );
          }
        },
        builder: (context, state) {
          if (state is ChatInitial || state is ChatHistoryLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentColor),
            );
          }

          if (state is! ChatStateActive) {
            return const SizedBox.shrink();
          }

          final canSend = !state.isStreaming &&
              (_textController.text.trim().isNotEmpty ||
                  state.selectedFiles.isNotEmpty);

          if (state.messages.isNotEmpty) {
            _scrollToBottom();
          }

          return Column(
            children: [
              if (state.errorMessage != null)
                ErrorBanner(
                  message: state.errorMessage!,
                  onDismiss: () =>
                      context.read<ChatBloc>().add(const ClearChatError()),
                ),
              Expanded(
                child: state.messages.isEmpty
                    ? _EmptyState(onTap: (t) {
                        _textController.text = t;
                        _send();
                      })
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final msg = state.messages[index];
                          final streaming = state.isStreaming &&
                              msg.id == state.streamingMessageId;
                          final shimmer =
                              streaming && msg.text.isEmpty;

                          if (streaming) {
                            return _LiveModelBubble(
                              messageId: msg.id,
                              showShimmer: shimmer,
                            );
                          }

                          return MessageBubble(
                            key: ValueKey(msg.id),
                            message: msg,
                            isStreaming: false,
                            showShimmer: false,
                          );
                        },
                      ),
              ),
              AttachmentPreviewBar(
                files: state.selectedFiles,
                onRemove: (path) => context
                    .read<ChatBloc>()
                    .add(RemoveSelectedAttachment(path)),
              ),
              ChatInputPanel(
                controller: _textController,
                focusNode: _focusNode,
                isStreaming: state.isStreaming,
                canSend: canSend,
                onSend: _send,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LiveModelBubble extends StatelessWidget {
  const _LiveModelBubble({
    required this.messageId,
    required this.showShimmer,
  });

  final String messageId;
  final bool showShimmer;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChatBloc, ChatState, ChatMessage?>(
      selector: (state) {
        if (state is! ChatStateActive) {
          return null;
        }
        final i = state.messages.indexWhere((m) => m.id == messageId);
        return i == -1 ? null : state.messages[i];
      },
      builder: (context, msg) {
        if (msg == null) {
          return const SizedBox.shrink();
        }
        return MessageBubble(
          key: ValueKey('live_$messageId'),
          message: msg,
          isStreaming: true,
          showShimmer: showShimmer,
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    const tips = [
      'Explain this image',
      'Summarize this PDF',
      'Write Flutter code for a login screen',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_rounded,
                size: 56, color: AppTheme.accentColor),
            const SizedBox(height: 16),
            Text(
              'Multimodal Gemini Chat',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send text, photos, or PDFs. Replies render with Markdown.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white54, height: 1.5),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: tips
                  .map(
                    (t) => ActionChip(
                      label: Text(t),
                      onPressed: () => onTap(t),
                      backgroundColor: AppTheme.surfaceColor,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
