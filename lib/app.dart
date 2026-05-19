import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_ai_app/core/theme/app_theme.dart';
import 'package:my_ai_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:my_ai_app/features/chat/presentation/pages/chat_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.chatBloc});

  final ChatBloc chatBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatBloc>.value(
      value: chatBloc,
      child: MaterialApp(
        title: 'Gemini Chat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const ChatScreen(),
      ),
    );
  }
}
