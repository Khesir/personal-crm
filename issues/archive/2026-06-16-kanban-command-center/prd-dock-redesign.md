# PRD: Kanban Dock Redesign — 3-Pane Dock, Real Terminal, Issue Delete & Reactive Watch

**Status:** Draft
**Date:** 2026-06-15

---

## Problem Statement

The dock shipped in the previous cycle (issues 001-007, now in QA) works, but a round of follow-up usage surfaced six gaps:

1. There's no way to delete an issue — once a card exists, it's permanent unless edited by hand on disk.
2. The dock's "Terminal" pane is really just a read-only transcript of agent skill runs. It's empty and useless unless a skill happens to be running, and the user can't type into it or run their own commands.
3. When the dock is collapsed, it still shows as a tall strip with the full mode-toggle/collapse tabbar visible — collapsing should make the dock nearly disappear, leaving just a thin handle and a reopen pill.
4. The dock only exists on the Kanban screen. Switching to Bug Reports or Announcements makes it vanish entirely, along with any terminal session or chat conversation in progress.
5. The Chat pane is a straight embed of the full Home chat UI (title, mode toggle, large suggested-prompt cards, roomy spacing) — it doesn't fit well in a panel that's often only a few hundred pixels tall.
6. When the filesystem watcher detects a change to `issues/`, the whole board reloads through the normal loading state, causing a visible flash even though only one card actually changed.

---

## Solution

- Add a delete action to the issue detail view (confirmation required), which removes the issue's file and its card from the board.
- Replace the dock's `terminal`/`chat`/`both` two-pane toggle with three independent panes — **Terminal**, **Agent**, and **Chat** — each can be shown or hidden via its own toggle button (at least one must stay visible), arranged left-to-right with draggable dividers between visible panes.
- **Terminal** becomes a real interactive shell (PTY-backed via `flutter_pty` + `xterm`), scoped to the project's working directory, with session tabs.
- **Agent** is the renamed transcript pane from the previous cycle (live `AgentEvent` stream for skill runs) — unchanged behavior, just renamed and visually distinguished from the new Terminal.
- Collapsing the dock hides the entire tabbar and body, leaving only a thin drag handle plus the existing floating reopen pill; reopening restores the exact pane/size configuration from before collapse.
- The dock becomes an overlay anchored to the bottom of the project's content area, shared across Kanban, Bug Reports, and Announcements — the underlying content never resizes when the dock resizes, collapses, or reopens. The dock is hidden when viewing a read-only/archived Kanban board.
- The Chat pane gets a compact layout: no title/mode-toggle header (just the model switcher), a single-line empty-state prompt instead of suggested-prompt cards, tighter message spacing, and a composer that starts single-line and grows with input.
- Watcher-triggered reloads update the board's data silently (no loading-state flash); only the initial board load shows a spinner.

---

## User Stories

1. As a user, I want to delete an issue from its detail view, so that I can remove issues that are no longer relevant without editing files on disk.
2. As a user, I want to be asked to confirm before an issue is deleted, so that I don't lose work to an accidental click.
3. As a user, after I confirm deletion, I want to be returned to the board with the issue's card gone, so that the board immediately reflects the deletion.
4. As a user, I want a real terminal in the dock, so that I can run shell commands (git, flutter, etc.) without leaving the Kanban board.
5. As a user, I want the Terminal pane scoped to my project's working directory, so commands operate against the right repo by default.
6. As a user, I want to open additional terminal sessions as tabs within the Terminal pane, so I can run different commands side by side.
7. As a user, I want to switch between terminal session tabs, so I can keep multiple shells alive and check on each.
8. As a user, I want to interact with a running command (type input, send Ctrl+C), so I can use the Terminal like a normal shell, including for long-running or interactive processes.
9. As a user, I want the existing agent-run transcript view kept as its own "Agent" pane, so I can still watch a skill run step by step.
10. As a user, I want the Agent pane to keep running in the background when I hide it, so switching panes doesn't interrupt my running task.
11. As a user, I want to independently toggle the Terminal, Agent, and Chat panes on or off, so I can see exactly the combination of panes I need.
12. As a user, I want at least one pane to always remain visible when the dock is open, so the dock is never blank.
13. As a user, I want draggable dividers between whichever panes are currently visible, so I can resize them to fit my workflow.
14. As a user, when I run a skill from the board, I want the Agent pane to automatically appear (and the dock to expand if it was collapsed), so I immediately see the run start.
15. As a user, I want the collapsed dock to be a thin bar with no visible toggle controls, so it takes minimal space when I'm not using it.
16. As a user, I want a floating reopen pill while the dock is collapsed, so I can quickly bring it back.
17. As a user, when I reopen the dock, I want the same panes and divider positions I had before collapsing, so I don't have to reconfigure it every time.
18. As a user, I want the dock to stay visible when I switch between Kanban, Bug Reports, and Announcements, so my terminal session and chat conversation persist across tabs.
19. As a user, I want the dock's height, visible panes, and pane sizes to be shared across all sections of a project, so switching tabs doesn't reset my workspace layout.
20. As a user, I want the board (and other section content) to keep its full size regardless of the dock's height, so resizing the dock never squishes or reflows my content.
21. As a user, I want the dock hidden while viewing a read-only/archived board, so I'm not shown controls that don't apply there.
22. As a user, I want the docked Chat pane to be visually compact, so it fits comfortably in a panel that's often only a few hundred pixels tall.
23. As a user, I want the docked Chat pane's empty state to be a simple one-line prompt instead of large suggested-prompt cards, so it doesn't dominate a small pane.
24. As a user, I want the docked Chat pane's header to show only the model switcher, so there isn't a redundant "Chat" title taking up space.
25. As a user, I want the docked Chat pane's composer to start at one line and grow only as I type more, so it doesn't eat vertical space when idle.
26. As a user, I want the board to update automatically and silently when a file under `issues/` changes externally, so I don't see the whole board flash to a loading state for a one-card change.
27. As a user, I want the "Just updated" badge and the watch pill's "synced Xs ago" to keep working the same way after a silent reload, so I don't lose the existing watching feedback.
28. As a developer, I want `IssuesRepository` to expose a `deleteIssue` method following the same pattern as `updateIssue`/`moveIssue`, so the delete flow fits the existing repository/controller architecture.
29. As a developer, I want the Terminal pane's PTY session management hidden behind an abstraction (not `flutter_pty` types directly), so the controller logic can be unit-tested without a real PTY.
30. As a developer, I want watcher-triggered reloads to go through a distinct, non-loading controller method, so the initial board load and live-update paths are clearly separated.

---

## Implementation Decisions

### 1. Delete issue

- `IssuesRepository` gains `Future<void> deleteIssue(Issue issue)`, implemented by deleting the issue's underlying file.
- `IssuesController` gains `Future<void> deleteIssue(Issue issue)`: calls the repository, then removes the issue from the current in-memory list and re-emits `AsyncData`.
- The issue detail view's header gains a delete action alongside the existing Edit/Move actions.
- Tapping delete opens a confirmation dialog ("Delete issue? This can't be undone." / Cancel / Delete). Confirming calls `IssuesController.deleteIssue` and then triggers the existing "back to board" navigation.
- This is a hard delete — no soft-delete, trash, or recovery flow. Git history is the recovery path if needed.

### 2. Terminal pane (real PTY shell)

- New dependencies (desktop-only: Windows/macOS/Linux): `flutter_pty` for spawning a real PTY-backed process (ConPTY on Windows), and `xterm` for the terminal emulator widget that renders PTY output and forwards keystrokes. Decision recorded in `docs/adr/0004-real-pty-terminal-in-dock.md`.
- A new terminal-session abstraction wraps `flutter_pty`'s process handle behind an interface (output stream, write, resize, kill) so it can be faked in tests, mirroring how `ProcessRunner` abstracts `Process` today.
- A new session controller (StreamState-based) manages a list of terminal sessions ("tabs") for the current project. Each session pairs the PTY abstraction with an `xterm` terminal buffer. Sessions are created lazily, live for the lifetime of the project's shared `DockController` (see Decision 4), and use the project's `localPath` as their working directory.
- The Terminal pane widget renders the active session via `xterm`'s terminal view, plus a row of session tabs (existing "session-tab"/"new tab" styling from the mockup) for creating/switching sessions.
- On platforms without PTY support, the Terminal pane shows an "unavailable" state (consistent with how `WatchPill` communicates an unsupported/unavailable state).

### 3. Agent pane (renamed transcript view)

- The existing transcript widget (currently named `TerminalPane`, rendering `AgentRunController`'s `AgentEvent` stream) is renamed `AgentPane`. Its behavior is unchanged: empty state, idle prompt, live transcript with thinking/tool-use/tool-result/result events and auto-scroll.
- The Agent pane's pane header gains a run indicator (pulsing dot + skill name + elapsed time) shown only while a run is active, replacing the now-removed tabbar "running agent" pill from the previous cycle.
- The Agent pane's visibility (whether it's in the dock's active-pane set) is fully decoupled from `AgentRunController`'s lifecycle: toggling the pane off never calls `stop()`/`background()` on the run. The run only ends when it finishes naturally or is explicitly stopped.

### 4. Dock state — 3-pane toggle, sizing, and collapse

- `DockMode` (`terminal | chat | both`) and `splitFraction`/`setSplitFraction` are replaced by:
  - `enum DockPane { terminal, agent, chat }`
  - `activePanes: Set<DockPane>` — default `{terminal, chat}` (Agent starts hidden until a run begins, per Decision 3's auto-activation).
  - `paneWidthOverrides: Map<DockPane, double>` — an optional fixed pixel width per pane, set by dragging a divider. Panes without an override share the remaining width equally.
- `DockController.togglePane(DockPane pane)` toggles membership in `activePanes`. If `pane` is the only active pane, the call is a no-op — at least one pane must always remain visible.
- `DockController.setPaneWidth(DockPane pane, double widthPx, {required double totalWidthPx})` clamps the requested width so every currently-visible pane keeps at least `dockMinPaneWidth`.
- `dockMinPaneWidth` is lowered from 280px to 240px so a 3-pane layout is feasible at typical window widths.
- Panes render in a fixed left-to-right order — Terminal, Agent, Chat — regardless of activation order. Draggable dividers render only between adjacent *visible* panes (so 1 visible pane → 0 dividers, 2 → 1 divider, 3 → 2 dividers).
- `setAgentRunController` (called when a skill run starts) is generalized: instead of switching `mode`, it adds `DockPane.agent` to `activePanes` (without removing any other active pane) and sets `collapsed = false`.
- A new constant `dockCollapsedHeight` (a small fixed value, e.g. 10px) is introduced for the collapsed state, distinct from `dockMinHeight` (120px), which remains the floor for the *expanded* drag-resize range.
- `collapse()`/`reopen()` only toggle `collapsed`; `activePanes`, `paneWidthOverrides`, and `heightPx` are untouched — reopening automatically restores the prior configuration with no extra bookkeeping.
- When `collapsed`, the dock renders only a thin drag handle (`dockCollapsedHeight` tall) plus the existing floating reopen pill — the tabbar (pane toggles + collapse button) and the dock body are not rendered at all.

### 5. Dock visibility across sections (overlay)

- The dock widget is no longer rendered inside the Kanban section's own layout. It moves up to the project-content container, which already owns the single shared `DockController` instance for the project.
- The project-content container renders the active section's content and the dock widget as siblings in a `Stack`: the section content fills the available space (`Expanded`/`Positioned.fill`), and the dock is `Positioned(left: 0, right: 0, bottom: 0, ...)` as an overlay on top of it. The section content's size never changes as the dock resizes, collapses, or reopens.
- The dock is omitted entirely when the active Kanban view is a read-only archive.
- The Kanban section no longer owns or renders the dock — it goes back to being responsible only for the board grid.

### 6. Compact chat pane

- `HomeChatSection` gains a `compact: bool` parameter, default `false`.
- When `compact: true`:
  - The header renders only the existing model-switcher dropdown — the title row and chat-mode toggle are omitted.
  - The empty state renders a single placeholder line instead of the suggested-prompt cards.
  - Message list spacing/padding uses tighter values.
  - The composer starts at single-line height and grows only as the user types additional lines.
- The dock's Chat pane passes `compact: true`. The Home tab continues to use the default (non-compact) layout.

### 7. Reactive watcher (silent reload)

- `IssuesController` gains a `refresh(String localPath)` method that fetches the current issue list and emits `AsyncData` directly — without first emitting `AsyncLoading()`.
- `IssuesWatcherController`'s debounced reload calls `refresh` instead of `load`. `load` (which does emit `AsyncLoading()`) remains the entry point for the initial board open, where a loading state is appropriate.
- `changedIds` computation (driving the "Just updated" badge) and the watch pill's "synced Xs ago" continue to update the same way after `refresh` completes — no behavior change to that feedback, only to whether a loading flash occurs first.

---

## Testing Decisions

Good tests here exercise controllers/repositories through their public interfaces and assert on observable state (emitted values, in-memory lists, file presence) rather than internals — consistent with the existing suite.

- **Delete issue**:
  - Repository-level test (prior art: `issues_repository_impl_test.dart`, which uses a temp directory) — `deleteIssue` removes the issue's file from disk.
  - Controller-level test (prior art: `issues_controller_test.dart`'s `FakeIssuesRepository`) — `deleteIssue` calls the repository and removes the issue from the emitted list.
  - Widget test on the issue detail view — the delete action shows a confirmation dialog; confirming triggers the delete and returns to the board; cancelling leaves the issue untouched.

- **Terminal pane / session controller**:
  - The session controller is tested against a fake terminal-session implementation (no real `flutter_pty`/OS process) — covers session creation, tab switching, and that new sessions are created with the project's `localPath` as their working directory.
  - `flutter_pty`/`xterm` integration itself is not unit-tested (native, desktop-only) — covered by manual/visual QA instead.

- **Agent pane rename**:
  - Existing tests for the current transcript widget (prior art: `terminal_pane_test.dart`) are renamed/retargeted to the new `AgentPane` widget; behavior assertions (empty state, idle prompt, live transcript) carry over unchanged.

- **Dock state (3-pane toggle, collapse, sizing)**:
  - Extends `dock_state_test.dart` with: `togglePane` toggles membership and is a no-op on the last active pane; `setPaneWidth` clamps to `dockMinPaneWidth` for all visible panes; `collapse`/`reopen` preserve `activePanes`/`paneWidthOverrides`/`heightPx`; `setAgentRunController` adds `DockPane.agent` without removing other active panes and clears `collapsed`.

- **Dock overlay placement**:
  - Widget test on the project-content container — the dock renders for Kanban, Bug Reports, and Announcements sections, and is absent when viewing a read-only/archived Kanban board; the section content's size is unaffected by the dock's height.

- **Compact chat pane**:
  - Widget test on `HomeChatSection` (prior art: `composer_test.dart`) — with `compact: true`, the title/mode-toggle header and suggested-prompt cards are absent and the placeholder empty-state line is shown instead; with `compact: false` (Home tab), the existing layout is unchanged.

- **Reactive watcher**:
  - `issues_controller_test.dart` — `refresh` emits `AsyncData` directly (no `AsyncLoading` emission) and updates the issue list from the repository.
  - `issues_watcher_controller_test.dart` — the debounced reload path calls `refresh` rather than `load`.

---

## Out of Scope

- Soft-delete, trash, or any recovery mechanism for deleted issues.
- Mobile/web support for the Terminal pane (PTY is desktop-only by construction; see ADR 0004).
- Persisting terminal sessions across app restarts.
- Per-file/targeted patch reloads from the watcher (this PRD only removes the loading-state flash; the watcher still re-reads the whole `issues/` directory).
- An independent timeout-based clear for the "Just updated" badge (flagged separately in the prior QA report — not addressed here).
- Resizable minimum pane widths beyond the fixed `dockMinPaneWidth` constant.

---

## Further Notes

- This PRD is a follow-up to `issues/prd.md` (the original dock cycle, issues 001-007, currently in `issues/qa/`). It does not modify that PRD or its issues.
- `CONTEXT.md` already includes the glossary entries this PRD depends on: **Dock**, **Terminal** (dock pane), and **Agent pane** (dock pane).
- `docs/adr/0004-real-pty-terminal-in-dock.md` documents the `flutter_pty` + `xterm` decision referenced in Decision 2.
- `kanban-redesign.html` was updated during the grilling session to reflect the 3-pane layout (overlay dock, thin collapsed bar, independent Terminal/Agent/Chat toggles with draggable dividers, compact chat pane) and is the visual reference for this PRD.
