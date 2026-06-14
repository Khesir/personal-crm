---
id: issue-013
title: "Home chat: Chat/Agent mode segmented toggle in header"
feature: home-chat-agent-mode
status: done
created_at: 2026-06-14
tags: [afk, p2]
---

# [013] Home chat: Chat/Agent mode segmented toggle in header

**Type:** AFK
**Priority:** P2
**Blocked by:** None (009, 010 already in qa)

---

## What to build

Visual QA on issues 009/010 surfaced that there is no indicator showing whether the active
conversation is in Agent mode. Add a "Chat / Agent" segmented toggle to `home_chat_section.dart`'s
`_Header`, similar in spirit to Claude.ai's mode switcher.

- The toggle reflects the **active conversation's** mode: "Chat" highlighted when
  `conversation.workingProjectId == null`, "Agent" highlighted when it is non-null. When there is
  no active conversation, default to "Chat" highlighted.
- `workingProjectId` remains immutable per conversation (per issue 009) — the toggle does not
  change the current conversation's mode.
- Tapping the segment that matches the current conversation's mode does nothing.
- Tapping the other segment starts a **new conversation** in that mode:
  - Tapping "Chat" while in an agent-mode conversation calls `controller.newConversation()`.
  - Tapping "Agent" while in a plain conversation opens the existing `AgentModePickerDialog`
    (project + tool-capable model picker); on confirm, calls `controller.newAgentConversation(...)`.
    On cancel, nothing changes.
- When Agent mode is active, also show the working project's name next to/within the toggle (e.g.
  "Agent · ProjectName") so the user can see which project is in scope without opening a dialog.

---

## Acceptance criteria

- [ ] A plain conversation (`workingProjectId == null`) shows "Chat" highlighted in the header
  toggle; an agent-mode conversation shows "Agent" highlighted, plus its working project's name.
- [ ] Tapping the already-active segment is a no-op.
- [ ] Tapping "Chat" from an agent-mode conversation starts a new plain conversation
  (`controller.newConversation()`), which becomes active.
- [ ] Tapping "Agent" from a plain conversation opens `AgentModePickerDialog`; confirming creates a
  new agent-mode conversation (`controller.newAgentConversation(projectId, entry)`) which becomes
  active; cancelling leaves the current conversation active and unchanged.
- [ ] The empty state (no active conversation) shows "Chat" highlighted by default.
- [ ] Existing header layout (title + `ModelSwitcher`) continues to work unchanged.

---

## Tests required

Yes — unit/widget test the toggle's mode-resolution logic (active vs inactive segment given
`workingProjectId`) and that tapping the inactive segment invokes the correct controller method
(`newConversation` for "Chat", `newAgentConversation` after picker confirm for "Agent"), using the
existing `ChatController` test fakes. Visual styling itself is covered via `/qa`'s visual checklist.

---

## Notes

- Reuse `AgentModePickerDialog` (from issue 009) — do not build a new picker.
- Project name lookup for "Agent · ProjectName" can reuse `ProjectsRepository.getProjects()` (same
  pattern as `agent_mode_flow.dart`'s existing helpers).
- See PRD section "Step card UI" / visual QA feedback on issues 009 and 010 for context — this issue
  exists to make agent mode visible in the chat header, it does not change agent-loop or step-card
  behavior.

---

## Log

- Added `ChatModeToggle` (`presentation/widget/chat_mode_toggle.dart`): a two-segment "Chat / Agent"
  control in `home_chat_section.dart`'s `_Header`. "Chat" is highlighted when
  `conversation?.workingProjectId == null` (including the no-active-conversation case), "Agent" is
  highlighted otherwise and shows "Agent · ProjectName" via a `FutureBuilder` resolving the working
  project's name.
- Added `startNewAgentChat` and `workingProjectName` helpers to
  `presentation/helpers/agent_mode_flow.dart`. `startNewAgentChat` opens `AgentModePickerDialog`
  directly (skipping `NewChatDialog`'s switch, since tapping "Agent" already expresses the choice)
  and calls `controller.newAgentConversation` on confirm. Tapping "Chat" from an agent-mode
  conversation calls `controller.newConversation()`. Tapping the already-active segment is a no-op
  (`onTap: null`).
- Tested: new `test/features/home/presentation/widget/chat_mode_toggle_test.dart` (5 widget tests)
  covering no-op on active segment, "Chat" tap starting a new plain conversation from agent mode,
  "Agent · ProjectName" label, "Agent" tap opening the picker and creating an agent-mode conversation
  on confirm, and rendering with no active conversation. `flutter test` passes (316 tests, was 311);
  `flutter analyze` clean (only the 2 pre-existing `deprecated_member_use` infos).

QA approved by user on 2026-06-14.
