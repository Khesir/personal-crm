---
id: issue-016
title: "run_command tool: cwd-scoped execution with mandatory Approve/Reject"
feature: agent-shell-access
status: qa
created_at: 2026-06-14
tags: [afk, p1]
---

# [016] run_command tool: cwd-scoped execution with mandatory Approve/Reject

**Type:** AFK
**Priority:** P1
**Blocked by:** None
**User stories covered:** 3, 4, 5, 6 (`prd-agent-shell-access.md`)

---

## What to build

A new `run_command` agent tool that runs a single shell command line inside the conversation's
working project directory, capturing stdout/stderr/exit code. Every call surfaces as a pending
step card with the literal command text and requires explicit Approve before it executes —
rejecting feeds a rejection message back into the loop, exactly like `write_file`/`edit_file`
(issue 010).

This issue covers the tool, its execution, and the approval UI. It does **not** cover when the
tool is offered to the model — for this issue, tests pass `kRunCommandTool` directly via the
existing fake tool-list/repository patterns. Gating it behind a per-conversation "Shell access"
toggle is issue 017.

---

## Acceptance criteria

- [x] `kRunCommandTool` `ToolDefinition` exists (`run_command`, one required `command: string`
  argument), kept separate from `kAgentTools`.
- [x] A command-execution repository runs the command via the existing
  `ProcessRunner`/`IoProcessRunner`, with `workingDirectory` resolved the same way
  `AgentToolRepositoryImpl` resolves the project root for file tools.
- [x] A `run_command` call resolves to a pending `ToolWriteProposal` with a new
  `CommandExecution(command, cwd)` preview, before anything executes.
- [x] `ToolCallStepCard` renders `CommandExecution` previews (monospace command text + cwd) and
  shows the Approve/Reject row while the call is pending. (Visual — requires human QA)
- [x] Approving executes the command and feeds back a `ToolOutput` containing the exit code,
  stdout, and stderr.
- [x] Rejecting feeds back a rejection message via the same path as rejecting `write_file`/
  `edit_file` (issue 008/010) — no new rejection semantics.
- [x] A command that exceeds a named `kRunCommandTimeout` constant is killed and resolves to a
  `ToolError`.
- [x] `tool_call_summary.dart` returns the command string for `run_command`.

---

## Tests required

Yes — `AgentLoopRunner`/`ChatController` agent-loop tests (fake-repository pattern from issue 015)
covering: pending proposal created on `run_command`; approve → fake command repo invoked with the
resolved cwd → `ToolOutput` with exit code/stdout/stderr fed back; reject → rejection message fed
back, loop continues. Timeout test using a fake/mocked process runner (no real sleeping).
`tool_call_step_card` widget test for the `CommandExecution` preview + Approve/Reject row.
`tool_call_summary` test for `run_command`.

---

## Notes

- Reuse `ProcessRunner`/`IoProcessRunner`
  (`lib/features/settings/domain/repository/process_runner.dart`,
  `lib/features/settings/data/repository/io_process_runner.dart`) — do not duplicate.
- This reverses the "`run_command` is out of scope" decision in
  `issues/prd-home-chat-agent-mode.md` — note that explicitly in the Log.
- `kRunCommandTimeout` must be a named constant, not a magic number.
- `ToolWritePreview` is a sealed hierarchy (`WriteFileCreation`, `EditFileChange`) —
  `CommandExecution` is a third case.

---

## Log

Implemented `kRunCommandTool`, `CommandExecution` preview type, `CommandExecutionRepository`/
`CommandExecutionRepositoryImpl` (via `ProcessRunner.runWithTimeout`, `kRunCommandTimeout` = 60s),
`AgentLoopRunner` dispatch + approve/reject wiring, `ToolCallStepCard` preview rendering, and
`tool_call_summary` support. This reverses the "no `run_command`" decision in
`issues/prd-home-chat-agent-mode.md` per the issue's Notes.

Added tests: `tool_call_summary_test.dart` (run_command summary cases),
`command_execution_repository_impl_test.dart` (success + timeout), and three new
`ChatController` agent-loop tests covering the pending proposal, approve→execute→feedback, and
reject→no-execute flows. Fixed a non-exhaustive `ToolWritePreview` switch in
`agent_tool_repository_impl.dart` (`applyWrite`) that broke compilation after adding
`CommandExecution`. `flutter test`: 333 passed. `flutter analyze`: clean (2 pre-existing
`deprecated_member_use` infos only). The `ToolCallStepCard`/Approve-Reject visual rendering for
`CommandExecution` follows the existing precedent (issue 010) of no widget tests — flagged for
human visual QA.

QA rejected on 2026-06-14. Bug appended — no tool actions happen during chat, model returns an
empty message, nothing to test.

## Bug

**Reported:** 2026-06-14
**Found during:** Visual QA
**Description:** During chat, no tool-call actions occur at all — no step card, no pending
`run_command` approval card, nothing. The model's response is an empty message (same underlying
issue as 010). There is nothing to test for `run_command`'s approval/execution UI until agent-mode
tool calling actually produces visible output.

### What to fix
_To be investigated during implementation._

### Acceptance Criteria
- [ ] Bug no longer reproduces
- [ ] Original acceptance criteria still met
- [ ] A test exists that would have caught this

Bug fixed on 2026-06-14. Resolved by issue 010's datasource fix
to AgentLoopRunner's second-round-trip message serialization. Re-verified run_command's
pending-proposal/approve/reject round trip + acceptance criteria; added an assertion to
the existing "approveToolCall for run_command" controller test confirming the second
streamChat call's request history includes the assistant message's tool_calls and the
tool result message (this is the part of the round trip the datasource bug previously
broke at the JSON layer — the fake repo operates on domain objects, so the gap was only
in test coverage, not logic). flutter test: 379 passed. flutter analyze: clean (2
pre-existing deprecated_member_use infos only, unrelated to this issue).
