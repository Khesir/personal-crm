---
id: issue-005
title: "Chat pane: embed Avyn in the dock with a single model switcher"
feature: kanban
status: done
created_at: 2026-06-15
tags: [afk, p1]
---

# [005] Chat pane: embed Avyn in the dock with a single model switcher

**Type:** AFK
**Priority:** P1
**Blocked by:** 001
**User stories covered:** 24, 25, 26, 27

---

## What to build

Build the dock's Chat pane by embedding the existing Home chat experience (`HomeChatSection`/`ChatController`, persona "Avyn"), scoped to the working project, with cleaner styling per `kanban-redesign.html`.

Also remove the duplicate model-switcher dropdown from the chat composer app-wide: `Composer` (`lib/features/home/presentation/widget/composer.dart`) gains a flag to hide its model-switcher dropdown, since the pane-header switcher is now canonical. Apply this to both the dock's Chat pane and the Home tab for consistency.

---

## Acceptance criteria

- [x] Dock's Chat pane renders the Home chat conversation (Avyn), scoped to the working project.
- [x] A single model-switcher dropdown appears in the pane header; the composer no longer shows a model dropdown.
- [x] The Home tab's chat composer also no longer shows a model dropdown (header switcher remains canonical there too).
- [x] Sending a message and receiving a streamed response works identically to the Home tab.
- [x] Chat pane visuals (message bubbles, assistant cards) follow the cleaner styling from `kanban-redesign.html`.

---

## Tests required

Yes — new/extended widget test (e.g. `composer_test.dart` or alongside `chat_mode_toggle_test.dart`) asserting the model-switcher dropdown is absent from the composer when the new flag is set, and present in the pane header.

---

## Notes

- Visual reference: `kanban-redesign.html` — `.chat-pane`, `.chat-model` in `.pane-head`, `.msg.user`/`.msg.assistant`, `.chat-composer`.
- Depends on issue 001 for the dock shell/pane container to exist.

---

## Log

_Updated as work progresses._

- Added `lib/features/kanban/presentation/widget/chat_pane.dart` (`ChatPane`), a `FutureBuilder`-based wrapper that fetches the shared `ChatController` singleton via `createChatController()` (same pattern as `_HomePlaceholder`/`_HomeSidebar`) and renders `HomeChatSection`. Since `ChatController` is an app-wide shared singleton (not per-project), no extra controller plumbing was threaded through `KanbanSection`/`BoardDockSection`; project scoping happens per-conversation via `workingProjectId`, unchanged here.
- Wired `ChatPane` into `BoardDockSection._DockBody` (both `DockMode.chat` and the `DockMode.both` row), removing `_ChatPanePlaceholder`.
- `Composer` (`lib/features/home/presentation/widget/composer.dart`) gained a `showModelBadge` flag (default `true`, preserving existing behavior) that hides the active-model chip. Set to `false` for both `Composer` usages in `home_chat_section.dart`, since `_Header`'s `ModelSwitcher` is the canonical switcher for both the Home tab and (via the reused `HomeChatSection`) the dock's chat pane.
- Tests: new `test/features/home/presentation/widget/composer_test.dart` asserts the active-model chip is shown by default and hidden with `showModelBadge: false`. `flutter test test/features/home test/features/kanban` (237 tests) and `flutter analyze` (touched files clean; 2 pre-existing unrelated `deprecated_member_use` infos elsewhere) both pass.
- QA approved by user on 2026-06-16.