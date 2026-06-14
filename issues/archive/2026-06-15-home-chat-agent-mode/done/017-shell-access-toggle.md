---
id: issue-017
title: "Per-conversation Shell access toggle"
feature: agent-shell-access
status: done
created_at: 2026-06-14
tags: [afk, p1]
---

# [017] Per-conversation Shell access toggle

**Type:** AFK
**Priority:** P1
**Blocked by:** 016
**User stories covered:** 1, 2, 7 (`prd-agent-shell-access.md`)

---

## What to build

A per-conversation "Shell access" toggle that controls whether `run_command` (issue 016) is
offered to the model at all. Off by default, set only at conversation creation, and immutable
afterward — same lifecycle as `workingProjectId` (issue 004/009).

---

## Acceptance criteria

- [x] `ChatConversation` gains `shellAccessEnabled: bool` (default `false`) with `copyWith`/
  `toJson`/`fromJson` support.
- [x] `shellAccessEnabled` can only be `true` when `workingProjectId != null`.
- [x] `shellAccessEnabled` is immutable after creation — no UI affordance to change it on an
  existing conversation.
- [x] `AgentModePickerDialog` gains a "Shell access" checkbox, default off; `AgentModeSelection`
  carries `shellAccessEnabled`. (Visual — requires human QA)
- [x] `ChatController.newAgentConversation`/`branchIntoAgentMode` thread `shellAccessEnabled`
  through to the created `ChatConversation`.
- [x] The tool list passed to `streamChat()` for an agent-mode conversation is
  `[...kAgentTools, if (conversation.shellAccessEnabled) kRunCommandTool]`.
- [x] If `shellAccessEnabled == false` but the model emits a `run_command` call anyway,
  `AgentLoopRunner` returns `ToolError('Shell access is not enabled for this conversation.')`
  without surfacing an approval card.
- [x] `ChatModeToggle` (issue 013) shows a shell/terminal indicator when
  `conversation.shellAccessEnabled`. (Visual — requires human QA)

---

## Tests required

Yes — `ChatConversation` round-trip/`copyWith` tests including the `workingProjectId` invariant;
`ChatController`/`AgentLoopRunner` tests for tool-list construction with/without
`shellAccessEnabled` and the "not enabled" `ToolError` path (mirrors issue 015's "web search not
configured" test). `agent_mode_picker_dialog` checkbox and `chat_mode_toggle` indicator covered
via `/qa`'s visual checklist.

---

## Notes

- Depends on 016 for `kRunCommandTool`/`CommandExecution` dispatch to exist.
- Follow the same immutability pattern as `workingProjectId` (issue 004/009) — no UI to change it
  later.

---

## Log

_Updated as work progresses._

Added `shellAccessEnabled: bool` (default `false`, immutable via `copyWith`) to `ChatConversation`
with `toJson`/`fromJson` support. Added a "Shell access" checkbox to `AgentModePickerDialog`
(default off) and `shellAccessEnabled` to `AgentModeSelection`, threaded through
`startNewChat`/`branchIntoAgentMode`/`startNewAgentChat` into
`ChatController.newAgentConversation`/`branchIntoAgentMode`. `AgentLoopRunner` now builds its
`streamChat()` tool list via `_toolsFor(ctx)` (`kAgentTools` plus `kRunCommandTool` only when the
conversation has `shellAccessEnabled`), used in both `runTurn` and `_continueIfReady`. A
`run_command` call on a conversation without shell access now resolves to
`ToolError('Shell access is not enabled for this conversation.')` instead of a pending
`ToolWriteProposal`. `ChatModeToggle`'s agent segment shows a terminal icon when
`shellAccessEnabled`.

Tests: `chat_conversation_test.dart` round-trip/copyWith/old-shape-default coverage for
`shellAccessEnabled`; 3 new `ChatController` agent-loop tests (tool list with/without
`kRunCommandTool`, and the "not enabled" `ToolError` path); updated the 3 existing `run_command`
tests to use `agentConversation(shellAccessEnabled: true)`. `flutter test` → 360 passed,
`flutter analyze` clean except 2 pre-existing `deprecated_member_use` infos.

QA approved by user on 2026-06-14.
