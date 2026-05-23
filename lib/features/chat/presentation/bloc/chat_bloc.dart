import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_ai_app/core/config/app_config.dart';
import 'package:my_ai_app/core/error/failures.dart';
import 'package:my_ai_app/core/services/attachment_storage_service.dart';
import 'package:my_ai_app/core/utils/session_title.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_session.dart';
import 'package:my_ai_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:my_ai_app/features/chat/presentation/bloc/chat_event.dart';
import 'package:my_ai_app/features/chat/presentation/bloc/chat_state.dart';
import 'package:uuid/uuid.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required ChatRepository repository,
    required AttachmentStorageService attachmentStorage,
    Uuid uuid = const Uuid(),
  })  : _repository = repository,
        _attachmentStorage = attachmentStorage,
        _uuid = uuid,
        super(const ChatInitial()) {
    on<FetchAllSessions>(_onFetchAllSessions);
    on<CreateNewChat>(_onCreateNewChat);
    on<LoadChatSession>(_onLoadChatSession);
    on<PickAttachment>(_onPickAttachment);
    on<RemoveSelectedAttachment>(_onRemoveSelectedAttachment);
    on<SendMessage>(_onSendMessage);
    on<ClearChatError>(_onClearChatError);
    on<DeleteActiveSession>(_onDeleteActiveSession);
  }

  final ChatRepository _repository;
  final AttachmentStorageService _attachmentStorage;
  final Uuid _uuid;

  String? _activeChatId;
  String _sessionTitle = AppConfig.defaultSessionTitle;
  List<ChatMessage> _messages = const [];
  List<ChatSessionSummary> _sessions = const [];

  /// Bootstraps drawer list + first or latest session.
  Future<void> bootstrap() async {
    add(const FetchAllSessions());
  }

  Future<void> _onFetchAllSessions(
    FetchAllSessions event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatHistoryLoading());
    try {
      _sessions = await _repository.fetchAllSessions();

      if (_sessions.isEmpty) {
        await _createAndActivate(emit);
        return;
      }

      final targetId = _activeChatId ?? _sessions.first.chatId;
      await _loadSessionInternal(targetId, emit);
    } on Failure catch (failure) {
      await _emitActive(emit, errorMessage: failure.message);
    } catch (error) {
      await _emitActive(
        emit,
        errorMessage: 'Unable to load sessions: $error',
      );
    }
  }

  Future<void> _onCreateNewChat(
    CreateNewChat event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is ChatStateActive && current.isStreaming) {
      return;
    }

    await _createAndActivate(emit);
  }

  Future<void> _createAndActivate(Emitter<ChatState> emit) async {
    final chatId = _uuid.v4();
    try {
      final session = await _repository.createSession(chatId: chatId);
      _activeChatId = session.chatId;
      _sessionTitle = session.title;
      _messages = const [];
      _sessions = await _repository.fetchAllSessions();
      await _emitActive(emit);
    } on Failure catch (failure) {
      await _emitActive(emit, errorMessage: failure.message);
    }
  }

  Future<void> _onLoadChatSession(
    LoadChatSession event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is ChatStateActive && current.isStreaming) {
      return;
    }

    emit(const ChatHistoryLoading());
    await _loadSessionInternal(event.chatId, emit);
  }

  Future<void> _loadSessionInternal(
    String chatId,
    Emitter<ChatState> emit,
  ) async {
    try {
      final session = await _repository.loadSession(chatId);
      if (session == null) {
        await _createAndActivate(emit);
        return;
      }

      _activeChatId = session.chatId;
      _sessionTitle = session.title;
      _messages = List<ChatMessage>.from(session.messages);
      _sessions = await _repository.fetchAllSessions();
      await _emitActive(emit);
    } on Failure catch (failure) {
      await _emitActive(emit, errorMessage: failure.message);
    } catch (error) {
      await _emitActive(
        emit,
        errorMessage: 'Unable to load chat: $error',
      );
    }
  }

  Future<void> _onPickAttachment(
    PickAttachment event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatStateActive || current.isStreaming) {
      return;
    }

    try {
      final picked = await _attachmentStorage.pickAttachments(event.type);
      if (picked.isEmpty) {
        return;
      }
      emit(
        current.copyWith(
          selectedFiles: [...current.selectedFiles, ...picked],
          clearError: true,
        ),
      );
    } on Failure catch (failure) {
      emit(current.copyWith(errorMessage: failure.message));
    } catch (error) {
      emit(current.copyWith(errorMessage: 'Pick failed: $error'));
    }
  }

  void _onRemoveSelectedAttachment(
    RemoveSelectedAttachment event,
    Emitter<ChatState> emit,
  ) {
    final current = state;
    if (current is! ChatStateActive) {
      return;
    }

    emit(
      current.copyWith(
        selectedFiles: current.selectedFiles
            .where((f) => f.path != event.filePath)
            .toList(),
      ),
    );
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatStateActive || current.isStreaming) {
      return;
    }

    final chatId = _activeChatId;
    if (chatId == null) {
      return;
    }

    final prompt = event.text.trim();
    final hasFiles = current.selectedFiles.isNotEmpty;
    if (prompt.isEmpty && !hasFiles) {
      return;
    }

    final mediaPaths = current.selectedFiles.map((f) => f.path).toList();
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      text: prompt,
      timestamp: DateTime.now(),
      mediaPaths: mediaPaths,
    );
    final modelId = _uuid.v4();

    final titleOverride = isDefaultSessionTitle(_sessionTitle) && prompt.isNotEmpty
        ? deriveSessionTitle(prompt)
        : null;

    try {
      await _repository.saveMessage(
        chatId: chatId,
        message: userMessage,
        titleOverride: titleOverride,
      );
      if (titleOverride != null) {
        _sessionTitle = titleOverride;
      }
    } on Failure catch (failure) {
      emit(current.copyWith(errorMessage: failure.message));
      return;
    }

    _messages = [
      ..._messages,
      userMessage,
      ChatMessage(
        id: modelId,
        role: 'model',
        text: '',
        timestamp: DateTime.now(),
      ),
    ];

    emit(
      ChatStateActive(
        activeChatId: chatId,
        sessionTitle: _sessionTitle,
        sessions: List<ChatSessionSummary>.unmodifiable(_sessions),
        messages: List<ChatMessage>.unmodifiable(_messages),
        selectedFiles: const [],
        isStreaming: true,
        streamingMessageId: modelId,
        errorMessage: null,
      ),
    );

    final priorHistory = List<ChatMessage>.from(_messages)
      ..removeWhere((m) => m.id == modelId)
      ..removeWhere((m) => m.id == userMessage.id);

    try {
      await for (final chunk in _repository.sendMultimodalStream(
        prompt: prompt,
        history: priorHistory,
        attachmentPaths: mediaPaths,
      )) {
        final index = _messages.indexWhere((m) => m.id == modelId);
        if (index == -1) {
          continue;
        }

        _messages = List<ChatMessage>.from(_messages);
        _messages[index] = _messages[index].copyWith(
          text: _messages[index].text + chunk,
        );

        emit(
          ChatStateActive(
            activeChatId: chatId,
            sessionTitle: _sessionTitle,
            sessions: List<ChatSessionSummary>.unmodifiable(_sessions),
            messages: List<ChatMessage>.unmodifiable(_messages),
            isStreaming: true,
            streamingMessageId: modelId,
          ),
        );
      }

      await _finalize(emit, chatId, modelId);
    } catch (error) {
      _messages = List<ChatMessage>.from(_messages)
        ..removeWhere((m) => m.id == modelId);

      final msg = error is Failure ? error.message : '$error';
      emit(
        ChatStateActive(
          activeChatId: chatId,
          sessionTitle: _sessionTitle,
          sessions: List<ChatSessionSummary>.unmodifiable(_sessions),
          messages: List<ChatMessage>.unmodifiable(_messages),
          isStreaming: false,
          errorMessage: msg,
        ),
      );
    }
  }

  Future<void> _finalize(
    Emitter<ChatState> emit,
    String chatId,
    String modelId,
  ) async {
    final index = _messages.indexWhere((m) => m.id == modelId);
    if (index == -1) {
      await _refreshSessionsAndEmit(emit, chatId);
      return;
    }

    final modelMsg = _messages[index];
    if (modelMsg.text.trim().isEmpty) {
      _messages = List<ChatMessage>.from(_messages)..removeAt(index);
      await _refreshSessionsAndEmit(
        emit,
        chatId,
        errorMessage: 'No response from Gemini.',
      );
      return;
    }

    try {
      await _repository.saveMessage(chatId: chatId, message: modelMsg);
      _sessions = await _repository.fetchAllSessions();
      for (final summary in _sessions) {
        if (summary.chatId == chatId) {
          _sessionTitle = summary.title;
          break;
        }
      }
    } on Failure catch (failure) {
      await _refreshSessionsAndEmit(
        emit,
        chatId,
        errorMessage: failure.message,
        isStreaming: false,
      );
      return;
    }

    await _refreshSessionsAndEmit(emit, chatId);
  }

  Future<void> _refreshSessionsAndEmit(
    Emitter<ChatState> emit,
    String chatId, {
    String? errorMessage,
    bool isStreaming = false,
  }) async {
    try {
      _sessions = await _repository.fetchAllSessions();
    } catch (_) {}

    emit(
      ChatStateActive(
        activeChatId: chatId,
        sessionTitle: _sessionTitle,
        sessions: List<ChatSessionSummary>.unmodifiable(_sessions),
        messages: List<ChatMessage>.unmodifiable(_messages),
        isStreaming: isStreaming,
        streamingMessageId: null,
        errorMessage: errorMessage,
      ),
    );
  }

  void _onClearChatError(ClearChatError event, Emitter<ChatState> emit) {
    final current = state;
    if (current is ChatStateActive) {
      emit(current.copyWith(clearError: true));
    }
  }

  Future<void> _onDeleteActiveSession(
    DeleteActiveSession event,
    Emitter<ChatState> emit,
  ) async {
    final chatId = _activeChatId;
    if (chatId == null) {
      return;
    }

    try {
      await _repository.deleteSession(chatId);
      _activeChatId = null;
      _messages = const [];
      _sessions = await _repository.fetchAllSessions();

      if (_sessions.isNotEmpty) {
        await _loadSessionInternal(_sessions.first.chatId, emit);
      } else {
        await _createAndActivate(emit);
      }
    } on Failure catch (failure) {
      await _emitActive(emit, errorMessage: failure.message);
    }
  }

  Future<void> _emitActive(
    Emitter<ChatState> emit, {
    String? errorMessage,
    bool isStreaming = false,
    String? streamingMessageId,
  }) async {
    final chatId = _activeChatId;
    if (chatId == null) {
      emit(const ChatHistoryLoading());
      return;
    }

    emit(
      ChatStateActive(
        activeChatId: chatId,
        sessionTitle: _sessionTitle,
        sessions: List<ChatSessionSummary>.unmodifiable(_sessions),
        messages: List<ChatMessage>.unmodifiable(_messages),
        isStreaming: isStreaming,
        streamingMessageId: streamingMessageId,
        errorMessage: errorMessage,
      ),
    );
  }
}
