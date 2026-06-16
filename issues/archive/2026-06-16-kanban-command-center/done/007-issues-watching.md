---
id: issue-007
title: "Watching: live filesystem sync for the issues/ folder"
feature: kanban
status: done
created_at: 2026-06-15
tags: [afk, p2]
---

# [007] Watching: live filesystem sync for the issues/ folder

**Type:** AFK
**Priority:** P2
**Blocked by:** None
**User stories covered:** 28, 29, 30, 31, 32, 33

---

## What to build

Add a real filesystem watcher on `{localPath}/issues/<status>/*.md` (new `watcher` package dependency, `DirectoryWatcher`) that automatically reloads the board when files change, debounced ~500ms. The page head shows a pulsing "Watching issues/ · synced Xs ago" pill (per `kanban-redesign.html`'s `.watch-pill`); the existing "Rescan" button becomes a small icon-only fallback control.

Cards whose files changed in the most recent watcher-triggered reload show a "Just updated" badge for the current session (cleared on the next reload cycle or after a short timeout).

If the watcher fails to initialize (platform/path error), the pill indicates watching is unavailable and the board relies on manual "Rescan" only.

---

## Acceptance criteria

- [x] A `DirectoryWatcher` (from the new `watcher` dependency) watches `{localPath}/issues/` recursively for the selected project.
- [x] File changes trigger a debounced (~500ms) reload via `IssuesController.load`, with `lastSyncedAt` recorded.
- [x] The page head shows a pulsing "Watching issues/" pill with a "synced Xs ago" label that ticks over time.
- [x] The existing "Rescan" button is demoted to a small icon-only control, still triggering a manual `load`.
- [x] Issues whose files changed in the most recent watcher-triggered reload show a "Just updated" badge on their card; the badge clears on the next reload or after a short timeout.
- [x] If the watcher fails to start, the pill indicates watching is unavailable and "Rescan" remains fully functional.

---

## Tests required

Yes — new test under `test/features/kanban/domain/controller/` using a temp directory and the `watcher` package's testing utilities (or a fake `DirectoryWatcher`) asserting that file changes trigger a debounced `load()` and update `lastSyncedAt`/changed-ids, following the async-stream testing pattern in `agent_run_controller_test.dart`.

---

## Notes

- Visual reference: `kanban-redesign.html` — `.watch-pill`, `.watch-dot` pulse animation, `.badge-new`, icon-only `.icon-btn` for Rescan.
- Glossary: see `CONTEXT.md` for "Watching" vs "Rescan" — Rescan is a fallback, not the primary update path.
- Adds `watcher: ^1.x` to `pubspec.yaml` (desktop platforms — Windows/macOS/Linux — only; mobile/web not required).
- Independent of the dock/drag-and-drop/quick-add work; can be picked up any time.

---

## Log

Added `watcher: ^1.1.0` and a new `IssuesWatcherController` (`lib/features/kanban/domain/controller/issues_watcher_controller.dart`) — a `StreamState<IssuesWatcherStateData>` holding `watching`/`lastSyncedAt`/`changedIds`. It takes an injectable `DirectoryWatcherFactory` (`Stream<String> Function(String path)`, default backed by `package:watcher`'s `DirectoryWatcher`), debounces change events 500ms via `Timer`, then calls `IssuesController.load`, records `lastSyncedAt`, and computes `changedIds` by matching normalized changed paths against `Issue.filePath`. Synchronous factory errors and async stream errors both set `watching: false` without crashing.

New `WatchPill` widget (`presentation/widget/watch_pill.dart`) renders the pulsing dot + "Watching issues/ · synced Xs ago" (ticking via `Timer.periodic`), or an unavailable state when `watching == false`. `_RescanButton` in `app_shell_screen.dart` is now icon-only (32x32, no label). `changedIds` threads through `KanbanSection` → `KanbanColumn` → `IssueCard` as a plain `Set<String>`/`bool isJustUpdated`, rendering a `badge-new`-style "Just updated" badge above the card title.

Tested with a new `issues_watcher_controller_test.dart` using a `FakeIssuesRepository` + `StreamController<String>` (no real filesystem/`fake_async`): covers debounced reload triggering, `lastSyncedAt`/`changedIds` updates, and `watching: false` fallback on both async stream errors and synchronous factory throws (manual `load` still works in both cases). `flutter test test/features/kanban` (65 tests) and `flutter analyze` both pass clean.
- QA approved by user on 2026-06-16.
