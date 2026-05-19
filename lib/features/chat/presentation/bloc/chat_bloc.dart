import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_ai_app/core/error/failures.dart';
import 'package:my_ai_app/core/services/attachment_storage_service.dart';
import 'package:my_ai_app/features/chat/domain/entities/chat_message.dart';
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
    on<LoadChatHistory>(_onLoadChatHistory);
    on<PickAttachment>(_onPickAttachment);
    on<RemoveSelectedAttachment>(_onRemoveSelectedAttachment);
    on<SendMultimodalPrompt>(_onSendMultimodalPrompt);
    on<ClearChatError>(_onClearChatError);
    on<ClearChatHistory>(_onClearChatHistory);
  }

  final ChatRepository _repository;
  final AttachmentStorageService _attachmentStorage;
  final Uuid _uuid;

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
      emit(ChatStateActive(messages: const [], errorMessage: failure.message));
    } catch (error) {
      emit(
        ChatStateActive(
          messages: const [],
          errorMessage: 'Unable to load history: $error',
        ),
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

  Future<void> _onSendMultimodalPrompt(
    SendMultimodalPrompt event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatStateActive || current.isStreaming) {
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

    try {
      await _repository.saveMessage(userMessage);
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
            messages: List<ChatMessage>.unmodifiable(_messages),
            isStreaming: true,
            streamingMessageId: modelId,
          ),
        );
      }

      await _finalize(emit, modelId);
    } catch (error) {
      _messages = List<ChatMessage>.from(_messages)
        ..removeWhere((m) => m.id == modelId);

      final msg = error is Failure ? error.message : '$error';
      emit(
        ChatStateActive(
          messages: List<ChatMessage>.unmodifiable(_messages),
          isStreaming: false,
          errorMessage: msg,
        ),
      );
    }
  }

  Future<void> _finalize(Emitter<ChatState> emit, String modelId) async {
    final index = _messages.indexWhere((m) => m.id == modelId);
    if (index == -1) {
      emit(
        ChatStateActive(
          messages: List<ChatMessage>.unmodifiable(_messages),
          isStreaming: false,
        ),
      );
      return;
    }

    final modelMsg = _messages[index];
    if (modelMsg.text.trim().isEmpty) {
      _messages = List<ChatMessage>.from(_messages)..removeAt(index);
      emit(
        ChatStateActive(
          messages: List<ChatMessage>.unmodifiable(_messages),
          isStreaming: false,
          errorMessage: 'No response from Gemini.',
        ),
      );
      return;
    }

    try {
      await _repository.saveMessage(modelMsg);
    } on Failure catch (failure) {
      emit(
        ChatStateActive(
          messages: List<ChatMessage>.unmodifiable(_messages),
          isStreaming: false,
          errorMessage: failure.message,
        ),
      );
      return;
    }

    emit(
      ChatStateActive(
        messages: List<ChatMessage>.unmodifiable(_messages),
        isStreaming: false,
        streamingMessageId: null,
      ),
    );
  }

  void _onClearChatError(ClearChatError event, Emitter<ChatState> emit) {
    final current = state;
    if (current is ChatStateActive) {
      emit(current.copyWith(clearError: true));
    }
  }

  Future<void> _onClearChatHistory(
    ClearChatHistory event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _repository.clearChatHistory();
      _messages = const [];
      emit(const ChatStateActive(messages: []));
    } on Failure catch (failure) {
      emit(_active().copyWith(errorMessage: failure.message));
    }
  }

  ChatStateActive _active() {
    final current = state;
    if (current is ChatStateActive) {
      return current;
    }
    return ChatStateActive(messages: List<ChatMessage>.unmodifiable(_messages));
  }
}
