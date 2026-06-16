# PRD: Kanban Command Center — Integrated Dock, Drag-and-Drop, Quick-Add & Watching

**Status:** Draft
**Date:** 2026-06-15

---

## Problem Statement

The Projects > Kanban board is currently a static, read-mostly view:

- Cards cannot be moved between columns by dragging — there is no way to change an issue's status directly from the board.
- There is no way to create a new issue from the board itself; per-column creation is not exposed in the UI.
- The board only updates when the user presses "Rescan" — there is no live indication that the board reflects what's on disk, even though Claude Code skill runs can write new `.md` files at any time.
- Running a skill opens a full-screen `AgentRunScreen` overlay that hides the board and the Home chat (Avyn) entirely, so the user can't watch the board update or ask Avyn a question while a skill runs.
- The visual design doesn't match the app's `AppColors`/`AppStyling` tokens as closely as it could, and the Home chat composer has a redundant model-switcher dropdown.

## Solution

Redesign the Projects > Kanban section to match the agreed `kanban-redesign.html` mockup:

- **Drag-and-drop**: kanban cards can be dragged between columns; dropping a card updates the issue's status on disk via the existing `moveIssue` flow, with lift/shadow feedback and a drop placeholder showing where the card will land.
- **Inline quick-add**: each column header gets a "+" button that opens an inline title field; pressing Enter creates a new issue file directly in that column's status folder.
- **Bottom dock**: a resizable, collapsible dock anchored to the bottom of the kanban board hosts a Terminal pane and a Chat (Avyn) pane side by side, with a draggable internal split between them, a mode toggle (Terminal-only / Chat-only / Both), and a floating "reopen" pill when collapsed.
- **Terminal pane**: styled as a real terminal (monospace, dark background, ANSI-style colors, blinking cursor, session info) and driven by the existing agent-run event stream — when a skill is run from the Kanban board, its transcript renders here instead of (or in addition to) the full-screen overlay.
- **Chat pane**: embeds the existing Home chat (Avyn) experience, scoped to the working project, with a single model-switcher in the pane header (the composer's duplicate dropdown is removed).
- **Watching**: a real filesystem watcher on `issues/<status>/*.md` automatically reloads the board (debounced ~500ms) and shows a pulsing "Watching issues/ · synced Xs ago" pill; "Rescan" becomes a small icon-only fallback button.
- **Visuals**: columns and cards adopt the status-dot colors, spacing, and radii from `AppColors`/`AppStyling` as used in the mockup, including a "just updated" badge for cards changed by the watcher since the last sync.

---

## User Stories

### Drag-and-drop
1. As a user, I want to drag a kanban card from one column to another, so that the issue's status updates without opening a dialog.
2. As a user, I want the dragged card to lift visually (shadow, slight rotation/scale), so that I can tell which card is being moved.
3. As a user, I want a dashed placeholder to appear in the target column showing where the card will land, so that I can position it precisely.
4. As a user, I want column counts to update immediately after a drop, so that the board stays accurate at a glance.
5. As a user, if the underlying file move fails, I want the card to return to its original column, so that the board never shows a state that doesn't match disk.
6. As a user, I want dragging to work with mouse-based pointer input on desktop, so that the interaction matches a native desktop app.

### Quick-add
7. As a user, I want to click "+" on a column header, so that an inline input appears for a new issue title.
8. As a user, I want to press Enter to create the issue, so that it's written to disk in that column's status folder immediately.
9. As a user, I want Esc or clicking away to cancel the quick-add, so that I don't accidentally create empty issues.
10. As a user, I want the newly created issue to get a generated id and `created_at`, so that it's a valid issue file matching the existing frontmatter format.
11. As a user, I want the new card to appear in the correct column immediately after creation, so that I don't need to rescan to see it.

### Dock layout
12. As a user, I want the Terminal and Chat panels docked at the bottom of the kanban board, so that I can monitor agent runs and chat with Avyn without leaving the board.
13. As a user, I want to drag the dock's top edge to resize its height, so that I can balance space between the board and the dock.
14. As a user, I want to collapse the dock to a thin bar, so that the board can use the full vertical space.
15. As a user, I want a floating "reopen" pill showing the running task's name and elapsed time when the dock is collapsed, so that I know work is still happening in the background.
16. As a user, I want to toggle between Terminal-only, Chat-only, and split (both) layouts, so that I can focus on whichever pane I need.
17. As a user, I want to drag a divider between the Terminal and Chat panes in split mode to resize their relative widths, so that I can give more room to whichever I'm using.
18. As a user, I want the dock's height, mode, and split ratio to persist while I navigate within the same session, so that I don't have to re-configure it constantly.

### Terminal pane
19. As a user, I want the Terminal pane to look like a real terminal (monospace font, near-black background, ANSI-style colored output, blinking cursor), so that it feels familiar when watching Claude Code work.
20. As a user, I want the Terminal pane to show the live event stream of the currently running agent skill (thinking, tool use, tool result, final result) styled as a transcript, so that I can follow along without leaving the board.
21. As a user, I want the Terminal pane to show an idle prompt (e.g. `➜ personal-crm`) with a blinking cursor when no skill is running, so that it still reads as a real terminal shell.
22. As a user, when no skill has ever been run for this project, I want the Terminal pane to show a helpful empty state explaining how to start one, so that the panel isn't confusing on first use.
23. As a user, I want starting a skill from the Kanban board to route its output into the dock's Terminal pane (switching the dock to Terminal or Both mode and expanding it if collapsed), so that I see it immediately.

### Chat pane
24. As a user, I want the Chat pane in the dock to show the same Avyn assistant as the Home tab, scoped to the working project, so that I can ask questions about the board's issues.
25. As a user, I want the model switcher to appear only once, in the pane header, so that the composer isn't cluttered with a duplicate dropdown.
26. As a user, I want to send messages and see streaming responses in the dock's chat pane, so that the experience matches the Home chat tab.
27. As a user, I want the chat pane's visual style (bubbles, assistant cards) to feel cleaner and less cluttered than the current Home tab, per the agreed mockup.

### Watching / Rescan
28. As a user, I want the board to automatically refresh when files under `issues/<status>/` change on disk, so that I don't have to manually rescan after a skill run finishes.
29. As a user, I want a pulsing "Watching issues/" indicator with a "synced Xs ago" timestamp, so that I can trust the board reflects the current disk state.
30. As a user, I want rapid successive file writes (e.g. during a skill run) to be debounced (~500ms) before the board reloads, so that the UI doesn't thrash.
31. As a user, I want a small icon-only "Rescan" button as a manual fallback, so that I can force a refresh if watching ever misses a change.
32. As a user, I want cards that changed since the last sync to show a "Just updated" badge, so that I can spot what the watcher just picked up.
33. As a user, when the watcher fails to start (e.g. unsupported platform/path), I want the "Watching" pill to indicate it's unavailable and fall back to manual "Rescan" only, so that the board still functions.

### Visual consistency
34. As a user, I want kanban columns and cards to use the `AppColors`/`AppStyling` tokens (status-dot colors, spacing, radii, fonts) shown in the mockup, so that the board feels consistent with the rest of the app.

---

## Implementation Decisions

### Kanban board (`lib/features/kanban`)

- **Drag-and-drop**: `IssueCard` becomes draggable (`Draggable<Issue>` / `LongPressDraggable` for desktop pointer drag), and `KanbanColumn`'s list becomes a `DragTarget<Issue>`. On accept, call the existing `IssuesController.moveIssue(issue, newStatus)`. The controller updates local state optimistically; if `repository.moveIssue` throws, the controller reverts to the previous list and surfaces an error (e.g. via a transient inline message).
- **Quick-add**: new reusable widget (`presentation/widget/quick_add_field.dart`) rendered inline at the top of each `KanbanColumn`'s body, toggled by the existing "+" affordance in the column header. On submit, calls `IssuesController.createIssue(localPath, issue)` with `issue.status` set to that column's `IssueStatus`.
- **`IssuesRepositoryImpl.createIssue`**: currently always writes into the `backlog/` folder regardless of `issue.status`. Change it to write into the folder matching `issue.status` (via the existing `_statusFolders` map), so quick-add creates the file directly in the target column without a separate move.
- **Watching**: add a new `watcher` package dependency (`watcher: ^1.x`, `DirectoryWatcher`) used by a new controller/state (e.g. `IssuesWatcherController` or an extension of `IssuesController`) that watches `{localPath}/issues/` recursively, debounces events by 500ms, then calls `load(localPath)` and records `lastSyncedAt` plus the set of issue ids that changed in that reload (for the "Just updated" badge). If the watcher fails to initialize (platform/path error), the controller exposes a `watching: false` flag so the UI falls back to manual rescan only.
- **Watch pill / Rescan**: new `presentation/widget/watch_pill.dart` renders the pulsing dot + "Watching issues/" + "synced Xs ago" (computed from `lastSyncedAt`, ticking on a timer). The existing `_RescanButton` becomes icon-only (no label) and is visually demoted, calling the same `_rescan()` → `issuesController.load(localPath)`.
- **Card/column visuals**: update `KanbanColumn` and `IssueCard` to match the mockup's spacing/radii/status-dot colors via `AppColors`/`AppStyling` (no new tokens — confirm any missing tokens exist before adding new ones).

### Dock (new section within `kanban` feature)

- New `presentation/section/board_dock_section.dart` — the bottom dock containing the tabbar (active/backgrounded agent runs), mode toggle (terminal/chat/both), resize handle, collapse/reopen control, and the two panes.
- New `presentation/state/dock_state.dart` — a `StreamState` holding `heightPx`, `collapsed`, `mode` (`terminal` | `chat` | `both`), and `splitFraction` (terminal pane's share of width in `both` mode). Pure UI state, scoped to the `_ProjectsContent` widget's lifetime (resets on app restart unless the user asks for persistence later).
- New `presentation/widget/terminal_pane.dart` — renders the active `AgentRunController`'s `AgentEvent` stream as a styled transcript, reusing the existing event-to-row mapping from `EvThinking`/`EvTool` but restyled with terminal colors/monospace font. Shows an idle prompt with a blinking cursor when `AgentRunStatus` is not `running`, and an empty-state message when no run has ever started for this project.
- New `presentation/widget/chat_pane.dart` — wraps `HomeChatSection`/`ChatController`, scoped to the working project, with the composer's model-switcher dropdown hidden (only the pane-header switcher remains).
- **Routing agent runs into the dock**: when a skill is started from the Kanban board (`onRunSkill` in `_ProjectsContent`/`AppShellScreen`), instead of showing the full-screen `AgentRunScreen` overlay, the same `AgentRunController` is handed to `BoardDockSection`'s terminal pane, and the dock auto-expands and switches to `terminal` or `both` mode. `AgentRunScreen`'s full-screen overlay remains available for skill runs triggered from contexts without a dock (e.g. Bug Reports), reusing the same `AgentRunController`.

### Home chat (`lib/features/home`)

- `Composer` (`presentation/widget/composer.dart`) gains a way to omit its model-switcher dropdown (e.g. a constructor flag), since the canonical model switcher now lives in the pane header for both the dock's chat pane and, for consistency, the Home tab.

### Dependencies

- Add `watcher: ^1.x` to `pubspec.yaml` for filesystem watching (already discussed and approved).

---

## Testing Decisions

Tests should verify externally observable behavior (controller state, repository file output, widget interactions) rather than internal implementation details.

- **`IssuesRepositoryImpl.createIssue`** (`test/features/kanban/data/repository/issues_repository_impl_test.dart`): extend existing tests to assert a created issue with `status: ready` (etc.) is written into the corresponding folder (`issues/ready/`), not always `backlog/`.
- **`IssuesController`** (`test/features/kanban/domain/controller/issues_controller_test.dart`): extend with a test that `moveIssue` reverts local state when `repository.moveIssue` throws (drag-and-drop revert behavior).
- **New issues-watcher controller**: new test file under `test/features/kanban/domain/controller/`, using a temp directory and the `watcher` package's testing utilities (or a fake `DirectoryWatcher`) to assert that file changes trigger a debounced `load()` and update `lastSyncedAt`/changed-ids. Follows the async-stream testing pattern in `agent_run_controller_test.dart`.
- **`DockState`**: new unit test for the dock's `StreamState` — collapse/reopen toggling, mode switching, and height/split clamping logic, independent of widgets.
- **Drag-and-drop widget test**: new widget test for `KanbanColumn`/`IssueCard` simulating a drag gesture into another column's `DragTarget` and asserting `IssuesController.moveIssue` is invoked with the correct target status.
- **Quick-add widget test**: new widget test asserting Enter with non-empty text calls `IssuesController.createIssue` with the column's status, and Esc/blur does not.
- **Terminal pane**: widget test rendering a fixed list of `AgentEvent`s and asserting the transcript renders without overflow/error, plus an idle-state render when `AgentRunStatus.stopped`/no controller.
- **Composer flag**: extend `chat_mode_toggle_test.dart`-style widget tests (or a new `composer_test.dart`) to assert the model-switcher dropdown is absent when the new flag is set.

---

## Out of Scope

- **Literal terminal / subprocess `claude` CLI**: running an actual shell or `claude` CLI process inside the Terminal pane (PTY integration, raw stdin/stdout) is a separate, larger effort. This PRD only covers styling the Terminal pane to look like a real terminal and feeding it the existing `AgentRunController` event stream.
- **Multiple terminal sessions / session tabs for distinct shells**: the mockup shows session tabs (`claude`, `bash`); this PRD does not implement multiple independent terminal sessions. At most, the dock shows the current (and any backgrounded) agent run(s).
- **Persisting dock layout** (height, mode, split ratio) across app restarts.
- **Cross-platform filesystem watcher edge cases** beyond Windows/macOS/Linux desktop (e.g. network drives, WSL path translation) — best-effort only, with manual "Rescan" as the fallback.
- **Bug Reports / Announcements sections**: no changes to those sections beyond what's needed to keep `AgentRunScreen`'s full-screen overlay working for skill runs triggered from them.
- **Reordering cards within the same column** (only cross-column status changes are in scope, matching the existing `moveIssue` contract).

---

## Further Notes

- The `watcher` package dependency should be added with the minimum version needed for `DirectoryWatcher` on desktop platforms (Windows/macOS/Linux); mobile/web support is not required since this feature targets the desktop "Command Center" experience.
- The "Just updated" badge's changed-id set only needs to live for the current session (e.g. cleared on next watcher cycle or after a short timeout) — no persistence required.
- Visual reference: `kanban-redesign.html` (repo root) is the agreed mockup for layout, spacing, and interaction details; `lib/core/theme/app_colors.dart` and `app_styling.dart` remain the source of truth for actual token values used in the Flutter implementation.
