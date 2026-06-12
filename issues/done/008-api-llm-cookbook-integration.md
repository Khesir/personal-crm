---
id: issue-008
title: "API LLM cookbook integration (Claude Anthropic & Custom API in Home chat)"
feature: service-cards
status: done
created_at: 2026-06-13
tags: [afk, p2]
---

# [008] API LLM cookbook integration (Claude Anthropic & Custom API in Home chat)

**Type:** AFK
**Priority:** P2
**Blocked by:** none (006 and 007 are both done/qa)
**User stories covered:** 19 (revised), extends 29-34

---

## What to build

Extend Home chat's cookbook (issue 007) to also aggregate enabled **API LLM** cards (Claude Anthropic,
Custom API), with full routing and streaming — closing the gap intentionally left out of scope by 007 and
documented in the PRD's "Out of Scope" section / User Story #19.

- Rename `LocalLlmRepository` (`lib/features/home/domain/repository/local_llm_repository.dart`) to
  `ChatModelRepository` (interface unchanged: `listModels()`, `streamChat({model, messages})`) since the
  contract now spans both Local LLM and API LLM cards. Update all implementers and references
  (`OllamaRepositoryImpl`, `OpenAiCompatibleRepositoryImpl`, `ChatController`, `home/di.dart`,
  `service_card_form_dialog.dart`, and the existing test file).
- New Anthropic repository (`lib/features/home/data/datasource/anthropic_datasource.dart` +
  `lib/features/home/data/repository/anthropic_repository_impl.dart`) for `claudeAnthropic` cards:
  - `listModels()`: `GET https://api.anthropic.com/v1/models` with headers `x-api-key: {apiKey}`,
    `anthropic-version: 2023-06-01` — response shape `{ data: [{ id, ... }, ...] }` (same `data`/`id` shape
    as the OpenAI-compatible datasource's parsing).
  - `streamChat()`: `POST https://api.anthropic.com/v1/messages` with the same headers plus
    `content-type: application/json`, body `{ model, max_tokens: 4096, messages: [...], stream: true }`.
    `ChatMessage`s with `role == ChatRole.system` are extracted into a top-level `system` string field
    (joined, if multiple) instead of the `messages` array — Anthropic's Messages API has no `system` role
    inside `messages`. Parse Anthropic's named-event SSE stream: emit `delta.text` for
    `content_block_delta` events where `delta.type == 'text_delta'`, stop at `message_stop`.
- Reuse `OpenAiCompatibleRepositoryImpl`/`OpenAiCompatibleDatasource` unchanged for `customApi` cards — only
  the `Dio` instance differs (bearer-auth header, `baseUrl` from `card.fields['baseUrl']`).
- `home/di.dart`'s `_repositoryFor` and `service_card_form_dialog.dart`'s `_repositoryForCard` gain branches
  for `claudeAnthropic` (Anthropic-headers `Dio` → `AnthropicRepositoryImpl`) and `customApi` (bearer-auth
  `Dio` → `OpenAiCompatibleRepositoryImpl`), mirroring the header/URL patterns already used by issue 006's
  health checks (`lib/features/settings/data/repository/health_check_repository_impl.dart`).
- `ChatController.refresh()`'s card filter becomes
  `(c.category == ServiceCategory.localLlm || c.category == ServiceCategory.apiLlm) && c.enabled`
  (rename the resulting `_localLlmCards` field to `_cookbookCards`); `sendMessage()`'s card lookup uses the
  same list. `disabledModels` curation already applies uniformly per-card, so no further change is needed
  there.
- `service_card_form_dialog.dart`'s per-model checklist (`_showModelChecklist`, from issue 007) extends to
  `claudeAnthropic`/`customApi` cards in edit mode (loading/checklist/"Unable to load models" states, same
  as Local LLM cards).
- Home chat's empty-state copy (`home_chat_section.dart`'s `_EmptyState`) drops the "local"/"Nothing leaves
  this machine" framing — it's no longer accurate once API LLM entries can appear in the cookbook. Replace
  with a provider-neutral message (e.g. "Chat with your configured models.").
- `issues/prd-settings-services-cards.md` has already been updated (User Story #19 and the "Out of Scope"
  entry both now cross-reference this issue).

---

## Acceptance criteria

- [ ] With an enabled Claude Anthropic card and a valid API key, its models appear in Home chat's model
  picker as `"<model> — <card name>"`, alongside any Local LLM entries.
- [ ] With an enabled Custom API card, its models (via `GET {baseUrl}/v1/models` with bearer auth) appear in
  the picker the same way.
- [ ] Selecting a Claude Anthropic entry and sending a message streams the assistant's response via the
  Anthropic Messages API (`POST /v1/messages`, `stream: true`), with chunks accumulating into the assistant
  message exactly like Local LLM entries.
- [ ] Selecting a Custom API entry and sending a message streams via `POST {baseUrl}/v1/chat/completions`
  with bearer auth, same SSE parsing as Custom Local.
- [ ] A disabled or unreachable (e.g. invalid API key) API LLM card contributes zero entries without
  affecting other cards — same per-card error isolation as Local LLM cards.
- [ ] `disabledModels` curation works for API LLM cards: unchecking a model in the edit dialog's checklist
  removes it from the picker on next load.
- [ ] Switching between a Local LLM entry and an API LLM entry mid-session streams correctly via each
  entry's respective repository.
- [ ] Home chat's empty state no longer claims chats stay local/private when API LLM cards may be enabled.

---

## Tests required

Yes — extend `test/features/home/domain/controller/chat_controller_test.dart`:
- Rename the fake/typedefs to match the `ChatModelRepository` rename.
- Add a fake API LLM card (e.g. `claudeAnthropic`, category `apiLlm`) alongside existing Local LLM cards in
  the multi-card aggregation, routing, curation, and fallback tests — verify entries from both categories
  appear together, route to the correct fake repository, and that `disabledModels` filters apply the same
  way.
- New datasource-level tests for `AnthropicDatasource`: SSE parsing of `content_block_delta`/`message_stop`
  events into accumulated text (using a fake/manual stream, following the same pattern as the existing
  OpenAI-compatible SSE parsing — no real network calls), and `listModels()` parsing of the `{ data: [...] }`
  response shape.
- Confirm `system`-role messages (if any are ever constructed) are excluded from Anthropic's `messages` array
  and passed via the top-level `system` field — a unit test on the request-body construction is sufficient
  (no live API call).

---

## Notes

- Builds directly on 006 (`done/`) and 007 (`qa/`) — reuses 006's exact header/URL patterns for Anthropic and
  Custom API, and 007's cookbook/`ChatModelRepository` architecture.
- Anthropic's Messages API requires `max_tokens`; use a hardcoded default of `4096` (no existing
  configuration surface for this — adding one is out of scope here).
- A failed `streamChat()` call (e.g. 401 from an invalid API key) propagating out of `sendMessage()` is a
  pre-existing gap (not introduced by this issue, and not specific to API LLM cards) — out of scope to fix
  here, but worth a follow-up issue since API errors (bad keys, rate limits) are more likely in practice than
  local-server connection errors.
- Optional, non-blocking: a visual cue in the model picker distinguishing local vs. API (cloud) entries for
  privacy awareness — out of scope for this issue but worth a future UX pass.

---

## Log

_Updated as work progresses._

- Renamed `LocalLlmRepository` → `ChatModelRepository` (`lib/features/home/domain/repository/chat_model_repository.dart`,
  replacing `local_llm_repository.dart`) and updated all implementers/references
  (`OllamaRepositoryImpl`, `OpenAiCompatibleRepositoryImpl`, `ChatController`, `home/di.dart`,
  `service_card_form_dialog.dart`, and the test file).
- Added `AnthropicDatasource`/`AnthropicRepositoryImpl` (`lib/features/home/data/datasource/anthropic_datasource.dart`,
  `lib/features/home/data/repository/anthropic_repository_impl.dart`): `listModels()` via `GET /v1/models`
  (`{data: [{id, ...}]}` shape); `streamChat()` via `POST /v1/messages` with `max_tokens: 4096`, `stream: true`,
  system-role messages extracted into a top-level `system` string field, and Anthropic SSE parsing
  (`content_block_delta` → `delta.text`, stops at `message_stop`).
- `home/di.dart`'s `_repositoryFor` and `service_card_form_dialog.dart`'s `_repositoryForCard` gained
  `claudeAnthropic` (Anthropic-header `Dio` → `AnthropicRepositoryImpl`) and `customApi` (bearer-auth `Dio` →
  `OpenAiCompatibleRepositoryImpl`) branches, mirroring issue 006's health-check header/URL patterns.
- `ChatController.refresh()`'s card filter now includes `ServiceCategory.apiLlm` cards alongside `localLlm`
  (renamed `_localLlmCards` → `_cookbookCards`); `sendMessage()`'s lookup uses the same list. `disabledModels`
  curation applies unchanged (no per-category branching needed).
- `service_card_form_dialog.dart`'s per-model checklist (`_showModelChecklist`) now also shows for
  `claudeAnthropic`/`customApi` cards in edit mode via a new `_isApiLlmType` getter.
- Updated Home chat's empty-state copy (`home_chat_section.dart`) to drop the "local"/"Nothing leaves this
  machine" framing ("Assistant" / "Chat with your configured models — local or API.").
- Tests: new `test/features/home/data/datasource/anthropic_datasource_test.dart` (4 tests) covering
  `listModels()` parsing, SSE `content_block_delta`/`message_stop` parsing, request-body shape
  (`model`/`max_tokens`/`stream`/`messages`), and `system`-role extraction — using a fake `HttpClientAdapter`,
  no real network calls. Extended `test/features/home/domain/controller/chat_controller_test.dart` (renamed
  `FakeLocalLlmRepository` → `FakeChatModelRepository`) with 4 new tests covering cross-category cookbook
  aggregation, a disabled API LLM card contributing zero entries, `disabledModels` curation for an API LLM
  card, and `sendMessage` routing to an API LLM card's repository. `flutter analyze` clean (same 2
  pre-existing unrelated infos); full `flutter test` 120/120 passing.
- QA rejected on 2026-06-13. Bug appended — sending a message to a Claude Anthropic entry whose request the
  Anthropic API rejects (400 bad request) crashes the app with an unhandled `DioException`.
- Bug fixed on 2026-06-13. Root cause was in `ChatController.sendMessage()` (not `AnthropicDatasource`, whose
  `try`/`catch` already covers `_dio.post()` and forwards failures via `controller.addError`): the
  `streamChat()` consumption loop had a `try`/`finally` with no `catch`, so a stream error thrown by `await
  for` propagated unhandled out of `sendMessage()` — a fire-and-forget call from the UI — crashing the app.
  Added a `catch` clause that calls a new `_setErrorMessage()` helper, replacing the in-progress assistant
  message's `content` with a short user-facing notice ("⚠️ Something went wrong while generating a response.
  Please try again.") while leaving `streaming: true` for `_finishStreaming()` (in the existing `finally`
  block) to flip to `false` as normal. Generic — applies to any `ChatModelRepository` backend. Added a new
  test, `sendMessage surfaces a stream error from the repository as an error message instead of crashing`, in
  `test/features/home/domain/controller/chat_controller_test.dart` using a new `_ErroringStreamRepository`
  fake (mirrors `AnthropicDatasource`'s `controller.addError` + `controller.close()` pattern). Full `flutter
  test` 123/123 passing; `flutter analyze` clean (same 2 pre-existing unrelated infos).
- Follow-up fix on 2026-06-13 (post-approval, fixed directly per user request rather than via a new QA
  cycle): the generic message from the fix above was itself appearing for a real Claude Anthropic card.
  `POST /v1/messages` was returning a 400 `invalid_request_error` ("Your credit balance is too low to access
  the Anthropic API..."), which `GET /v1/models` doesn't hit (no credits required), so the card still
  populated the cookbook and the chat looked broken with no indication why. Added
  `describeChatError()` (`lib/features/home/data/datasource/chat_error_mapper.dart`), used by all three
  datasources' (`AnthropicDatasource`, `OpenAiCompatibleDatasource`, `OllamaDatasource`) `streamChat()` catch
  blocks: when a `DioException`'s response body is JSON shaped like `{"error": "..."}` or
  `{"error": {"message": "..."}}`, the stream now emits a new `ChatRequestException`
  (`chat_model_repository.dart`) carrying that message instead of the raw `DioException`.
  `ChatController._setErrorMessage()` appends the `ChatRequestException`'s message in parentheses to the
  existing generic notice (e.g. "Something went wrong while generating a response. (Your credit balance is
  too low...) Please try again."), falling back to the unchanged generic message when no provider message can
  be parsed (e.g. local-server connection errors). New tests: `AnthropicDatasource.streamChat()` surfaces the
  provider's error message as a `ChatRequestException` on a 400 response, and `ChatController.sendMessage()`
  includes that message in the conversation. Full `flutter test` 125/125 passing; `flutter analyze` clean
  (same 2 pre-existing unrelated infos).
- QA approved by user on 2026-06-13.

---

## Bug

**Reported:** 2026-06-13
**Found during:** Visual QA
**Description:** Selecting a Claude Anthropic entry and sending a message can crash the app with an
unhandled exception:

```
[ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: DioException [bad response]: This
exception was thrown because the response has a status code of 400 and RequestOptions.validateStatus was
configured to throw for this status code.
...
#0      DioMixin.fetch (package:dio/src/dio_mixin.dart:523:7)
<asynchronous suspension>
#1      AnthropicDatasource.streamChat.<anonymous closure> (package:crm/features/home/data/datasource/anthropic_datasource.dart:38:26)
<asynchronous suspension>
```

`AnthropicDatasource.streamChat()`'s `try`/`catch` wraps the SSE-parsing loop, but `_dio.post(...)` itself
can throw a `DioException` (e.g. a 400 from a malformed or rejected request) before the stream is even
established — and/or `ChatController.sendMessage()` doesn't handle a `streamChat()` failure, so the error
goes unhandled instead of surfacing in the conversation as an error message. This is the
"failed `streamChat()` call propagating unhandled out of `sendMessage()`" gap already noted (but left out
of scope) in this issue's Notes — it now needs to be fixed because it crashes the app rather than just
leaving a stuck "streaming" message.

### What to fix
_To be investigated during implementation._

### Acceptance Criteria
- [x] Bug no longer reproduces
- [x] Original acceptance criteria still met
- [x] A test exists that would have caught this
