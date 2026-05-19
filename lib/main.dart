import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_ai_app/app.dart';
import 'package:my_ai_app/core/config/app_config.dart';
import 'package:my_ai_app/core/services/attachment_storage_service.dart';
import 'package:my_ai_app/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:my_ai_app/features/chat/data/datasources/gemini_remote_service.dart';
import 'package:my_ai_app/features/chat/data/models/chat_message_model.dart';
import 'package:my_ai_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:my_ai_app/features/chat/presentation/bloc/chat_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(AppConfig.chatMessageTypeId)) {
    Hive.registerAdapter(ChatMessageAdapter());
  }

  final chatBox = await ChatLocalDataSource.openBox();
  final localDataSource = ChatLocalDataSource(chatBox: chatBox);
  final remoteService = GeminiRemoteService(apiKey: AppConfig.geminiApiKey);
  final attachmentStorage = AttachmentStorageService();

  final repository = ChatRepositoryImpl(
    localDataSource: localDataSource,
    remoteService: remoteService,
  );

  final chatBloc = ChatBloc(
    repository: repository,
    attachmentStorage: attachmentStorage,
  );

  runApp(MyApp(chatBloc: chatBloc));
}
