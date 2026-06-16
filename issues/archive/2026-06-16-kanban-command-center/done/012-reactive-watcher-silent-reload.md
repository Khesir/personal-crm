---
id: issue-012
title: "Reactive watcher: silent reload (no loading flash)"
feature: kanban
status: done
created_at: 2026-06-15
tags: [afk, p2]
---

# 012 Reactive watcher: silent reload (no loading flash)

**Type:** AFK
**Priority:** P2
**Blocked by:** None
**User stories covered:** 26, 27, 30

---

## What to build

Make watcher-triggered board reloads update silently, without flashing the whole board to a loading state.

- `IssuesController` gains `refresh(String localPath)`: fetches the current issue list and emits `AsyncData` directly, without first emitting `AsyncLoading()`.
- `IssuesWatcherController`'s debounced reload calls `refresh` instead of `load`. `load` (which emits `AsyncLoading()`) remains the entry point for the initial board open, where a loading state is appropriate.
- `changedIds` computation (driving the "Just updated" badge) and the watch pill's "synced Xs ago" continue to update the same way after `refresh` completes — only the loading-state flash is removed.

---

## Acceptance criteria

- [ ] Calling `refresh` updates the issue list without emitting `AsyncLoading()` first
- [ ] An external file change under `issues/<status>/` updates the board within the existing debounce window, without a visible loading-state flash
- [ ] The "Just updated" badge still appears on the affected card after a watcher-triggered reload
- [ ] The watch pill's "synced Xs ago" still resets after a watcher-triggered reload
- [ ] The initial board load (on opening the project) still shows the existing loading state via `load`

---

## Tests required

Yes — `issues_controller_test.dart`: `refresh` emits `AsyncData` directly (no `AsyncLoading` emission) and updates the issue list from the repository. `issues_watcher_controller_test.dart`: the debounced reload path calls `refresh` rather than `load`.

---

## Notes

Independent of the dock work (issues 008-010) — can be picked up in any order relative to them. See `issues/prd-dock-redesign.md` (Implementation Decision 7). Out of scope: per-file targeted patch reloads and an independent timeout-based clear for the "Just updated" badge (both noted as out of scope in the PRD).

---

## Log

_Updated as work progresses._

- Added `IssuesController.refresh(localPath)`, which calls `repository.getIssues` directly and emits `AsyncData` without an intermediate `AsyncLoading()`. `load()` is unchanged.
- Updated `IssuesWatcherController._reload()` to call `issuesController.refresh(localPath)` instead of `load()`; `changedIds`/`lastSyncedAt` logic unchanged.
- Tests: `issues_controller_test.dart` adds a test asserting `refresh()` emits exactly one `AsyncData` (no `AsyncLoading`) and reflects updated repo state. `issues_watcher_controller_test.dart` adds a test asserting the debounced reload only emits `AsyncData` on `issuesController.stream` (no `AsyncLoading`). `flutter test test/features/kanban` (82 tests) and `flutter analyze` (2 pre-existing unrelated deprecation warnings only) both pass.
- QA approved by user on 2026-06-16.
