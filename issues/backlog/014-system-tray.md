---
id: issue-014
title: "System tray — minimize to tray, tray menu"
feature: agent
status: backlog
created_at: 2026-06-16
tags: [afk, p2]
---

# [014] System tray — minimize to tray, tray menu

**Type:** AFK
**Priority:** P2
**Blocked by:** 013
**User stories covered:** 23, 24, 25, 26, 27, 28

---

## What to build

Add Windows system tray support to Avyn using `tray_manager`. The tray icon represents the full app — not just the agent server.

Behaviour when closing the window:
- If an agent loop is **active** → minimise to tray instead of quitting. The window hides; the tray icon appears.
- If no loop is active → call `POST /shutdown` and exit normally.

Tray icon and menu:
- Icon reflects agent status: a static icon when idle, a pulsing or distinct icon when a loop is running
- Tray menu items:
  - **Open Avyn** — restores the window
  - **Agent: Running / Idle** — non-interactive status label
  - **Stop agent** — calls `AgentController.stop()` and cancels the active loop (only visible when running)
  - **Quit** — calls `POST /shutdown` and exits regardless of loop state

Intercept the OS window close event. When a loop is active, suppress the close and minimise to tray instead. Show a tooltip or brief notification the first time this happens so the user understands why the window did not close.

---

## Acceptance criteria

- [ ] Closing the window while a loop is active minimises to tray
- [ ] Closing the window with no active loop shuts down cleanly
- [ ] Tray icon is visible in the Windows system tray while Avyn is minimised
- [ ] Tray icon reflects agent status (running vs idle)
- [ ] "Open Avyn" restores the window
- [ ] "Stop agent" cancels the active loop
- [ ] "Quit" shuts down server and exits regardless of loop state
- [ ] First minimise-to-tray shows a user-facing hint

---

## Tests required

Yes — widget test:
- Assert close event while loop active triggers minimise-to-tray (not quit)
- Assert close event with no loop triggers shutdown

---

## Notes

`tray_manager` is a new dependency — requires approval per the no-new-packages rule. It is the standard Flutter Windows tray package and is already referenced in the PRD decision.

---

## Log

_Updated as work progresses._
