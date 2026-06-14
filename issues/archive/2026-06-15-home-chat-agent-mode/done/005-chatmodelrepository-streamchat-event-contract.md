---
id: issue-005
title: "ChatModelRepository.streamChat() contract change: ChatStreamEvent + ToolDefinition"
feature: home-chat-agent-mode
status: done
created_at: 2026-06-14
tags: [afk, p1]
---

# [005] ChatModelRepository.streamChat() contract change: ChatStreamEvent + ToolDefinition

**Type:** AFK
**Priority:** P1
**Blocked by:** 004
**User stories covered:** 26 (contract portion)

---

## What to build

Change `ChatModelRepository.streamChat()`'s signature from `Stream<String>` to `Stream<ChatStreamEvent>`,
and give it an optional `tools: List<ToolDefinition>` parameter (default `[]`). Apply this mechanically
across all three providers — Ollama, OpenAI-compatible, Anthropic — **without** implementing any tool-call
parsing yet (that's issues 006, 008, 009). When `tools` is empty, behavior is unchanged: only text-delta
events are emitted.

- `ChatStreamEvent`: a small sealed type (`lib/features/home/domain/model/`) with two variants:
  - A text-delta variant wrapping a `String` chunk (today's behavior).
  - A tool-call-requested variant wrapping a `List<ToolCall>` (unused by any provider until 006/008/009, but
    the type must exist so the sealed type and `ChatController` unwrapping logic compile against it).
- `ToolDefinition`: `{ name: String, description: String, parameters: Map<String, dynamic> }` (JSON Schema for
  the tool's arguments).
- Update `anthropic_datasource.dart`, `ollama_datasource.dart`, `openai_compatible_datasource.dart` and their
  `*_repository_impl.dart` to the new `streamChat()` signature: every emitted text chunk is now wrapped in the
  text-delta `ChatStreamEvent` variant. The `tools` parameter is accepted but not yet sent in any request body.
- `ChatController` (`domain/controller/chat_controller.dart`) unwraps the text-delta event exactly as it
  unwraps a `String` chunk today — no behavior change for non-agent conversations (`workingProjectId == null`).

---

## Acceptance criteria

- [ ] `ChatStreamEvent` sealed type exists with text-delta and tool-call-requested variants.
- [ ] `ToolDefinition` model exists with `name`, `description`, `parameters`.
- [ ] `ChatModelRepository.streamChat()` signature is `Stream<ChatStreamEvent> streamChat({required String
  model, required List<ChatMessage> messages, List<ToolDefinition> tools = const []})` across the interface
  and all three implementations.
- [ ] All three datasources/repositories compile and emit only text-delta events when `tools` is empty.
- [ ] `ChatController.sendMessage()` for non-agent conversations continues to stream text into the assistant
  message exactly as before (no observable behavior change).
- [ ] Existing datasource and controller tests pass after being updated to the new event-wrapped return type.

---

## Tests required

Yes — per the PRD's testing decisions: update every existing datasource test
(`test/features/home/data/datasource/*_datasource_test.dart`) for the new event-wrapped return type (text
chunks now arrive as text-delta `ChatStreamEvent`s). Update `chat_controller_test.dart`'s
`FakeChatModelRepository` to emit `ChatStreamEvent`s. All existing non-agent-mode tests must continue passing
unchanged in observable behavior.

---

## Notes

- This is a breaking signature change affecting all three datasource/repository implementations and their
  existing tests, done *before* any tool-call parsing — per the PRD: "every existing test updates its
  expectations to the new event-wrapped shape, even before tool-call parsing is implemented for that
  provider."
- Depends on 004 for the `ToolCall` type used by the tool-call-requested `ChatStreamEvent` variant.
- See PRD section "`ChatModelRepository` contract change".

---

## Log

_Updated as work progresses._

- Added `ChatStreamEvent` (sealed, `ChatStreamTextDelta`/`ChatStreamToolCallsRequested`) and `ToolDefinition` models.
- Changed `ChatModelRepository.streamChat()` to `Stream<ChatStreamEvent>` with optional `tools` param; updated Ollama, OpenAI-compatible, and Anthropic datasources/repositories to wrap text chunks in `ChatStreamTextDelta`. `ChatController.sendMessage()` now switches on the event type, appending text deltas exactly as before and no-op'ing on tool-call-requested events.
- Updated `chat_controller_test.dart` fakes and `anthropic_datasource_test.dart` to the new event-wrapped shape. `flutter test test/features/home/` (42 tests) and `flutter analyze` on all touched files pass with no new issues.

QA approved by user on 2026-06-14.
