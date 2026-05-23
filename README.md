# my_ai_app — Gemini Multimodal Chat (Flutter)

Production-style Flutter app: **multi-chat history** (ChatGPT/Gemini style), **text + images + PDF** input, **streaming** AI replies, **Markdown** rendering, and **offline persistence** with Hive.

| Item | Value (from code) |
|------|-------------------|
| Model | `gemini-2.5-flash` (`AppConfig.geminiModel`) |
| API transport | Google Generative Language **REST SSE** (`streamGenerateContent?alt=sse`) |
| State management | `flutter_bloc` |
| Local DB | `hive_flutter` — box `chat_sessions_v1` |
| SDK note | `google_genai` on pub.dev is a **placeholder**; multimodal payloads use `lib/core/genai/genai_content.dart` (`GenAiContent.multi`, `GenAiData.mime`) |

---

## Features (as implemented)

### Multi-chat sessions
- Each conversation is a **`ChatSession`**: `chatId`, `title`, `createdAt`, `updatedAt`, embedded `messages`.
- **Navigation drawer** lists sessions (newest `updatedAt` first).
- **New chat** creates a fresh session with title `"New chat"`.
- **Switch chat** loads that session’s messages from Hive.
- **Delete** (trash icon) removes the active session; opens the next session or a new one.
- First user text message auto-renames the session (max **48** chars, `session_title.dart`).

### Multimodal input
- **Text** — optional if attachments exist.
- **Images** — `image_picker` (multi), extensions: `jpg`, `jpeg`, `png`, `webp`, `gif`, `heic`.
- **PDF** — `file_picker`, extension `pdf`.
- Max file size: **20 MB** per attachment.
- Files are copied under app documents (`AttachmentStorageService`).
- **Preview bar** above the input; remove before send.

### AI output
- **Streaming** tokens appended live in the UI (`await for` on repository stream).
- **Markdown** for model messages (`flutter_markdown` / `MarkdownBody`): headings, bold, code blocks, tables, accent colors (`markdown_message_body.dart`).
- **Shimmer** while the model bubble is empty and streaming.

### Persistence
- Hive adapters: `ChatMessageAdapter` (typeId **1**), `ChatSessionAdapter` (typeId **2**).
- `ChatMessage`: `id`, `role` (`user` \| `model`), `text`, `timestamp`, `mediaPaths` (local file paths).
- Empty model messages are not saved; stale empty model rows are pruned on load.

---

## Project structure

```
lib/
├── main.dart                          # Hive init, adapters, DI, chatBloc.bootstrap()
├── app.dart                           # MaterialApp + BlocProvider
├── core/
│   ├── config/app_config.dart
│   ├── genai/genai_content.dart       # GenAiContent / GenAiData.mime shim
│   ├── services/attachment_storage_service.dart
│   ├── theme/app_theme.dart
│   ├── utils/session_title.dart
│   └── error/failures.dart
└── features/chat/
    ├── domain/
    │   ├── entities/
    │   │   ├── chat_message.dart
    │   │   ├── chat_session.dart      # ChatSession + ChatSessionSummary
    │   │   └── attachment_pick_type.dart
    │   └── repositories/chat_repository.dart
    ├── data/
    │   ├── models/
    │   │   ├── chat_message_model.dart + ChatMessageAdapter
    │   │   └── chat_session_model.dart + ChatSessionAdapter
    │   ├── datasources/
    │   │   ├── chat_local_datasource.dart
    │   │   └── gemini_remote_service.dart
    │   └── repositories/chat_repository_impl.dart
    └── presentation/
        ├── bloc/
        │   ├── chat_bloc.dart
        │   ├── chat_event.dart
        │   └── chat_state.dart
        ├── pages/chat_screen.dart
        └── widgets/
            ├── chat_history_drawer.dart
            ├── chat_input_panel.dart
            ├── attachment_preview_bar.dart
            ├── message_bubble.dart
            ├── message_media_attachments.dart
            ├── markdown_message_body.dart
            ├── streaming_shimmer_bubble.dart
            ├── ai_status_badge.dart
            └── error_banner.dart
```

---

## Architecture

```
UI (ChatScreen, Drawer, Input)
        ↓ events
   ChatBloc
        ↓
 ChatRepositoryImpl
   ├── ChatLocalDataSource  → Hive Box<ChatSessionModel>
   └── GeminiRemoteService  → REST SSE + optional generateContent fallback
```

### BLoC events (`chat_event.dart`)

| Event | Purpose |
|-------|---------|
| `FetchAllSessions` | Load drawer list; open latest session or create first |
| `CreateNewChat` | New UUID session, empty messages |
| `LoadChatSession(chatId)` | Switch thread |
| `PickAttachment(type)` | Image or PDF picker |
| `RemoveSelectedAttachment(path)` | Remove staged file |
| `SendMessage(text)` | Send multimodal prompt + stream response |
| `ClearChatError` | Dismiss error state |
| `DeleteActiveSession` | Delete current session from Hive |

### BLoC states (`chat_state.dart`)

| State | Purpose |
|-------|---------|
| `ChatInitial` | Before bootstrap |
| `ChatHistoryLoading` | Loading sessions / switching chat |
| `ChatStateActive` | `activeChatId`, `sessionTitle`, `sessions`, `messages`, `selectedFiles`, `isStreaming`, `errorMessage`, `streamingMessageId` |

`ReceiveStreamChunk` exists as an event type; streaming is handled inside `SendMessage` via `await for` (no separate chunk handler registered).

### Gemini API (`gemini_remote_service.dart`)

- Endpoint: `POST https://generativelanguage.googleapis.com/v1beta/models/{model}:streamGenerateContent?alt=sse&key={apiKey}`
- Builds `contents` from history + new user turn with `inlineData` (base64) for attachments.
- Generation config: `temperature: 0.8`, `topP: 0.95`, `maxOutputTokens: 8192`.
- Stream timeout: **120 seconds**.
- If SSE yields no text, falls back to non-stream `generateContent`.

---

## Requirements

- **Flutter** SDK `^3.11.5` (see `pubspec.yaml`)
- **Google AI API key** with access to `gemini-2.5-flash`
- **Android**: `INTERNET`, `READ_MEDIA_IMAGES`, `READ_EXTERNAL_STORAGE` (maxSdk 32) — see `android/app/src/main/AndroidManifest.xml`
- **iOS**: photo/library usage as required by `image_picker` / `file_picker` (configure `Info.plist` if App Store build)

---

## Setup & run

```bash
cd my_ai_app
flutter pub get
```

### API key (recommended)

Pass the key at build/run time (do **not** commit keys to git):

```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE
```

`AppConfig.geminiApiKey` reads `String.fromEnvironment('GEMINI_API_KEY', defaultValue: ...)`. Prefer `--dart-define` over hardcoding in `app_config.dart`.

### Run

```bash
flutter run
# or release
flutter run --release --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE
```

### Analyze & test

```bash
flutter analyze
flutter test
```

---

## Usage (in the app)

1. Open the **menu (☰)** → see chat history.
2. Tap **New chat** for an empty thread.
3. Tap **+** in the input area → **Image** or **PDF**.
4. Type a message (optional if files are attached) → **Send**.
5. Model replies stream in with Markdown formatting.
6. **Trash** deletes the **current** session only.

---

## Dependencies (`pubspec.yaml`)

| Package | Role in this app |
|---------|------------------|
| `flutter_bloc` | `ChatBloc` |
| `hive` / `hive_flutter` | Session + message persistence |
| `http` | Gemini REST SSE |
| `google_genai` | Declared; **not used at runtime** (placeholder package) |
| `image_picker` | Photos |
| `file_picker` | PDFs |
| `flutter_markdown` | AI reply rendering |
| `shimmer` | Streaming placeholder |
| `uuid` | IDs for sessions/messages/files |
| `equatable` | Entities / BLoC |
| `google_fonts` | UI typography |
| `path` / `path_provider` | Attachment storage paths |
| `mime` | MIME detection for uploads |
| `intl` | Drawer session timestamps |

---

## Hive schema

**Box name:** `chat_sessions_v1`  
**Key:** `chatId` (String)

**ChatSessionModel (typeId 2)**  
`chatId`, `title`, `createdAt`, `updatedAt`, `messages[]`

**ChatMessageModel (typeId 1)** — nested in session  
`id`, `role`, `text`, `timestamp`, `mediaPaths[]`

---

## Troubleshooting

| Issue | What to check |
|-------|----------------|
| Empty AI bubble / no reply | Valid API key; network; `flutter run` full restart (not hot reload only) |
| 403 / API errors | Key restrictions, billing, model name `gemini-2.5-flash` |
| Attachments fail | File &lt; 20 MB; allowed extension; Android permissions |
| Old chats missing | Storage migrated to `chat_sessions_v1`; earlier single-box data is not auto-imported |
| Gradle cache errors | `cd android && gradlew --stop`, clear `~/.gradle/caches` if corrupted |

---

## Security

- Never commit API keys. Use `--dart-define=GEMINI_API_KEY=...` or CI secrets.
- Rotate any key that was committed or shared.
- Chat data stays **on device** in Hive; attachments in app documents directory.

---

## 100% accurate project prompt (specification)

Use this block verbatim when extending the project or regenerating code so behavior matches the repository.

```text
Build a Flutter app named my_ai_app (SDK ^3.11.5) — a multimodal AI chat client like ChatGPT/Gemini.

STACK
- flutter_bloc for state (ChatBloc, sealed ChatEvent/ChatState).
- hive_flutter: box chat_sessions_v1, Hive typeId 1 = ChatMessage, typeId 2 = ChatSession.
- Gemini model gemini-2.5-flash via REST (http package), NOT the placeholder google_genai pub package.
- Multimodal request builder: lib/core/genai/genai_content.dart with GenAiContent.multi, GenAiData.mime, inlineData base64 in JSON.
- Endpoints: streamGenerateContent?alt=sse; fallback generateContent if stream empty.
- image_picker (multi image), file_picker (pdf), flutter_markdown for model role only, shimmer while streaming.

DOMAIN
- ChatMessage: id, role (user|model), text, timestamp, mediaPaths (List<String> local paths).
- ChatSession: chatId, title, createdAt, updatedAt, messages List<ChatMessage>.
- ChatSessionSummary: chatId, title, updatedAt for drawer list.

BLOC EVENTS
FetchAllSessions, CreateNewChat, LoadChatSession(chatId), PickAttachment(AttachmentPickType.image|pdf),
RemoveSelectedAttachment(path), SendMessage(text), ClearChatError, DeleteActiveSession.

BLOC STATE ChatStateActive
activeChatId, sessionTitle, sessions (summaries), messages, selectedFiles (List<File>), isStreaming,
streamingMessageId, errorMessage.

FLOW
- main: Hive.initFlutter, register both adapters, open sessions box, ChatRepositoryImpl(local+GeminiRemoteService),
  ChatBloc.bootstrap() -> FetchAllSessions -> load latest or create session.
- SendMessage: save user message to Hive session; append user + empty model placeholder; stream chunks updating model text;
  on complete save model message; refresh session list; auto-title from first user text if title is "New chat" (max 48 chars).
- initializeSession(history) on remote service before each send; history excludes current user+model placeholders.

UI
- Dark theme (AppTheme), ChatScreen with drawer (ChatHistoryDrawer): New chat button, session list sorted by updatedAt desc.
- App bar: menu, dynamic sessionTitle, delete active session.
- Attachment preview bar, ChatInputPanel with + menu (image/pdf), send when text or files present and not streaming.
- MessageBubble: user vs model; model uses MarkdownMessageBody; images rounded in bubble; PDF attachment card.
- Portrait only in main via SystemChrome.

CONFIG AppConfig
geminiModel, hiveSessionsBoxName, chatMessageTypeId=1, chatSessionTypeId=2, defaultSessionTitle='New chat',
sessionTitleMaxLength=48, maxAttachmentBytes=20MB, allowed image/pdf extensions, geminiApiKey from GEMINI_API_KEY env.

ATTACHMENTS
AttachmentStorageService copies picks to app documents with uuid filename; validates size/extension.

ERRORS
Failures: CacheFailure, NetworkFailure, ApiFailure, TimeoutFailure, RateLimitFailure, UnknownFailure — surfaced via SnackBar/ErrorBanner.

NO placeholder TODOs in production paths; streaming via await for in bloc, not broken ChatSession SDK streaming.
```

---

## License

Private app (`publish_to: 'none'`). Add your license if you open-source the project.
