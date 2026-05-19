import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_ai_app/core/error/failures.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';
import 'package:my_ai_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:my_ai_app/features/chat/presentation/bloc/chat_event.dart';
import 'package:my_ai_app/features/chat/presentation/bloc/chat_state.dart';
import 'package:uuid/uuid.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required ChatRepository repository,
    Uuid uuid = const Uuid(),
  })  : _repository = repository,
        _uuid = uuid,
        super(const ChatInitial()) {
    on<LoadChatHistory>(_onLoadChatHistory);
    on<SendPrompt>(_onSendPrompt);
    on<ReceiveStreamChunk>(_onReceiveStreamChunk);
    on<ChatStreamError>(_onChatStreamError);
    on<ClearChatError>(_onClearChatError);
    on<ClearChatHistory>(_onClearChatHistory);
    on<StreamStarted>(_onStreamStarted);
    on<StreamCompleted>(_onStreamCompleted);
  }

  final ChatRepository _repository;
  final Uuid _uuid;

  StreamSubscription<String>? _streamSubscription;
  String? _activeModelMessageId;
  List<ChatMessage> _messages = const [];

  Future<void> _onLoadChatHistory(
    LoadChatHistory event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatHistoryLoading());
    try {
      _messages = await _repository.loadChatHistory();
      emit(
        ChatStateActive(
          messages: List<ChatMessage>.unmodifiable(_messages),
        ),
      );
    } on Failure catch (failure) {
      emit(
        ChatStateActive(
          messages: const [],
          errorMessage: failure.message,
        ),
      );
    } catch (error) {
      emit(
        ChatStateActive(
          messages: const [],
          errorMessage: 'Unable to load chat history: $error',
        ),
      );
    }
  }

  Future<void> _onSendPrompt(
    SendPrompt event,
    Emitter<ChatState> emit,
  ) async {
    final trimmedPrompt = event.text.trim();
    if (trimmedPrompt.isEmpty) {
      return;
    }

    final currentState = state;
    if (currentState is ChatStateActive && currentState.isStreaming) {
      return;
    }

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      text: trimmedPrompt,
      timestamp: DateTime.now(),
    );

    final modelMessageId = _uuid.v4();

    try {
      await _repository.saveMessage(userMessage);
    } on Failure catch (failure) {
      emit(
        _activeStateOrEmpty().copyWith(errorMessage: failure.message),
      );
      return;
    } catch (error) {
      emit(
        _activeStateOrEmpty().copyWith(
          errorMessage: 'Failed to save your message: $error',
        ),
      );
      return;
    }

    add(
      StreamStarted(
        userMessage: userMessage,
        modelMessageId: modelMessageId,
      ),
    );

    await _streamSubscription?.cancel();
    _activeModelMessageId = modelMessageId;

    // Pass prior turns only; the new prompt is sent separately (avoids duplicate).
    final priorHistory = List<ChatMessage>.from(_messages);

    _streamSubscription = _repository
        .sendPromptStream(trimmedPrompt, priorHistory)
        .listen(
      (String chunk) {
        add(ReceiveStreamChunk(chunk));
      },
      onError: (Object error) {
        final message = error is Failure
            ? error.message
            : 'Streaming failed: $error';
        add(ChatStreamError(message));
      },
      onDone: () {
        add(const StreamCompleted());
      },
      cancelOnError: true,
    );
  }

  void _onStreamStarted(
    StreamStarted event,
    Emitter<ChatState> emit,
  ) {
    _messages = [
      ..._messages,
      event.userMessage,
      ChatMessage(
        id: event.modelMessageId,
        role: 'model',
        text: '',
        timestamp: DateTime.now(),
      ),
    ];

    emit(
      ChatStateActive(
        messages: List<ChatMessage>.unmodifiable(_messages),
        isStreaming: true,
        streamingMessageId: event.modelMessageId,
      ),
    );
  }

  void _onReceiveStreamChunk(
    ReceiveStreamChunk event,
    Emitter<ChatState> emit,
  ) {
    final modelMessageId = _activeModelMessageId;
    if (modelMessageId == null) {
      return;
    }

    final messageIndex = _messages.indexWhere(
      (message) => message.id == modelMessageId,
    );
    if (messageIndex == -1) {
      return;
    }

    final currentMessage = _messages[messageIndex];
    final updatedMessage = currentMessage.copyWith(
      text: currentMessage.text + event.chunk,
    );

    _messages = List<ChatMessage>.from(_messages);
    _messages[messageIndex] = updatedMessage;

    final currentState = state;
    if (currentState is ChatStateActive) {
      emit(
        currentState.copyWith(
          messages: List<ChatMessage>.unmodifiable(_messages),
        ),
      );
    }
  }

  Future<void> _onStreamCompleted(
    StreamCompleted event,
    Emitter<ChatState> emit,
  ) async {
    final modelMessageId = _activeModelMessageId;
    _activeModelMessageId = null;
    _streamSubscription = null;

    if (modelMessageId != null) {
      final messageIndex = _messages.indexWhere(
        (message) => message.id == modelMessageId,
      );
      if (messageIndex != -1) {
        final finalizedMessage = _messages[messageIndex];
        if (finalizedMessage.text.trim().isNotEmpty) {
          try {
            await _repository.saveMessage(finalizedMessage);
          } on Failure catch (failure) {
            emit(
              _activeStateOrEmpty().copyWith(
                isStreaming: false,
                clearStreamingMessageId: true,
                errorMessage: failure.message,
              ),
            );
            return;
          } catch (error) {
            emit(
              _activeStateOrEmpty().copyWith(
                isStreaming: false,
                clearStreamingMessageId: true,
                errorMessage: 'Failed to persist AI response: $error',
              ),
            );
            return;
          }
        } else {
          _messages = List<ChatMessage>.from(_messages)..removeAt(messageIndex);
        }
      }
    }

    emit(
      ChatStateActive(
        messages: List<ChatMessage>.unmodifiable(_messages),
        isStreaming: false,
      ),
    );
  }

  Future<void> _onChatStreamError(
    ChatStreamError event,
    Emitter<ChatState> emit,
  ) async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;

    final modelMessageId = _activeModelMessageId;
    _activeModelMessageId = null;

    if (modelMessageId != null) {
      _messages = List<ChatMessage>.from(_messages)
        ..removeWhere((message) => message.id == modelMessageId);
    }

    emit(
      ChatStateActive(
        messages: List<ChatMessage>.unmodifiable(_messages),
        isStreaming: false,
        errorMessage: event.error,
      ),
    );
  }

  void _onClearChatError(
    ClearChatError event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is ChatStateActive) {
      emit(currentState.copyWith(clearError: true));
    }
  }

  Future<void> _onClearChatHistory(
    ClearChatHistory event,
    Emitter<ChatState> emit,
  ) async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    _activeModelMessageId = null;

    try {
      await _repository.clearChatHistory();
      _messages = const [];
      emit(
        const ChatStateActive(
          messages: [],
          isStreaming: false,
        ),
      );
    } on Failure catch (failure) {
      emit(
        _activeStateOrEmpty().copyWith(errorMessage: failure.message),
      );
    } catch (error) {
      emit(
        _activeStateOrEmpty().copyWith(
          errorMessage: 'Failed to clear chat history: $error',
        ),
      );
    }
  }

  ChatStateActive _activeStateOrEmpty() {
    final currentState = state;
    if (currentState is ChatStateActive) {
      return currentState;
    }
    return ChatStateActive(messages: List<ChatMessage>.unmodifiable(_messages));
  }

  @override
  Future<void> close() async {
    await _streamSubscription?.cancel();
    return super.close();
  }
}
