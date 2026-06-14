---
id: issue-020
title: "Recommended pick: default model selection by hardware fit"
feature: cookbook-fit
status: qa
created_at: 2026-06-14
tags: [afk, p2]
---

# [020] Recommended pick: default model selection by hardware fit

**Type:** AFK
**Priority:** P2
**Blocked by:** 018
**User stories covered:** 3 (`prd-agent-capabilities-expansion.md`)

---

## What to build

When starting a new conversation without an explicit model choice, default the selection to the
local model that best fits the user's hardware (per issue 018's `fitResult`), instead of the
existing default-card behavior — falling back to that existing behavior when no suitable local
entry exists.

---

## Acceptance criteria

- [x] When starting a new conversation without an explicit model choice, the default selection is
  the local `CookbookEntry` with the highest `fitResult.score`.
- [x] For new agent-mode conversations, the candidate set is additionally filtered to
  `supportsTools == true` entries.
- [x] If no local entries exist, or none have a `fitResult` (e.g. no `HardwareInfo`), falls back
  to the existing default-card selection behavior, unchanged.
- [x] The existing "no model selected yet" flow for plain conversations continues to work when no
  local entries qualify.

---

## Tests required

Yes — `ChatController`/`home/di.dart` test: a local, tool-capable entry with the highest
`fitResult.score` wins; falls back correctly when there are no local entries or no hardware info;
plain-conversation default behavior is unaffected when no local entries qualify.

---

## Notes

- Lives in `ChatController`/`createChatController` (`home/di.dart`), extending the current "no
  model selected yet" fallback — do not replace it.

---

## Log

_Updated as work progresses._

Added `recommendedCookbookEntry(List<CookbookEntry>)` to `cookbook_entry.dart` — returns the
entry with the highest `fitResult.score`, or null if none have a `fitResult`. `ChatController.refresh()`'s
"no model selected yet" `activeEntry` default now tries `recommendedCookbookEntry(cookbook)` before
falling back to `cookbook.first` (unchanged when empty). `AgentModePickerDialog`'s initial
`_selectedEntry` uses the same helper over `widget.cookbook`, which is already filtered to
`supportsTools == true`, satisfying the agent-mode filter requirement without duplicating logic.

Tests: new `recommendedCookbookEntry` unit tests in `cookbook_entry_test.dart` (highest score wins
regardless of order, ignores null `fitResult`, falls back to null for empty/no-fit lists); new
`ChatController` test verifying `load()` defaults `activeEntry` to the highest-`fitResult.score`
entry rather than `cookbook.first`. `flutter test` → 369 passed, `flutter analyze` clean except 2
pre-existing `deprecated_member_use` infos.
