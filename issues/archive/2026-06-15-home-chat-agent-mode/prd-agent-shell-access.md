# PRD: Agent shell access (`run_command` tool)

**Status:** Draft
**Date:** 2026-06-14

---

## Problem Statement

`issues/prd-home-chat-agent-mode.md` explicitly scoped v1 to file tools only: *"no command/process
execution (`run_command` is explicitly out of scope, not just deferred)"*. `kAgentTools`
(`lib/features/home/domain/model/agent_tools.dart`) is fixed at `[read_file, list_dir, grep,
write_file, edit_file, web_search]`.

This PRD **reverses that exclusion**: agent-mode conversations should be able to opt into running
shell commands (`flutter test`, `git status`, `npm run lint`, etc.) inside their working project,
so Avyn can verify its own file edits instead of just making them blind.

This is the highest-risk tool added so far (arbitrary command execution on the user's machine), so
scope is deliberately narrow and gated behind an explicit, per-conversation opt-in plus mandatory
approval on every call.

---

## Solution

### `run_command` tool

A new `kRunCommandTool` `ToolDefinition` (`name: 'run_command'`, one required `command: string`
argument — a single shell command line, executed via the OS shell). It is **not** added to
`kAgentTools` (which stays the fixed v1 file-tool set per issue 015). Instead, it is appended to
the tool list passed to `streamChat()` only for conversations where shell access is enabled (see
below).

### Per-conversation "Shell access" toggle

- `ChatConversation` gains `shellAccessEnabled: bool` (default `false`), following the same
  lifecycle as `workingProjectId` (issue 004/009): set only at creation time, **immutable**
  thereafter, no UI affordance to change it on an existing conversation.
- `shellAccessEnabled` can only be `true` when `workingProjectId != null` — shell access requires a
  working project, both for cwd-scoping and because plain (non-agent) conversations have no tool
  loop at all.
- `AgentModePickerDialog` (issue 009) gains a "Shell access" checkbox, shown alongside the
  project/model pickers, default **off**. `AgentModeSelection` gains `shellAccessEnabled: bool`.
  `ChatController.newAgentConversation`/`branchIntoAgentMode` thread it through to the created
  `ChatConversation`.
- The header's `ChatModeToggle` (issue 013) shows a small indicator (e.g. a shell/terminal icon)
  next to "Agent · ProjectName" when `conversation.shellAccessEnabled == true`, so the user can see
  at a glance which conversations can run commands.

### Execution: cwd-scoped, like the file tools

- `run_command` executes via the existing `ProcessRunner`/`IoProcessRunner` abstraction
  (`lib/features/settings/domain/repository/process_runner.dart`), with `workingDirectory` set to
  the conversation's working project root — the same root `read_file`/`write_file`/`grep` resolve
  against in `AgentToolRepositoryImpl`.
- No path-escape checking on the *command string itself* (it's an opaque shell command, unlike file
  tool paths) — the boundary is enforced by `workingDirectory` alone. Output capture: stdout,
  stderr, and exit code, combined into a single `ToolOutput` (e.g. `exit 0\n<stdout>` /
  `exit 1\n<stderr>`) so the model can react to failures the same way a human reading a terminal
  would.
- A reasonable execution timeout (named constant, not magic number) kills runaway commands and
  returns a `ToolError` — this is the one piece of "safety" baked into the tool itself, independent
  of the approval gate.

### Mandatory approval on every call

- Every `run_command` call — regardless of the command — surfaces as a pending step card and
  requires explicit Approve before executing, reusing the `ToolWriteProposal`/`_ApproveRejectRow`
  mechanism from issue 010 (no "trusted command" allowlist that skips approval; that's future
  scope, not v1).
- `ToolWritePreview` (sealed: `WriteFileCreation`, `EditFileChange`) gains a third case, e.g.
  `CommandExecution(command: String, cwd: String)`. `ToolCallStepCard._buildPreview` renders it as
  the literal command string (monospace, like the existing diff previews) plus the cwd it will run
  in.
- `ToolCallStepCard`'s pending-approval check (`_isPending && _isWriteOrEdit`) is generalized to
  also match `run_command` so the Approve/Reject row renders for it.
- Rejecting a `run_command` call follows the exact same path as rejecting `write_file`/`edit_file`
  today (issue 008/010) — feeds a rejection message back into the loop, no new rejection semantics.
- If `shellAccessEnabled == false` for the conversation but the model emits a `run_command` call
  anyway (e.g. a stale tool list from before the toggle was checked), `AgentLoopRunner` returns
  `ToolError('Shell access is not enabled for this conversation.')` without ever surfacing an
  approval card — mirrors the existing "web search not configured" `ToolError` pattern from issue
  015.

---

## User Stories

1. As a user, I want to enable "Shell access" when starting (or branching into) an agent-mode
   conversation, so Avyn can run commands like `flutter test` in that project.
2. As a user, I want shell access off by default and unchangeable after a conversation is created,
   so I don't accidentally grant command execution to a conversation I forgot was sensitive.
3. As a user, I want every command Avyn wants to run to show up as a step card with the exact
   command text and an Approve/Reject choice, so nothing executes without my explicit say-so.
4. As a user, I want a rejected command to be reported back to Avyn (not silently dropped), so it
   can adjust its plan.
5. As a user, I want commands to run inside the conversation's working project directory (same
   boundary as file edits), so "shell access" doesn't mean "access to my whole machine."
6. As a user, I want a command that hangs to be killed automatically after a timeout, so one bad
   command can't freeze the conversation.
7. As a user, I want to see at a glance (in the chat header) whether the active conversation has
   shell access enabled, so I know what I'm approving before I approve it.

---

## Implementation Decisions

- `lib/features/home/domain/model/agent_tools.dart`: add `kRunCommandTool` (`run_command`,
  required `command: string`), kept separate from `kAgentTools`.
- `lib/features/home/domain/model/chat_conversation.dart`: add `shellAccessEnabled: bool = false`
  to `ChatConversation` (+ `copyWith`/`toJson`/`fromJson`), same pattern as `workingProjectId`.
- `lib/features/home/domain/controller/chat_controller.dart`: tool list passed to `streamChat()`
  for an agent-mode conversation becomes `[...kAgentTools, if (conversation.shellAccessEnabled)
  kRunCommandTool]`. `newAgentConversation`/`branchIntoAgentMode` gain a `shellAccessEnabled`
  parameter.
- New `CommandExecutionRepository` (or a method on the existing `AgentToolRepository` —
  decide during breakdown which is the better seam) wrapping `ProcessRunner`/`IoProcessRunner`,
  resolving `workingDirectory` the same way `AgentToolRepositoryImpl._resolvePath` resolves the
  project root.
- `AgentLoopRunner._executeWithResolvedPaths`: add a `run_command` branch — checks
  `conversation.shellAccessEnabled` (`ToolError` if false), otherwise produces a
  `ToolWriteProposal(preview: CommandExecution(...))` for approval, mirroring the existing
  `write_file`/`edit_file` proposal path.
- `lib/features/home/domain/model/tool_execution_result.dart`: add `CommandExecution(command,
  cwd)` to the `ToolWritePreview` sealed hierarchy.
- `lib/features/home/presentation/widget/tool_call_step_card.dart`: render `CommandExecution`
  previews (monospace command + cwd) and extend the pending-approval condition to include
  `run_command`.
- `lib/features/home/presentation/dialogs/agent_mode_picker_dialog.dart`: add a "Shell access"
  checkbox to `AgentModeSelection`/the dialog UI, default off, only meaningful when a project is
  selected (which is always true for this dialog).
- `lib/features/home/presentation/widget/chat_mode_toggle.dart` (issue 013): add a small
  shell/terminal indicator when `conversation.shellAccessEnabled`.
- New named constant for the execution timeout (e.g. `kRunCommandTimeout`) — no magic numbers.
- `lib/features/home/presentation/helpers/tool_call_summary.dart`: add a `run_command` case
  returning the command string (same pattern as issue 015's `web_search` case).

---

## Testing Decisions

- `ChatConversation` `shellAccessEnabled` round-trip (`toJson`/`fromJson`/`copyWith`), including the
  invariant that it's only meaningful alongside a non-null `workingProjectId`.
- `AgentLoopRunner`/`ChatController` agent-loop tests (fake-repository pattern from issues 008/015):
  - `run_command` with `shellAccessEnabled: true` produces a pending `ToolWriteProposal` with a
    `CommandExecution` preview; approving it dispatches to the command-execution repository with
    the conversation's working directory and feeds stdout/exit code back as `ToolOutput`;
    rejecting it feeds a rejection message back, same as `write_file`/`edit_file`.
  - `run_command` with `shellAccessEnabled: false` resolves immediately to
    `ToolError('Shell access is not enabled for this conversation.')`, no approval card, loop
    continues.
  - A command that exceeds `kRunCommandTimeout` resolves to a `ToolError` (use a fake/mocked
    process runner — do not actually sleep in tests).
- `tool_call_step_card` widget tests: `CommandExecution` preview renders the command/cwd and shows
  the Approve/Reject row while pending.
- `agent_mode_picker_dialog`/`chat_mode_toggle`: covered via `/qa`'s visual checklist (consistent
  with how issues 009/013 treated dialog and header UI).

---

## Out of Scope

- Allowlisting specific commands, or a "trusted command" tier that skips approval — every
  `run_command` call requires Approve in v1.
- Changing `shellAccessEnabled` on an existing conversation (immutable like `workingProjectId`).
- A global (cross-conversation) shell-access setting — this PRD is per-conversation only, per the
  scoping discussion.
- Interactive/long-running processes (dev servers, REPLs) — `run_command` is for one-shot commands
  that terminate within `kRunCommandTimeout`.
- Any change to `write_file`/`edit_file` approval UX — issue 010 already covers this (step cards,
  diffs, Approve/Reject); it's in `qa/` awaiting sign-off, not part of this PRD.

---

## Further Notes

- This PRD explicitly reverses the "`run_command` is out of scope" decision in
  `issues/prd-home-chat-agent-mode.md`. The breakdown should note this reversal in the issue that
  adds `kRunCommandTool`.
- `ProcessRunner`/`IoProcessRunner` already exist (used by `brain_section.dart` to open a folder) —
  reuse, do not duplicate.
- The exact shape of `ToolWritePreview.CommandExecution` and how `AgentLoopRunner` threads
  `shellAccessEnabled` through to `_executeWithResolvedPaths` should be confirmed against the
  current `tool_execution_result.dart`/`agent_loop_runner.dart` during breakdown — this PRD
  describes the shape, not exact signatures.
