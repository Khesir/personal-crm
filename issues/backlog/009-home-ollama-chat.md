# [009] Home: local Ollama chat

**Type:** AFK
**Priority:** P1
**Blocked by:** 001, 002

---

## What to build

The Home tab: a private, local ChatGPT-style chat backed by Ollama, per `screen-home.jsx`.

Models:

- `ChatConversation { id, title, createdAt, updatedAt, messages }`
- `ChatMessage { role, content, streaming }`

Modules:

- `OllamaRepository` (abstract):
  - `listModels()` — `GET {OLLAMA_BASE_URL}/api/tags`
  - `streamChat({model, messages})` — `POST {OLLAMA_BASE_URL}/api/chat` with `stream: true`, consumed as
    NDJSON via Dio's streamed response.
- `ChatController extends StreamState<ChatStateData>`: manages the conversation list, the active
  conversation, and appends streamed tokens to the last (assistant) message as they arrive.
- Conversations persisted as JSON in `shared_preferences`.

UI (per `screen-home.jsx`):

- Sidebar: conversation list with relative timestamps ("2m", "1h", "Yesterday", ...) + "New chat" button.
- Page header: conversation title + `ModelSwitcher`, populated from `listModels()`.
- Message list: `UserMsg`, `BotMsg` (with "generating…" indicator while streaming), `CodeBlock` for
  fenced code, all rendered via `flutter_markdown_plus`.
- `Composer`: input box showing the active model tag and a send button.
- Empty state (no conversations / new chat): "Local assistant" intro + suggested prompt chips + composer.

---

## Acceptance criteria

- [ ] Sending a message streams the assistant's response token-by-token with a "generating…" indicator.
- [ ] Code blocks and markdown in responses render via `flutter_markdown_plus`.
- [ ] Model switcher lists models from the configured Ollama instance and switches the active model for
      subsequent messages.
- [ ] New conversations appear in the sidebar with relative timestamps; conversation history persists
      across an app restart.
- [ ] The empty state (no conversations / new chat) shows the suggested prompts and intro per the design.

---

## Tests required

Yes — `ChatController` unit tests with `FakeOllamaRepository`: streaming token accumulation, conversation
list management (create/select), persistence round-trip.

---

## Notes

- Full end-to-end verification requires a local Ollama instance reachable at `OLLAMA_BASE_URL`.
