---
id: issue-010
title: "Compact chat pane for the dock"
feature: kanban
status: done
created_at: 2026-06-15
tags: [afk, p2]
---

# 010 Compact chat pane for the dock

**Type:** AFK
**Priority:** P2
**Blocked by:** 008
**User stories covered:** 22, 23, 24, 25

---

## What to build

Give `HomeChatSection` a compact layout for use in the dock's Chat pane, which is often only a few hundred pixels tall.

- Add a `compact: bool` parameter to `HomeChatSection`, default `false`.
- When `compact: true`:
  - The header renders only the existing model-switcher dropdown — the title row and chat-mode toggle are omitted.
  - The empty state renders a single placeholder line instead of the suggested-prompt cards.
  - Message list spacing/padding uses tighter values (reference `AppStyling`).
  - The composer starts at single-line height and grows only as the user types additional lines.
- The dock's Chat pane (`ChatPane`) passes `compact: true`. The Home tab continues to use the default (non-compact) layout.

---

## Acceptance criteria

- [ ] In the dock's Chat pane, the header shows only the model-switcher dropdown (no title, no mode toggle)
- [ ] In the dock's Chat pane, an empty conversation shows a single placeholder line instead of suggested-prompt cards
- [ ] In the dock's Chat pane, message spacing/padding is visually tighter than the Home tab
- [ ] In the dock's Chat pane, the composer starts at one line and grows as the user types more lines, without exceeding a sensible max height
- [ ] The Home tab's chat layout is unchanged (title, mode toggle, suggested prompts, default spacing/composer all remain as before)
- [ ] Sending/receiving messages, model switching, and project scoping behave identically in compact and non-compact modes

---

## Tests required

Yes — widget test on `HomeChatSection` (prior art: `composer_test.dart`): with `compact: true`, assert the title/mode-toggle header and suggested-prompt cards are absent and the placeholder empty-state line is shown instead; with `compact: false` (Home tab), assert the existing layout is unchanged.

---

## Notes

Depends on issue 008 since the Chat pane lives inside the restructured dock (`DockPane.chat`). See `issues/prd-dock-redesign.md` (Implementation Decision 6).

---

## Log

_Updated as work progresses._

- Added `compact: bool` (default `false`) to `HomeChatSection`. When `true`, `_Header` renders only the `ModelSwitcher` (no title/mode toggle), `_EmptyState` shows a single "Ask the assistant anything." line instead of the Assistant title + suggested-prompt chips, and message-list/header/composer padding use `AppStyling.spaceSm` instead of `spaceLg`. `ChatPane` now passes `compact: true`; the Home tab's `HomeChatSection(controller: controller)` is unaffected (default `false`). Existing `minLines: 1, maxLines: 4` on `Composer`'s `TextField` already satisfies "starts single-line, grows to a sensible max" for both modes, so `composer.dart` was left unchanged.
- Added `test/features/home/presentation/section/home_chat_section_test.dart` with a minimal `ChatController` built from local fakes (`_FakeServiceCardsRepository`, `_FakeChatModelRepository`, `_FakeChatConversationsRepository`, `_FakeBrainRepository`). Two widget tests cover compact `false`/`true`: title/suggested-prompt chips present vs. absent, placeholder line absent vs. present.
- `flutter analyze` clean on touched files; `flutter test test/features/home test/features/kanban` — 260/260 passed.
- QA approved by user on 2026-06-16.
