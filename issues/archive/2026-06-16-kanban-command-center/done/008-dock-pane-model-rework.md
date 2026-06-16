---
id: issue-008
title: "Dock pane model rework: 3-pane toggle, overlay hoist, thin collapse, Agent pane rename"
feature: kanban
status: done
created_at: 2026-06-15
tags: [afk, p1]
---

# 008 Dock pane model rework: 3-pane toggle, overlay hoist, thin collapse, Agent pane rename

**Type:** AFK
**Priority:** P1
**Blocked by:** None
**User stories covered:** 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21

---

## What to build

Replace the dock's current `terminal`/`chat`/`both` mode toggle with three independent panes — **Terminal**, **Agent**, and **Chat** — each shown or hidden via its own toggle, and make the dock a shared overlay visible across all project sections (Kanban, Bug Reports, Announcements), not just Kanban.

State model (`DockController`/`DockStateData`):
- Replace `DockMode` and `splitFraction`/`setSplitFraction` with:
  - `enum DockPane { terminal, agent, chat }`
  - `activePanes: Set<DockPane>`, default `{terminal, chat}`
  - `paneWidthOverrides: Map<DockPane, double>` — optional fixed pixel width per pane; panes without an override share remaining width equally
- `togglePane(DockPane pane)` toggles membership in `activePanes`; no-op if `pane` is the only active pane (at least one pane must stay visible)
- `setPaneWidth(DockPane pane, double widthPx, {required double totalWidthPx})` clamps so every visible pane keeps at least `dockMinPaneWidth` (lower this constant from 280px to 240px)
- `setAgentRunController` adds `DockPane.agent` to `activePanes` (without removing other active panes) and sets `collapsed = false`, instead of switching `mode`
- New constant `dockCollapsedHeight` (small, e.g. 10px) for the collapsed state, distinct from `dockMinHeight` (120px), which remains the floor for the expanded drag-resize range
- `collapse()`/`reopen()` only toggle `collapsed` — `activePanes`, `paneWidthOverrides`, and `heightPx` are untouched, so reopening restores the exact prior configuration

Dock UI (`BoardDockSection` and friends):
- Replace the mode-toggle with three pane-toggle buttons (Terminal, Agent, Chat)
- Panes render left-to-right in fixed order (Terminal, Agent, Chat); draggable dividers render only between adjacent *visible* panes (0 panes visible besides one → no dividers, 2 visible → 1 divider, 3 visible → 2 dividers)
- When `collapsed`, render only a thin drag handle (`dockCollapsedHeight` tall) plus the existing floating reopen pill — the tabbar (pane toggles + collapse button) and dock body are not rendered at all
- The reopen pill shows the active task/elapsed time when a run is active (carrying forward the fix for the known gap from issue 001's QA), falling back to placeholder text otherwise

Overlay hoist:
- Move the dock widget out of the Kanban section's own layout and render it in the shared project-content container (which already owns the single `DockController` instance per project) as a `Stack` overlay: section content fills the available space and never resizes as the dock resizes/collapses/reopens; the dock is `Positioned` at the bottom on top of it
- The dock is omitted entirely when the active Kanban view is a read-only archive
- The Kanban section no longer owns or renders the dock

Agent pane rename:
- Rename the existing transcript widget (currently rendering `AgentRunController`'s `AgentEvent` stream) from `TerminalPane` to `AgentPane` — no behavior change beyond the rename and the pane-toggle wiring
- Add a run indicator (pulsing dot + skill name + elapsed time) to the Agent pane's header, shown only while a run is active, replacing the removed tabbar "running agent" pill
- The Agent pane's visibility is fully decoupled from `AgentRunController`'s lifecycle: toggling it off never calls `stop()`/`background()`

Note: the **Terminal** pane toggle is introduced by this issue as a slot in the new 3-pane layout, but its content remains the existing placeholder/empty state until issue 009 replaces it with a real PTY shell. Do not attempt to build the PTY terminal here.

---

## Acceptance criteria

- [ ] Dock shows three independent pane toggles: Terminal, Agent, Chat
- [ ] Clicking a toggle shows/hides that pane; clicking the last remaining visible pane's toggle is a no-op
- [ ] Visible panes render left-to-right in fixed order (Terminal, Agent, Chat) with draggable dividers between adjacent visible panes only
- [ ] Resizing a divider clamps so all visible panes keep at least `dockMinPaneWidth` (240px)
- [ ] Collapsing the dock leaves only a thin drag handle and the floating reopen pill — no tabbar or pane content visible
- [ ] Reopening the dock restores the exact panes/widths/height from before collapsing
- [ ] The reopen pill shows the active skill name and elapsed time when a run is active, and placeholder text otherwise
- [ ] The dock is visible (same instance/state) when switching between Kanban, Bug Reports, and Announcements
- [ ] The dock is not rendered when viewing a read-only/archived Kanban board
- [ ] The board (and other section content) keeps its full size regardless of the dock's height, collapse, or reopen state
- [ ] Starting a skill run adds the Agent pane to the visible set (without hiding Terminal/Chat) and expands the dock if collapsed
- [ ] The Agent pane (renamed from the prior transcript pane) retains its empty state, idle prompt, live transcript, and auto-scroll behavior
- [ ] Hiding the Agent pane does not stop or background the underlying agent run

---

## Tests required

Yes — extend `dock_state_test.dart` with: `togglePane` toggles membership and is a no-op on the last active pane; `setPaneWidth` clamps to `dockMinPaneWidth` for all visible panes; `collapse`/`reopen` preserve `activePanes`/`paneWidthOverrides`/`heightPx`; `setAgentRunController` adds `DockPane.agent` without removing other active panes and clears `collapsed`. Rename/retarget the existing transcript widget tests (prior art: `terminal_pane_test.dart`) to the new `AgentPane` widget, keeping their behavior assertions. Add a widget test on the project-content container verifying the dock renders for Kanban, Bug Reports, and Announcements, and is absent for a read-only/archived Kanban view, with section content size unaffected by dock height.

---

## Notes

This is the foundational slice for the dock redesign — issues 009 and 010 build on the new `DockPane`/`activePanes` model and the restructured `BoardDockSection`. Follow the existing `StreamState`/`DockController` patterns in `dock_state.dart`. See `issues/prd-dock-redesign.md` (Implementation Decisions 3, 4, 5) and `CONTEXT.md`'s **Dock**, **Terminal**, and **Agent pane** glossary entries.

---

## Log

_Updated as work progresses._

- Reworked `dock_state.dart`: `DockPane` enum (terminal/agent/chat), `activePanes`/`paneWidthOverrides`, `togglePane`, `setPaneWidth` (clamped to `dockMinPaneWidth=240`), `dockCollapsedHeight`, generalized `setAgentRunController`/`collapse`/`reopen`. Rewrote `board_dock_section.dart` for the 3-pane toggle layout, thin collapsed handle, and a reopen pill that shows live skill/elapsed time via `AgentRunController`.
- Renamed `terminal_pane.dart`/`TerminalPane` -> `agent_pane.dart`/`AgentPane` with a pulsing-dot run indicator in its header; added a new placeholder `TerminalPane` for the Terminal slot. Hoisted `BoardDockSection` out of `kanban_section.dart` into a new reusable `ProjectContentDockOverlay` rendered by `app_shell_screen.dart`'s `_ProjectsContent`, omitted via `shouldShowProjectDock` for read-only/archived Kanban views.
- Tests: rewrote `dock_state_test.dart` (17 tests) and `agent_pane_test.dart` (5 tests, renamed from `terminal_pane_test.dart`), added `project_content_dock_overlay_test.dart` and `shouldShowProjectDock` cases in `shell_controller_test.dart`. Full `flutter test` (431 tests) and `flutter analyze` pass.
- QA approved by user on 2026-06-16.
