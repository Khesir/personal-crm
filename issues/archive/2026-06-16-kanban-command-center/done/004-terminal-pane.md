---
id: issue-004
title: "Terminal pane: live agent-run transcript in the dock"
feature: kanban
status: done
created_at: 2026-06-15
tags: [afk, p1]
---

# [004] Terminal pane: live agent-run transcript in the dock

**Type:** AFK
**Priority:** P1
**Blocked by:** 001
**User stories covered:** 19, 20, 21, 22, 23

---

## What to build

Build the dock's Terminal pane and wire it to the existing agent-run pipeline:

- Styled as a real terminal: monospace font, near-black background, ANSI-style colored text, blinking cursor — per `kanban-redesign.html`.
- When an `AgentRunController` is active for the working project, the Terminal pane renders its `AgentEvent` stream (thinking, tool use, tool result, final result) as a live transcript, reusing the existing event-to-row logic from `EvThinking`/`EvTool` but restyled for the terminal.
- When no skill is running, show an idle prompt (e.g. `➜ personal-crm`) with a blinking cursor.
- When no skill has ever been run for this project (no controller yet), show an empty-state message explaining how to start one.
- Starting a skill from the Kanban board routes its `AgentRunController` into the dock's Terminal pane instead of the full-screen `AgentRunScreen` overlay, and the dock auto-expands (if collapsed) and switches to `terminal` or `both` mode. `AgentRunScreen`'s full-screen overlay remains available for skill runs triggered from contexts without a dock (e.g. Bug Reports), reusing the same `AgentRunController`.

---

## Acceptance criteria

- [x] Terminal pane uses monospace font, dark background, and ANSI-style colored spans matching the mockup's terminal styling.
- [x] While an agent run is active, the pane shows its live `AgentEvent` stream as a transcript (thinking/tool-use/tool-result/result), scrolling to follow new output.
- [x] When no run is active, the pane shows an idle prompt with a blinking cursor.
- [x] When no run has ever started for the current project, the pane shows an empty-state message instead of a bare prompt.
- [x] Starting a skill from the Kanban board sends its output to the dock's Terminal pane (auto-expanding/switching mode as needed) instead of opening the full-screen `AgentRunScreen` overlay.
- [x] Skill runs started from Bug Reports (or other non-dock contexts) still use the full-screen `AgentRunScreen` overlay, unchanged.

---

## Tests required

Yes — widget test rendering a fixed list of `AgentEvent`s in the Terminal pane and asserting the transcript renders without overflow/error, plus a render test for the idle and empty states (no controller / `AgentRunStatus.stopped`).

---

## Notes

- Visual reference: `kanban-redesign.html` — `.terminal-pane`, `.t-prompt`, `.t-tool`, `.t-result`, `.cursor` blink animation.
- A literal subprocess/PTY terminal (running `claude` CLI directly) is out of scope for this issue and the PRD as a whole — this pane only displays the existing `AgentRunController`/`AgentEvent` stream with terminal styling.
- Depends on issue 001 for the dock shell/pane container to exist.

---

## Log

Implemented `TerminalPane` (terminal-styled transcript, idle prompt with blinking cursor, empty state) and `BoardDockSection`/`DockController` hosting it in `KanbanSection`. Wired `_ProjectsContentState`'s "Run skill" button to pass a shared `DockController` through `onRunSkill`, routing the `AgentRunController` into the dock's Terminal pane (auto-expanding/switching mode) instead of the full-screen overlay; Bug Reports' `onRunSkill` call is unchanged (no `dock` arg) and still uses `AgentRunScreen`. Added `terminal_pane_test.dart` covering empty state, idle prompt, and transcript rendering. `flutter test test/features/kanban` (61 tests) and `flutter analyze` on touched files pass.
- QA approved by user on 2026-06-16.
