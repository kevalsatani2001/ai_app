import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_ai_app/core/theme/app_theme.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';
import 'package:my_ai_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:my_ai_app/features/chat/presentation/bloc/chat_event.dart';
import 'package:my_ai_app/features/chat/presentation/bloc/chat_state.dart';
import 'package:my_ai_app/features/chat/presentation/widgets/ai_status_badge.dart';
import 'package:my_ai_app/features/chat/presentation/widgets/chat_input_panel.dart';
import 'package:my_ai_app/features/chat/presentation/widgets/error_banner.dart';
import 'package:my_ai_app/features/chat/presentation/widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(const LoadChatHistory());
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendPrompt() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      return;
    }
    context.read<ChatBloc>().add(SendPrompt(text));
    _textController.clear();
    _focusNode.requestFocus();
    _scrollToBottom();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _confirmClearHistory() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: Text(
            'Clear conversation?',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          content: Text(
            'This will permanently delete all local chat messages.',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (shouldClear == true && mounted) {
      context.read<ChatBloc>().add(const ClearChatHistory());
    }
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
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gemini Chat',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Powered by gemini-2.5-flash',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          BlocSelector<ChatBloc, ChatState, bool>(
            selector: (state) =>
                state is ChatStateActive ? state.isStreaming : false,
            builder: (context, isStreaming) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AiStatusBadge(isStreaming: isStreaming),
              );
            },
          ),
          IconButton(
            tooltip: 'Clear chat',
            onPressed: _confirmClearHistory,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listenWhen: (previous, current) {
          if (current is ChatStateActive && current.errorMessage != null) {
            if (previous is! ChatStateActive) {
              return true;
            }
            return previous.errorMessage != current.errorMessage;
          }
          return false;
        },
        listener: (context, state) {
          if (state is ChatStateActive && state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  action: SnackBarAction(
                    label: 'Dismiss',
                    onPressed: () {
                      context.read<ChatBloc>().add(const ClearChatError());
                    },
                  ),
                ),
              );
          }
        },
        buildWhen: (previous, current) => previous != current,
        builder: (context, state) {
          return Column(
            children: [
              if (state is ChatStateActive && state.errorMessage != null)
                ErrorBanner(
                  message: state.errorMessage!,
                  onDismiss: () {
                    context.read<ChatBloc>().add(const ClearChatError());
                  },
                ),
              Expanded(
                child: _buildMessageArea(state),
              ),
              BlocSelector<ChatBloc, ChatState, bool>(
                selector: (state) =>
                    state is ChatStateActive ? state.isStreaming : false,
                builder: (context, isStreaming) {
                  return ChatInputPanel(
                    controller: _textController,
                    focusNode: _focusNode,
                    isStreaming: isStreaming,
                    onSend: _sendPrompt,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageArea(ChatState state) {
    if (state is ChatInitial || state is ChatHistoryLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentColor),
      );
    }

    if (state is! ChatStateActive) {
      return const SizedBox.shrink();
    }

    final messages = state.messages;
    if (messages.isEmpty) {
      return _EmptyChatState(onSuggestionTap: (value) {
        _textController.text = value;
        _sendPrompt();
      });
    }

    _scrollToBottom(animated: state.isStreaming);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isStreamingMessage =
            state.isStreaming && message.id == state.streamingMessageId;
        final showShimmer =
            isStreamingMessage && message.text.isEmpty;

        if (isStreamingMessage) {
          return _StreamingMessageBubble(
            message: message,
            showShimmer: showShimmer,
          );
        }

        return MessageBubble(
          key: ValueKey(message.id),
          message: message,
          isStreaming: false,
          showShimmer: false,
        );
      },
    );
  }
}

class _StreamingMessageBubble extends StatelessWidget {
  const _StreamingMessageBubble({
    required this.message,
    required this.showShimmer,
  });

  final ChatMessage message;
  final bool showShimmer;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChatBloc, ChatState, ChatMessage?>(
      selector: (state) {
        if (state is! ChatStateActive) {
          return null;
        }
        final index = state.messages.indexWhere(
          (entry) => entry.id == message.id,
        );
        if (index == -1) {
          return null;
        }
        return state.messages[index];
      },
      builder: (context, liveMessage) {
        final resolvedMessage = liveMessage ?? message;
        return MessageBubble(
          key: ValueKey('${resolvedMessage.id}_stream'),
          message: resolvedMessage,
          isStreaming: true,
          showShimmer: showShimmer,
        );
      },
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({required this.onSuggestionTap});

  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'Explain quantum computing simply',
      'Write a Flutter widget for a gradient button',
      'Plan a 3-day trip to Tokyo',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.userGradientStart,
                    AppTheme.userGradientEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Start a conversation',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your messages are saved locally and streamed live from Gemini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: suggestions
                  .map(
                    (suggestion) => ActionChip(
                      label: Text(suggestion),
                      onPressed: () => onSuggestionTap(suggestion),
                      backgroundColor: AppTheme.surfaceColor,
                      labelStyle: GoogleFonts.inter(color: Colors.white70),
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
