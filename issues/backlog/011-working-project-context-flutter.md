---
id: issue-011
title: "Working project context in Flutter ChatPane"
feature: agent
status: backlog
created_at: 2026-06-16
tags: [afk, p2]
---

# [011] Working project context in Flutter ChatPane

**Type:** AFK
**Priority:** P2
**Blocked by:** 005
**User stories covered:** 19, 20, 21

---

## What to build

Add working project selection to the `ChatPane`. The user can optionally bind the agent to a project — when bound, file and shell tools operate in that project's directory. Without a project, the agent runs in general-purpose mode.

`AgentController` gains a `workingProject` field (nullable `Project`). The controller sends `workingProject.localPath` in every `/chat` request when set, and null when not set.

The `ChatPane` header shows the currently selected working project (or "No project" if none). A project picker affordance in the header lets the user select a different project or clear the selection. Switching project takes effect immediately on the next message — no session restart.

The available projects come from the existing projects repository (already used in the settings and kanban features).

---

## Acceptance criteria

- [ ] `AgentController` holds a nullable `workingProject` and sends its `localPath` in `/chat` requests
- [ ] `ChatPane` header displays the currently selected project name (or "No project")
- [ ] User can open a project picker and select a different project
- [ ] User can clear the working project (reverts to general-purpose mode)
- [ ] Switching project takes effect on the next message without restarting the session

---

## Tests required

Yes:
- `AgentController` test: assert `localPath` is included in the request when `workingProject` is set, and null when not set
- `ChatPane` widget test: assert header shows project name; assert clearing sets it to null

---

## Notes

The working project is independent of the kanban board's current project — the user can have a different project selected in the agent than on the board.

---

## Log

_Updated as work progresses._
