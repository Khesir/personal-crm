---
id: issue-001
title: "Delete agent_run + simplify dock to two panes"
feature: agent
status: done
created_at: 2026-06-16
tags: [afk, p1]
---

# [001] Delete agent_run + simplify dock to two panes

**Type:** AFK
**Priority:** P1
**Blocked by:** None
**User stories covered:** 30, 31

---

## What to build

Remove all code belonging to the old broken `agent_run` feature and collapse the kanban dock from three panes to two.

Delete the entire `features/agent_run/` module including all datasources, repositories, controllers, models, screens, dialogs, and widgets. Delete `agent_pane.dart`. Remove all imports and references to these files across the codebase.

Remove `DockPane.agent` from the enum. The dock has exactly two panes going forward: `terminal` and `chat`. Update `board_dock_section.dart`, `dock_state.dart`, and any other files that reference `DockPane.agent` or `AgentRunController`. Remove `agentRunController` from `DockStateData` and all methods that set or clear it (`setAgentRunController`, `clearAgentRunController`).

The `ChatPane` stays — it becomes the sole agent surface in a future issue.

---

## Acceptance criteria

- [ ] `features/agent_run/` directory is fully deleted
- [ ] `agent_pane.dart` is deleted
- [ ] `DockPane` enum has exactly two values: `terminal` and `chat`
- [ ] `DockStateData` has no `agentRunController` field
- [ ] `board_dock_section.dart` renders only the terminal and chat panes
- [ ] App compiles with no errors or dead imports
- [ ] All existing tests pass

---

## Tests required

Yes — update `test/features/kanban/presentation/state/dock_state_test.dart` to assert `DockPane` has two values and `DockStateData` has no agent controller field. Delete `test/features/agent_run/` entirely. Delete `test/features/kanban/presentation/widget/agent_pane_test.dart`.

---

## Notes

Git history preserves the deleted code — no archiving needed. This is a clean delete, not a move.

---

## Log

Implemented 2026-06-18. Deleted features/agent_run/ module, agent_pane.dart, and associated tests. Removed DockPane.agent enum value and agentRunController from DockStateData. board_dock_section.dart now renders only terminal and chat panes.