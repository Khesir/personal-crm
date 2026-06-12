---
id: issue-007
title: "Local model cookbook (multi-card picker, routing & curation)"
feature: service-cards
status: done
created_at: 2026-06-12
tags: [afk, p1]
---

# [007] Local model cookbook (multi-card picker, routing & curation)

**Type:** AFK
**Priority:** P1
**Blocked by:** 005
**User stories covered:** 29, 30, 31, 32, 33, 34

---

## What to build

Generalize Home chat's model picker from a single hardcoded Ollama instance into a "cookbook" aggregated
from every enabled Local LLM card, with routing and per-model curation.

- New `LocalLlmRepository` interface generalizing the existing Ollama repository's contract
  (`listModels()`, `streamChat({model, messages})`):
  - The existing Ollama repository implementation satisfies it unchanged for `ollama`-type cards.
  - A new OpenAI-compatible implementation satisfies it for `customLocal`-type cards: list models via `GET
    {baseUrl}/v1/models`, stream chat via `POST {baseUrl}/v1/chat/completions` with `stream: true`,
    parsing OpenAI-style SSE `data: {...}` lines terminated by `data: [DONE]`.
- New `CookbookEntry { cardId, cardName, cardType, model }` value object.
- Chat state's `availableModels: List<String>` becomes `List<CookbookEntry>`; `activeModel: String?`
  becomes `activeEntry: CookbookEntry?`.
- `ChatController.load()`: for every **enabled** Local LLM card, build the matching `LocalLlmRepository`
  pointed at that card's base URL, call `listModels()` (errors caught per-card — a failing card
  contributes zero entries), filter out models in that card's `disabledModels`, and flatten into the
  cookbook list. If the previous active entry is still present, keep it; otherwise fall back to the first
  entry, or `null` if the list is empty.
- `ChatController.sendMessage()`: resolve `activeEntry.cardId` back to its card, build the matching
  `LocalLlmRepository`, and stream from it.
- The model switcher renders each entry as `"<model> — <card name>"`.
- The chat empty-state copy ("Chat privately with a local Ollama model...") becomes provider-agnostic
  ("a local model") since Custom Local cards may not be Ollama.
- The Local LLM card edit dialog (from issue 005) gains a per-model enable/disable checklist: populated by
  calling `listModels()` for that card when the dialog opens (shows an inline "Unable to load models"
  message if the card is unreachable); toggling a model persists via
  `ServiceCardsController.toggleModelEnabled` / `disabledModels`.

---

## Acceptance criteria

- [ ] With two enabled Local LLM cards configured (e.g. one Ollama, one Custom Local), the Home chat model
  picker shows entries from both, each labeled `"<model> — <card name>"`.
- [ ] Selecting a model from either card and sending a message streams the response from that card's
  server.
- [ ] If a Local LLM card is disabled or unreachable, its models are absent from the picker and the rest of
  the picker still populates.
- [ ] If the currently active entry's card is removed or disabled, the picker falls back to the first
  remaining entry, or shows nothing if none remain.
- [ ] The Local LLM card edit dialog shows a checklist of that card's installed models; unchecking a model
  removes it from the chat picker on next load, and checking it again restores it.
- [ ] If a card's models can't be listed when opening its edit dialog, the checklist shows an "Unable to
  load models" message instead of erroring.

---

## Tests required

Yes — extend the existing chat controller test: a fake service-cards repository supplies enabled Local LLM
cards (with `disabledModels`), and a fake `LocalLlmRepository` per card (generalizing the existing fake
Ollama repository) verifies aggregation across multiple cards, curation filtering, active-entry
selection/switching, `sendMessage` routing to the correct fake per card, fallback behavior when the active
entry's card disappears, and that one card's error doesn't prevent others from contributing entries.

---

## Notes

- API LLM cards (issue 006) are explicitly out of scope for this cookbook — Local LLM only, per the PRD.
- Hardware-compatibility scanning and model downloads are out of scope (future PRD).

---

## Log

_Updated as work progresses._

- Added `CookbookEntry` (`lib/features/home/domain/model/cookbook_entry.dart`) with value equality, plus a new
  `LocalLlmRepository` interface (`lib/features/home/domain/repository/local_llm_repository.dart`, replacing
  `ollama_repository.dart`) generalizing `listModels()`/`streamChat()`.
- Added an OpenAI-compatible implementation (`data/datasource/openai_compatible_datasource.dart` +
  `data/repository/openai_compatible_repository_impl.dart`) for `customLocal` cards: `GET /v1/models`,
  `POST /v1/chat/completions` with SSE `data: {...}` / `data: [DONE]` parsing.
- Rewrote `ChatStateData` (`cookbook: List<CookbookEntry>`, `activeEntry: CookbookEntry?`) and `ChatController`
  (`load()` aggregates enabled Local LLM cards into the cookbook, filters `disabledModels`, keeps/falls back the
  active entry; `sendMessage()` routes to the active entry's card repo via `repositoryFor`).
- Rewrote `home/di.dart` (`_repositoryFor` switches on `ServiceType` to build Ollama or OpenAI-compatible repos;
  `ChatController` now takes `ServiceCardsRepository` + `repositoryFor`), `ModelSwitcher` (renders
  `"<model> — <card name>"`), `home_chat_section.dart` (provider-agnostic empty-state copy, `Composer` passed
  `state.activeEntry?.model`).
- Added a per-model enable/disable checklist to `service_card_form_dialog.dart` for Local LLM cards in edit mode:
  fetches `listModels()` on open (loading/checklist/"Unable to load models" states), checkboxes call
  `ServiceCardsController.toggleModelEnabled`.
- Tests: rewrote `test/features/home/domain/controller/chat_controller_test.dart` with
  `FakeServiceCardsRepository`/`FakeLocalLlmRepository` covering multi-card aggregation, per-card routing,
  disabled/unreachable card exclusion, `disabledModels` filtering, active-entry keep/fallback/empty behavior, and
  ported persistence/streaming tests (13 tests, all passing). `flutter analyze` and full `flutter test` (113
  tests) are clean.
- QA rejected on 2026-06-13. Bug appended — toggling a model in a Local LLM card's checklist (Settings)
  doesn't reflect in Home chat's model picker without a full app restart.
- Bug fixed on 2026-06-13. Root cause: `createChatController()` (`lib/features/home/di.dart`) cached a
  singleton `ChatController` and only ever called `load()` once at startup, so the cookbook never
  re-aggregated after Settings changed a card's `disabledModels` or enabled/disabled/added/removed a card.
  Extracted the cookbook-aggregation logic from `ChatController.load()` into a new `ChatController.refresh()`
  method, and updated `createChatController()` to call `refresh()` on the cached instance every time it's
  invoked (i.e. each time Home becomes visible again via `_HomePlaceholder`'s rebuild), so the picker now
  reflects Settings changes without an app restart. Added a `ChatController`-level test
  (`test/features/home/domain/controller/chat_controller_test.dart`) that loads the cookbook, mutates the
  fake service-cards repository's `disabledModels`, and calls `refresh()` on the same controller instance to
  verify the cookbook updates live.
- QA rejected on 2026-06-13. Two bugs appended — no way to enable/disable a Local LLM card from Settings,
  and a newly-added Ollama card's models don't appear in Home chat's cookbook until its edit dialog has been
  opened once.
- Bug fixed on 2026-06-13. Added `ServiceCardsController.toggleCardEnabled(cardId)` (flips `enabled` via
  `copyWith`, persists, refreshes `ServiceCardsCache`) and wired a `Switch` into `_ServiceCard`
  (`services_section.dart`), threaded through `_CategorySection` via a new `onToggleEnabled` callback —
  giving every service card (Local LLM, API LLM, Services) a visible enable/disable control. Added
  `ServiceCardsController toggleCardEnabled flips a card's enabled flag and persists, leaving other cards
  untouched` to `test/features/settings/domain/controller/service_cards_controller_test.dart`. This
  unblocks acceptance criterion #3, since a user can now disable a Local LLM card and `ChatController.refresh()`'s
  existing `c.enabled` filter excludes it from the cookbook.
- Bug fixed on 2026-06-13. Root cause: concurrent first calls to `createChatController()`
  (`lib/features/home/di.dart`) — from `_HomePlaceholder` and `_HomeSidebar` building in the same frame —
  both saw `_chatController == null` and each constructed its own `ChatController`, leaving the sidebar and
  content area on divergent instances and only one of them ever becoming the singleton. The abandoned
  instance's cookbook was aggregated once and never `refresh()`-ed again, so a newly-added card's models
  never appeared in the widget still bound to it. Fixed by adding an in-flight
  `Future<ChatController>? _chatControllerCreation` guard so only one `ChatController` is ever constructed;
  concurrent callers await the same in-flight future and then `refresh()` the resulting instance. Added
  `createChatController concurrent first calls return the same singleton instance` to
  `test/features/home/di_test.dart`, which failed before the fix (two distinct instances) and passes after.
- QA approved by user on 2026-06-13.

---

## Bug

**Reported:** 2026-06-13
**Found during:** Visual QA
**Description:** After enabling/disabling a model in a Local LLM card's per-model checklist (Settings >
Services > Local LLM > Edit), Home chat's cookbook still shows the old set of models. The user has to
fully restart the app (in dev, a hot restart) before the change appears — it should reflect without
requiring a restart.

### What to fix
_To be investigated during implementation._ `createChatController()` caches a singleton `ChatController`
and only calls `load()` once at startup, so the cookbook never re-aggregates after Settings changes
`disabledModels` (or adds/removes/enables/disables a card). The cookbook should refresh — e.g. by
re-running `load()` when Home becomes visible again, or by having `ChatController` listen for
`ServiceCardsController` changes and re-aggregate — without requiring a full app restart.

### Acceptance Criteria
- [x] Bug no longer reproduces
- [x] Original acceptance criteria still met
- [x] A test exists that would have caught this

---

## Bug

**Reported:** 2026-06-13
**Found during:** Visual QA
**Description:** There is no way to enable or disable a Local LLM card from Settings > Services > Local
LLM — no enable/disable control is shown on the card tile or in its edit dialog. This blocks acceptance
criterion #3 ("If a Local LLM card is disabled or unreachable, its models are absent from the picker and
the rest of the picker still populates") from being exercised at all, since a user has no way to disable a
card.

### What to fix
Added `ServiceCardsController.toggleCardEnabled(cardId)`, mirroring `toggleModelEnabled`: finds the card by
id, flips its `enabled` flag via `copyWith(enabled: !card.enabled)`, persists via
`repository.saveCards(updated)`, refreshes `ServiceCardsCache`, and emits the updated list. Wired a `Switch`
into `_ServiceCard` (`services_section.dart`), shown for every card across all three categories (Local LLM,
API LLM, Services), reflecting `card.enabled` and calling a new `onToggleEnabled` callback threaded through
`_CategorySection` (mirroring `onSetDefault`) to `controller.toggleCardEnabled(card.id)`. A user can now
disable a Local LLM card from its tile, which `ChatController.refresh()` already excludes via its
`c.enabled` filter — unblocking acceptance criterion #3.

### Acceptance Criteria
- [x] Bug no longer reproduces
- [x] Original acceptance criteria still met
- [x] A test exists that would have caught this

---

## Bug

**Reported:** 2026-06-13
**Found during:** Visual QA
**Description:** After adding (or saving) an Ollama card in Settings > Services > Local LLM, its models do
not appear in Home chat's cookbook/model picker. They only show up after opening that card's edit dialog,
which re-fetches the model list from the card's base URL. The cookbook should be able to list and show the
card's models on its own, without requiring the user to open the edit dialog first.

### What to fix
Root cause: `createChatController()` (`lib/features/home/di.dart`) had a race between the two callers that
invoke it in the same frame — `_HomePlaceholder` and `_HomeSidebar` (both `FutureBuilder`s that call
`createChatController()` on every build, e.g. when Home first becomes visible). Both calls observed
`_chatController == null` simultaneously, so each constructed and `load()`-ed its **own**
`ChatController` instance before either assignment to the singleton completed — leaving the sidebar and
content area bound to two divergent `ChatController`s, only one of which ever became `_chatController`.
The abandoned instance's cookbook was aggregated once at that point in time and never `refresh()`-ed
again, so a card added afterwards (whose models would only be picked up by the *other*, still-singleton
instance) never appeared in the widget still bound to the abandoned instance. Re-aggregation only
appeared to work after opening the edit dialog because that screen's `_loadModels()` happens to run against
the live singleton via the next `createChatController()` call. Fixed by adding an in-flight
`Future<ChatController>? _chatControllerCreation` guard: the first caller starts construction and stores
the in-flight future; any concurrent caller awaits that same future (then calls `refresh()` on the
resulting instance) instead of starting its own. This guarantees exactly one `ChatController` instance is
ever created, so the sidebar and content area — and every subsequent `refresh()` — operate on the same
state, and a newly-added card's models appear in the cookbook on the next time Home becomes visible,
without needing to open the card's edit dialog.

### Acceptance Criteria
- [x] Bug no longer reproduces
- [x] Original acceptance criteria still met
- [x] A test exists that would have caught this
