---
id: issue-001
title: "Dock shell: resizable, collapsible bottom dock with mode toggle"
feature: kanban
status: done
created_at: 2026-06-15
tags: [afk, p1]
---

# [001] Dock shell: resizable, collapsible bottom dock with mode toggle

**Type:** AFK
**Priority:** P1
**Blocked by:** None
**User stories covered:** 12, 13, 14, 15, 16, 17, 18

---

## What to build

A bottom dock anchored to the Projects > Kanban board, matching the layout in `kanban-redesign.html`. The dock contains a tabbar (collapse control, mode toggle), a resize handle on its top edge, two side-by-side panes with a draggable internal split, and a floating "reopen" pill shown when collapsed.

For this slice, the panes can contain placeholder content (e.g. a labeled empty container for "Terminal" and "Chat") — issues 004 and 005 wire in the real Terminal and Chat panes. The goal here is the dock's structural/interaction shell working end-to-end and visible on the board.

New `StreamState` (`DockState` or similar) holds:
- `heightPx` — current dock height
- `collapsed` — bool
- `mode` — `terminal` | `chat` | `both`
- `splitFraction` — terminal pane's share of width in `both` mode

This state is scoped to the kanban section's widget lifetime (no persistence across app restarts).

---

## Acceptance criteria

- [x] Dock renders anchored to the bottom of the Projects > Kanban board, below the board's columns.
- [x] Dragging the dock's top edge resizes its height, clamped to a sensible min/max (matching the mockup's `--dock-min` / `--dock-max` intent).
- [ ] A collapse control shrinks the dock to a thin bar; a floating "reopen" pill appears showing the active task name + elapsed time (placeholder text if no run is active) and restores the dock on tap.
- [x] Mode toggle switches between Terminal-only, Chat-only, and Both (split) layouts.
- [x] In "Both" mode, a draggable divider between the two panes resizes their relative widths, clamped to a minimum width per pane.
- [x] Dock state (height, collapsed, mode, split fraction) persists while navigating within the session but does not need to survive app restart.

---

## Tests required

Yes — unit tests for the dock's `StreamState`: collapse/reopen toggling, mode switching, and height/split clamping logic, independent of widgets (per PRD Testing Decisions).

---

## Notes

- Visual reference: `kanban-redesign.html` (repo root) — dock tabbar, resize handle, mode toggle, split divider, reopen pill.
- Use `AppColors`/`AppStyling` tokens; do not introduce new hardcoded colors/spacing.
- This issue blocks 004 (Terminal pane) and 005 (Chat pane), which fill in the dock's panes with real content.

---

## Log

_Updated as work progresses._

QA approved by user on 2026-06-16.

Implemented `DockController`/`DockStateData` (`lib/features/kanban/presentation/state/dock_state.dart`) with `setHeight` (clamped 120-800px), `collapse`/`reopen`, `setMode` (terminal/chat/both), and `setSplitFraction` (clamped to a 280px minimum pane width). Added `BoardDockSection` (`lib/features/kanban/presentation/section/board_dock_section.dart`) with a drag-to-resize handle, tabbar with mode toggle + collapse/reopen control, placeholder Terminal/Chat panes with a draggable divider in "both" mode, and a floating reopen pill when collapsed. Wired into `KanbanSection` below the board columns.

Tested: 10 new unit tests for `DockController` covering default state, collapse/reopen, mode switching, and height/split clamping at both ends — all green (`flutter test test/features/kanban/`, 47/47 passing). `flutter analyze` clean on both new files and the full `kanban` feature.