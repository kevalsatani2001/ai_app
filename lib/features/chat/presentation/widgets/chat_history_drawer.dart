import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:my_ai_app/core/theme/app_theme.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_session.dart';
import 'package:my_ai_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:my_ai_app/features/chat/presentation/bloc/chat_event.dart';
import 'package:my_ai_app/features/chat/presentation/bloc/chat_state.dart';

class ChatHistoryDrawer extends StatelessWidget {
  const ChatHistoryDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.surfaceColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Chats',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<ChatBloc>().add(const CreateNewChat());
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('New chat'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                buildWhen: (prev, curr) =>
                    curr is ChatStateActive &&
                    (prev is! ChatStateActive ||
                        prev.sessions != curr.sessions ||
                        prev.activeChatId != curr.activeChatId),
                builder: (context, state) {
                  if (state is! ChatStateActive) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentColor,
                      ),
                    );
                  }

                  if (state.sessions.isEmpty) {
                    return Center(
                      child: Text(
                        'No conversations yet',
                        style: GoogleFonts.inter(color: Colors.white38),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.sessions.length,
                    itemBuilder: (context, index) {
                      final session = state.sessions[index];
                      final isActive = session.chatId == state.activeChatId;

                      return _SessionTile(
                        session: session,
                        isActive: isActive,
                        onTap: () {
                          if (isActive) {
                            Navigator.pop(context);
                            return;
                          }
                          Navigator.pop(context);
                          context.read<ChatBloc>().add(
                                LoadChatSession(session.chatId),
                              );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.onTap,
  });

  final ChatSessionSummary session;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = DateFormat.MMMd().add_jm().format(session.updatedAt);

    return Material(
      color: isActive
          ? AppTheme.accentColor.withValues(alpha: 0.18)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            leading: Icon(
              Icons.chat_bubble_outline_rounded,
              color: isActive ? AppTheme.accentColor : Colors.white54,
              size: 22,
            ),
            title: Text(
              session.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
            trailing: isActive
                ? const Icon(Icons.check_circle_rounded,
                    color: AppTheme.accentColor, size: 20)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
