---
id: issue-002
title: "Inject brain into Home chat's system prompt"
feature: brain
status: done
created_at: 2026-06-13
tags: [afk, p1]
---

# [002] Inject brain into Home chat's system prompt

**Type:** AFK
**Priority:** P1
**Blocked by:** 001
**User stories covered:** 8, 9, 14

---

## What to build

Wire `BrainRepository` (from issue 001) into `ChatController.sendMessage` so every Home chat request is
preceded by the brain's assembled system prompt.

- `ChatController` gains a `BrainRepository` dependency, wired via `home/di.dart` consuming `brain`'s
  `api.dart` (per the module-DI rule: `home` registers the dependency on `brain`, not the reverse).
- In `sendMessage`, before calling `repo.streamChat(model: ..., messages: history)`:
  - Call `brainRepository.buildSystemPrompt()`.
  - If it returns non-null, prepend `ChatMessage(role: ChatRole.system, content: prompt)` to the `history`
    list used for *this request only*.
  - If it returns `null`, send `history` unchanged.
- This prepended system message must **not** be added to `conversation.messages` and must **not** be
  persisted via `conversationsRepository.saveConversations` — it's rebuilt fresh every request so edits to
  `identity.md`/`soul.md`/`memory.md` take effect on the next message.
- No changes to `ChatModelRepository`, the three provider repository impls, or their datasources —
  `ChatRole.system` messages are already handled correctly by all of them (Anthropic extracts into `system`
  field; Ollama/OpenAI-compatible pass through as `role: "system"`).

---

## Acceptance criteria

- [ ] `ChatController` depends on `BrainRepository` (via `brain`'s `api.dart`), wired in `home/di.dart`.
- [ ] When `buildSystemPrompt()` returns a non-null string, the `messages` list passed to
  `ChatModelRepository.streamChat()` starts with a `ChatMessage(role: ChatRole.system, content: <prompt>)`.
- [ ] When `buildSystemPrompt()` returns `null`, the `messages` list passed to `streamChat()` is unchanged
  from today's behavior.
- [ ] The prepended system message never appears in `conversation.messages`, in the UI, or in persisted
  conversation data.
- [ ] Existing `ChatController`/streaming/error-handling behavior (story progress, error messages,
  persistence of user/assistant messages) is unaffected.

---

## Tests required

Yes — extend `test/features/home/domain/controller/chat_controller_test.dart` with a `FakeBrainRepository`
returning a canned `String?`. Assert:
- the `messages` argument captured by `FakeChatModelRepository.streamChat()` is prepended with the expected
  `ChatRole.system` message when `buildSystemPrompt()` returns non-null;
- `messages` is unchanged when `buildSystemPrompt()` returns `null`;
- `conversation.messages` (and whatever gets persisted) never contains the system message.

---

## Notes

- `ChatRole.system` and its `.value` mapping already exist in `lib/features/home/domain/model/chat_message.dart`.
- `AnthropicDatasource.streamChat` already filters `ChatRole.system` messages into the `system` field;
  `OllamaDatasource`/`OpenAiCompatibleDatasource` already pass all messages through as-is — confirmed during
  PRD grilling, no signature changes needed anywhere in `chat_model_repository.dart` or its implementations.

---

## Log

_Updated as work progresses._

- Added `BrainRepository` as a 4th constructor dependency on `ChatController`; `sendMessage` now calls `buildSystemPrompt()` and prepends a `ChatRole.system` message to a request-only `requestMessages` list (history/`conversation.messages`/persistence untouched).
- Wired `createBrainRepository()` into `home/di.dart`'s `_createChatController`.
- Added `FakeBrainRepository` and `lastMessages` capture on `FakeChatModelRepository`; added 3 new tests covering prepend-on-non-null, unchanged-on-null, and never-persisted/never-in-UI. All 32 tests in `test/features/home/` pass; `flutter analyze` clean on changed files.
- QA approved by user on 2026-06-13.
