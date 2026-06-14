---
id: issue-008
title: "ChatController agent loop: tool execution, write approvals, reference-project trust, step limit"
feature: home-chat-agent-mode
status: qa
created_at: 2026-06-14
tags: [afk, p1]
---

# [008] ChatController agent loop: tool execution, write approvals, reference-project trust, step limit

**Type:** AFK
**Priority:** P1
**Blocked by:** 004, 006, 007
**User stories covered:** 9, 10, 11, 12, 13, 14, 15, 16, 20, 21, 22, 28, 29

---

## What to build

Implement the agent loop in `ChatController.sendMessage()` for agent-mode conversations
(`workingProjectId != null`), wiring together the domain model (004), `AgentToolRepository` (006), and
Ollama's tool-call parsing (007). Non-agent conversations (`workingProjectId == null`) are unaffected.

- `sendMessage()` for an agent-mode conversation passes the fixed v1 `ToolDefinition` list to `streamChat()`.
- Loop, per `sendMessage()` call:
  1. Consume `ChatStreamEvent`s: text-delta events append to the in-progress assistant message (as today); a
     tool-call-requested event finalizes that assistant message with its `toolCalls` and stops consuming the
     current stream.
  2. For each requested `ToolCall`, resolve via `AgentToolRepository.execute(...)`:
     - `ToolOutput` → append a `tool`-role message with the result; continue.
     - `ToolWriteProposal` / `ToolReferenceConfirmationNeeded` → leave the tool call unanswered (pending —
       derived from the message list, not separately persisted) and stop the loop, awaiting a user decision.
     - `ToolError` → append a `tool`-role message containing the error text; continue.
  3. If every requested tool call in the turn now has a `tool`-role answer, re-invoke `streamChat()` with the
     updated message history (+ tools) and repeat from step 1.
  4. Stop when a turn produces no `toolCalls` (final answer) or `kMaxAgentLoopSteps` (named constant, e.g. 25)
     is reached — append a notice message when the limit is hit.
- New controller methods: `approveToolCall`, `rejectToolCall`, `allowReferenceProject`,
  `denyReferenceProject`.
  - Approve → executes the proposal now via `AgentToolRepository`, records the real `ToolOutput` as the
    `tool`-role answer, resumes the loop from step 3.
  - Reject → records a "rejected by user" `tool`-role result, resumes the loop from step 3.
  - Allow reference project → adds the project to `trustedReferenceProjectIds`, re-attempts the same tool
    call (re-runs `execute(...)` for that call).
  - Deny → records a denial `tool`-role result for that call, resumes the loop from step 3.
- **Pending-approval state is derived, not stored separately**: if the active conversation's last message is
  an `assistant` message with non-empty `toolCalls` and there is no following `tool`-role message answering
  each `id`, those tool calls are "pending."
- `_persist()` is called after every message-list mutation, including pending/awaiting states, so an
  in-progress agent loop survives an app restart.

---

## Acceptance criteria

- [ ] An agent-mode `sendMessage()` call passes the v1 tool definitions to `streamChat()`.
- [ ] A turn that returns only text (no `toolCalls`) behaves like a normal conversation turn.
- [ ] A turn that requests tool calls resolving to `ToolOutput`/`ToolError` automatically appends `tool`-role
  messages and re-invokes `streamChat()`, looping until a final text-only response.
- [ ] A turn requesting a `write_file`/`edit_file` that resolves to `ToolWriteProposal` stops the loop with
  the tool call left unanswered (pending).
- [ ] `approveToolCall` executes the pending write, appends its real result as a `tool`-role message, and
  resumes the loop.
- [ ] `rejectToolCall` appends a "rejected by user" `tool`-role message and resumes the loop without writing
  to disk.
- [ ] A tool call resolving to `ToolReferenceConfirmationNeeded` stops the loop pending
  `allowReferenceProject`/`denyReferenceProject`.
- [ ] `allowReferenceProject` adds the project to `trustedReferenceProjectIds`, re-attempts the call, and does
  not re-prompt for that project again in the same conversation.
- [ ] `denyReferenceProject` records a denial result and resumes the loop without granting access.
- [ ] After `kMaxAgentLoopSteps` round-trips without a final text-only response, the loop stops and appends a
  notice message.
- [ ] `_persist()` runs after every mutation, including pending states; reloading conversations after a
  simulated restart preserves a pending tool-call/approval state.
- [ ] All existing non-agent-mode (`workingProjectId == null`) tests continue passing unchanged.

---

## Tests required

Yes — extend `test/features/home/domain/controller/chat_controller_test.dart`: extend
`FakeChatModelRepository` to emit scripted `ChatStreamEvent` sequences (including tool-call-requested events
across multiple loop iterations) and add a fake `AgentToolRepository`. Cover: full loop to a final answer,
pause/resume on a write proposal (approve and reject paths), reference-project confirmation/trust persistence
within a conversation, and the `kMaxAgentLoopSteps` cutoff, per the PRD's "ChatController agent loop" testing
decisions.

---

## Notes

- Depends on 004 (domain model), 006 (`AgentToolRepository`), and 007 (Ollama tool-call parsing, so the loop
  is "proven against Ollama" per the PRD's tracer-bullet note).
- This issue is the core of the Ollama tracer bullet; issues 009/010 build UI on top of it, and 011/012 add
  the remaining providers without touching this loop.
- See PRD section "`ChatController` agent loop".

---

## Log

_Updated as work progresses._

- Constructor approach: `ChatController` gains two new **optional named** params, `ProjectsRepository? projectsRepository` and
  `AgentToolRepository? agentToolRepository` (both default `null`). The agent loop only activates when both are non-null AND
  `conversation.workingProjectId != null`; otherwise `sendMessage()` behaves exactly as before. This avoided touching any of the
  ~20 existing `ChatController(...)` call sites in `chat_controller_test.dart`. `di.dart`'s `_createChatController()` now wires
  real `ProjectsRepositoryImpl(ProjectsLocalDatasource(prefs))` and `AgentToolRepositoryImpl()` instances.
- `AgentToolRepository` addition: `Future<ToolExecutionResult> applyWrite(ToolWriteProposal proposal)` — performs the actual
  filesystem write (`WriteFileCreation` -> create+write file, returns `ToolOutput('Wrote N bytes to <path>')`) or edit
  (`EditFileChange` -> re-validates the old_text still matches exactly once, then `replaceFirst`, returns
  `ToolOutput('Replaced text in <path>')`, or `ToolError` if the file no longer matches). Implemented in
  `AgentToolRepositoryImpl`.
- The agent loop itself (`kMaxAgentLoopSteps = 25` in `domain/model/agent_loop_constants.dart`) lives in a new
  `domain/controller/agent_loop_runner.dart` (`AgentLoopRunner` + `AgentLoopOps`/`AgentLoopContext`), kept under the 500-line
  limit (375 / 388 lines) by extracting it out of `chat_controller.dart`.
- `kAgentTools` is now passed to `streamChat()` whenever `workingProjectId != null`. `sendMessage()` delegates to
  `AgentLoopRunner.runTurn()` in agent mode; `approveToolCall`/`rejectToolCall`/`allowReferenceProject`/`denyReferenceProject`
  delegate to the runner's matching methods, all sharing `_continueIfReady()` to resume the loop.
- Tests: extended `test/features/home/domain/controller/chat_controller_test.dart` with a `FakeProjectsRepository`,
  `FakeAgentToolRepository` (scriptable per-call-id result queues + `applyWrite`), and a `scriptedTurns` mode on
  `FakeChatModelRepository` (queue of `ChatStreamEvent` sequences per `streamChat()` invocation). New "ChatController agent
  loop" group (12 tests) covers: tools passed to `streamChat`, text-only regression, `ToolOutput`/`ToolError` auto-loop,
  `ToolWriteProposal` pending + approve/reject, `ToolReferenceConfirmationNeeded` + allow (no re-prompt)/deny, the
  `kMaxAgentLoopSteps` cutoff, and pending-state persistence across a simulated restart. Also added 3 `applyWrite` unit tests to
  `agent_tool_repository_impl_test.dart`. `flutter test test/features/home/` -> 79/79 passing. `flutter analyze` on all touched
  files -> no issues (2 pre-existing unrelated deprecation warnings elsewhere in the repo).
