---
id: issue-009
title: "Real PTY terminal pane (flutter_pty + xterm)"
feature: kanban
status: done
created_at: 2026-06-15
tags: [afk, p1]
---

# 009 Real PTY terminal pane (flutter_pty + xterm)

**Type:** AFK
**Priority:** P1
**Blocked by:** 008
**User stories covered:** 4, 5, 6, 7, 8, 29

---

## What to build

Make the dock's Terminal pane a real interactive shell, scoped to the project's working directory, with session tabs — replacing the placeholder content from issue 008.

- Add new dependencies (desktop-only: Windows/macOS/Linux): `flutter_pty` (spawns a real PTY-backed process, ConPTY on Windows) and `xterm` (terminal emulator widget rendering PTY output and forwarding keystrokes). These were approved during grilling — see `docs/adr/0004-real-pty-terminal-in-dock.md`.
- Introduce a terminal-session abstraction wrapping the PTY process (output stream, write, resize, kill) behind an interface, so it can be faked in tests — mirroring how `ProcessRunner` abstracts `Process` today.
- Introduce a session controller (StreamState-based) managing a list of terminal sessions ("tabs") for the current project. Sessions are created lazily, live for the lifetime of the project's shared `DockController`, and use the project's `localPath` as their working directory.
- Build the Terminal pane UI: renders the active session via `xterm`'s terminal view, plus a row of session tabs for creating/switching sessions (per the "session-tab"/"new tab" styling in `kanban-redesign.html`).
- On platforms without PTY support, show an "unavailable" state (consistent with `WatchPill`'s unavailable state).

---

## Acceptance criteria

- [ ] The Terminal pane renders a live, interactive shell using `xterm`, backed by a real PTY process via `flutter_pty`
- [ ] The shell's working directory is the current project's `localPath`
- [ ] The user can type commands and see live output, including for long-running processes
- [ ] The user can send interrupt signals (e.g. Ctrl+C) to a running command
- [ ] The Terminal pane shows a row of session tabs; clicking "new tab" creates an additional session, and clicking a tab switches the active session
- [ ] Each session's output/buffer persists while switching tabs (not destroyed on tab switch)
- [ ] On a platform without PTY support, the Terminal pane shows an "unavailable" state instead of attempting to spawn a PTY

---

## Tests required

Yes — the session controller is tested against a fake terminal-session implementation (no real `flutter_pty`/OS process): covers session creation, tab switching, and that new sessions use the project's `localPath` as their working directory. `flutter_pty`/`xterm` integration itself is not unit-tested (native, desktop-only) — covered by manual/visual QA instead.

---

## Notes

Depends on issue 008's `DockPane.terminal` slot in the restructured dock. See `issues/prd-dock-redesign.md` (Implementation Decision 2) and `docs/adr/0004-real-pty-terminal-in-dock.md` for the dependency decision and alternatives considered.

---

## Log

_Updated as work progresses._

- Added `flutter_pty` and `xterm` dependencies. Introduced `TerminalSession` (interface, `lib/features/kanban/domain/repository/terminal_session.dart`) with a real `PtyTerminalSession` impl (`lib/features/kanban/data/repository/pty_terminal_session.dart`), and `TerminalSessionController` (`lib/features/kanban/presentation/state/terminal_session_controller.dart`) managing session "tabs" each pairing a `TerminalSession` with an `xterm` `Terminal` buffer. `_ProjectsContentState` in `app_shell_screen.dart` owns the controller per-project (recreated on `localPath` change, disposed in `dispose()`), threaded through `ProjectContentDockOverlay` → `BoardDockSection` → `_DockBody` → `TerminalPane`. Rebuilt `terminal_pane.dart` with a real `xterm` `TerminalView`, session-tab row (per `kanban-redesign.html`'s `.session-tab`/`.new-tab-btn` styling), and an "unavailable" pill state (via `isPtySupported()`, mirroring `WatchPill`'s unavailable visual language) for platforms without PTY support.
- Tests: new `test/features/kanban/presentation/state/terminal_session_controller_test.dart` covers session creation, multi-tab creation, tab switching (including no-op on unknown id), working-directory propagation from the project's `localPath`, and dispose killing all sessions — all against a `FakeTerminalSession` (no real PTY). `flutter test test/features/kanban` passes (89/89). `flutter analyze` clean (2 pre-existing unrelated deprecation infos). `flutter pub get` succeeds with new deps.
- Per the issue's testing decisions, `flutter_pty`/`xterm` integration (live shell I/O, Ctrl+C interrupts, resize, real PTY rendering) is NOT unit-tested — covered by manual/visual QA only.
- QA approved by user on 2026-06-16.
