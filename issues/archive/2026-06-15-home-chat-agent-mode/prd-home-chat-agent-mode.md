# PRD: Home Chat Agent Mode (file read/edit tools, scoped to a Project)

**Status:** Draft
**Date:** 2026-06-14

---

## Problem Statement

Home chat can only exchange plain text with an LLM (`ChatModelRepository.streamChat()` is `Stream<String>` in,
`Stream<String>` out). The user wants Home chat to behave more like Claude Code/OpenCode: able to read and
edit files in one of their projects and reason over multiple turns based on what it finds — not just answer
questions about code pasted into the chat.

Today, if the user wants help with a specific file, they have to paste its contents into the chat manually,
and the assistant can never apply a change back to disk.

---

## Solution

Introduce **Agent mode**: a per-conversation mode where, at creation, the user picks a registered `Project`
as the conversation's **working project** and a tool-capable model. For the rest of that conversation's
lifetime, the assistant can call five file-oriented tools — `read_file`, `list_dir`, `grep`, `write_file`,
`edit_file` — scoped to that working project (full read/write) and, on demand, to other registered
**reference projects** (read-only, after a one-time per-conversation confirmation).

Every tool call appears live in the transcript as a collapsible step card. Read-only tools execute
immediately; `write_file`/`edit_file` pause the conversation and show a diff/preview that the user must
approve or reject before anything touches disk. The agent loops (tool call → execute → feed result back →
continue) until the model returns a final text-only response or a safety step limit is reached.

v1 ships file tools only — no command/process execution (`run_command` is explicitly out of scope, not just
deferred). Tool-calling is implemented for Ollama first (the user's daily driver), then OpenAI-compatible,
then Anthropic, sharing the same agent loop, persistence, and UI across all three.

`CONTEXT.md` now defines **Agent mode**, **Working project**, and **Reference project** — see that file for
the canonical definitions.

---

## User Stories

1. As a user, I want to start a new conversation in "agent mode" by picking one of my registered Projects as
   the working project, so the assistant can read and edit files in that project.
2. As a user, I want the model picker for agent-mode conversations to only offer models capable of
   tool-calling, so I don't start a session that silently can't use any tools.
3. As a user whose daily driver is Ollama, I want Ollama models that support tool-calling (per their
   `/api/show` capabilities) to show a "Tools" badge in the cookbook, so I know which local models actually
   work for agent mode.
4. As a user, I want the assistant to read files in my working project via a `read_file` tool, so it can see
   real code before answering or editing.
5. As a user, I want the assistant to list directory contents via a `list_dir` tool, so it can explore my
   project's structure.
6. As a user, I want the assistant to search file contents via a `grep` tool, so it can find relevant code
   across the project without me pointing it at exact files.
7. As a user, I want the assistant to create new files via `write_file`, so it can scaffold new code when
   needed.
8. As a user, I want the assistant to make targeted edits to existing files via `edit_file` (find/replace),
   so small changes don't require it to re-send an entire file's contents.
9. As a user, I want every `write_file`/`edit_file` call to pause and show me a diff (or file-creation
   preview) before anything is written to disk, so nothing changes without my say-so.
10. As a user, I want to approve or reject each write/edit individually, so I retain full control over every
    change the assistant makes.
11. As a user, if I reject a write/edit, I want the assistant to be told it was rejected, so it can adjust
    its approach instead of assuming the change happened.
12. As a user, I want `read_file`/`list_dir`/`grep` calls within my working project to run without any
    confirmation, so exploration stays fast.
13. As a user, I want the assistant to be able to read files from my *other* registered projects (reference
    projects) when relevant, so it can cross-reference related code (e.g. the backend while working in the
    crm frontend).
14. As a user, the first time the assistant tries to read from a reference project in a conversation, I want
    to be asked to allow read access to that specific project, so I control which other projects it can see.
15. As a user, once I've allowed access to a reference project in a conversation, I don't want to be asked
    again for that same project in that same conversation, so exploration isn't constantly interrupted.
16. As a user, I want `write_file`/`edit_file` to be rejected outright — without even prompting — if the
    target path is outside my working project, so the assistant can never modify reference projects or
    anything else on disk.
17. As a user, I want every tool call to appear live in the chat transcript as a collapsible step card, so I
    can watch the assistant work in real time, the same way I watch Claude Code work.
18. As a user, I want each step card collapsed by default, showing just the tool name and a short summary
    (e.g. the file path), so long tool sequences don't overwhelm the transcript.
19. As a user, I want to expand a step card to see the full tool input/output — and a diff for edits — so I
    can inspect exactly what happened or is about to happen.
20. As a user, I want the assistant's final text response (after all tool calls for that turn finish) to
    appear as a normal chat bubble, so the conversation still reads naturally.
21. As a user, if the assistant gets stuck calling tools in a loop, I want it to stop automatically after a
    safety limit and tell me, so it doesn't run forever or rack up API costs unexpectedly.
22. As a user, I want an agent-mode conversation's working project to be fixed for that conversation's whole
    lifetime, so the scope of file access is always obvious from the conversation itself.
23. As a user, I want to "branch" any existing conversation into a new agent-mode conversation — picking a
    working project and tool-capable model — pre-filled with the original conversation's history, so I don't
    lose context when I realize mid-chat that I need file access.
24. As a user, I want my existing (non-agent) conversations to keep working exactly as before, so this change
    doesn't disrupt my chat history.
25. As a developer, I want `ChatMessage`/`ChatConversation` JSON persisted in `shared_preferences` to remain
    backward-compatible, so old conversations still load correctly after this change.
26. As a developer, I want `ChatModelRepository.streamChat()`'s new contract (tool definitions in, structured
    tool-call events out) implemented for Ollama first, then OpenAI-compatible, then Anthropic, sharing one
    agent loop/persistence/UI implementation across all three.
27. As a developer, I want file-tool execution (read/write/list/grep, path-boundary enforcement) to be
    unit-testable against real temporary directories without Flutter or network dependencies, so the core
    logic is fast and reliably covered.
28. As a user, if a tool call fails (file not found, an `edit_file` find/replace that matches zero or more
    than one location, permission error, etc.), I want the assistant to receive a clear error as the tool
    result — not have the conversation crash — so it can recover or explain the failure to me.
29. As a user, if I close and reopen an agent-mode conversation while a write/edit is awaiting my approval, I
    want to see that pending approval again, so I don't lose track of an in-progress change.
30. As a user, I want `run_command`/shell execution to NOT be part of this feature at all, so the assistant
    cannot run arbitrary commands on my machine.

---

## Implementation Decisions

### Domain model changes (`lib/features/home/domain/model/`)

- **`ChatRole`** gains a new value, `tool` (alongside `user`, `assistant`, `system`), representing a tool
  execution result fed back to the model. `fromValue`/`value` extended accordingly; unrecognized values
  still fall back to `user` for back-compat.
- **`ToolCall`** (new model): `{ id: String, name: String, arguments: Map<String, dynamic> }` — one requested
  tool invocation.
- **`ChatMessage`** gains:
  - `toolCalls: List<ToolCall>` (default `[]`) — set on `assistant` messages that requested one or more tool
    calls in that turn.
  - `toolCallId: String?` and `toolName: String?` — set on `tool`-role messages, linking the result back to
    the `ToolCall.id`/`name` it answers.
  - All new fields default to empty/null in `fromJson` when absent, so existing persisted plain-text
    messages deserialize unchanged.
- **`ChatConversation`** gains:
  - `workingProjectId: String?` (default `null`) — the conversation's working project; `null` means a normal
    (non-agent) conversation.
  - `trustedReferenceProjectIds: List<String>` (default `[]`) — reference projects the user has approved read
    access to, for this conversation, so far.
  - Both default safely for existing persisted conversations.
- **Pending-approval state is derived, not stored separately**: if the active conversation's last message is
  an `assistant` message with non-empty `toolCalls` and there is no following `tool`-role message answering
  each `id`, those tool calls are "pending." This makes story 29 (resuming a pending approval after
  reopening) fall out of the existing message list with no extra persisted state.

### `ChatModelRepository` contract change (`lib/features/home/domain/repository/`)

- `streamChat()` changes from `Stream<String>` to `Stream<ChatStreamEvent>`, and gains an optional
  `tools: List<ToolDefinition>` parameter (default `[]`):
  - `ChatStreamEvent` is a small sealed type with two variants: a text-delta event (current behavior, wraps
    a `String` chunk) and a tool-call-requested event (wraps a `List<ToolCall>` — a single assistant turn may
    request multiple tool calls).
  - `ToolDefinition`: `{ name: String, description: String, parameters: Map<String, dynamic> }` (JSON Schema
    for the tool's arguments).
  - When `tools` is empty (non-agent conversations), behavior is unchanged — only text-delta events are
    emitted, and `ChatController` unwraps them exactly as it unwraps `String` chunks today.
- This is a breaking signature change affecting all three datasource/repository implementations
  (`anthropic_datasource.dart`, `ollama_datasource.dart`, `openai_compatible_datasource.dart` and their
  `*_repository_impl.dart`) and their existing tests — every existing test updates its expectations to the
  new event-wrapped shape, even before tool-call parsing is implemented for that provider.

### Tool set (v1, fixed at 5 tools)

- `read_file(path)` — returns file contents.
- `list_dir(path)` — returns directory entries (files/folders).
- `grep(pattern, path?)` — searches file contents under `path` (defaults to project root) for `pattern`.
- `write_file(path, content)` — creates a new file with `content`. Errors if `path` already exists (use
  `edit_file` to modify existing files).
- `edit_file(path, old_text, new_text)` — replaces `old_text` with `new_text` in an existing file. Errors
  (returns a `tool`-role error result, per story 28) unless `old_text` matches **exactly once** in the file.
- Each tool's JSON Schema is defined once as a `ToolDefinition` constant and translated per-provider by the
  datasource (Anthropic's `input_schema` field vs. OpenAI/Ollama's `parameters` field — same JSON Schema
  content, different wrapping key).
- `run_command` / any process-execution tool is explicitly excluded from this PRD's tool set.

### New module: agent tool execution

- A new `AgentToolRepository` (domain interface) + impl, following the existing repository pattern.
  `execute(ToolCall call, { required String workingProjectPath, required List<String>
  trustedReferenceProjectPaths })` returns a `ToolExecutionResult`, one of:
  - `ToolOutput(text)` — successful read-only result (or a successfully-applied write, see below).
  - `ToolWriteProposal(path, preview)` — for `write_file`/`edit_file`: `preview` is either the new file's
    content (creation) or an old/new text pair (edit), used to render the diff. Execution is **not**
    performed until approved.
  - `ToolReferenceConfirmationNeeded(projectId, path)` — the resolved path falls under a registered project
    that isn't the working project and isn't yet in `trustedReferenceProjectIds`.
  - `ToolError(message)` — file not found, ambiguous/missing `edit_file` match, path outside all known
    projects, permission error, etc. Fed back to the model as a `tool`-role message so it can recover (story
    28).
- **Path resolution**: relative paths resolve against the working project's `localPath`. A resolved path is
  permitted for reads if it falls under the working project's `localPath` or any registered project's
  `localPath`; permitted for writes only if it falls under the working project's `localPath`. Anything else
  → `ToolError` (access denied).
- A named constant `kMaxAgentLoopSteps` (e.g. 25) caps how many tool-call round-trips a single `sendMessage`
  agent loop may execute before stopping and appending a notice message (story 21).

### `ChatController` agent loop (`domain/controller/chat_controller.dart`)

- `sendMessage()` for an agent-mode conversation (`workingProjectId != null`) passes the fixed v1
  `ToolDefinition` list to `streamChat()`.
- Loop, per `sendMessage()` call:
  1. Consume `ChatStreamEvent`s: text-delta events append to the in-progress assistant message (as today);
     a tool-call-requested event finalizes that assistant message with its `toolCalls` and stops consuming
     the current stream.
  2. For each requested `ToolCall`, resolve via `AgentToolRepository.execute(...)`:
     - `ToolOutput` → append a `tool`-role message with the result; continue.
     - `ToolWriteProposal` / `ToolReferenceConfirmationNeeded` → leave the tool call unanswered (pending, per
       the derived-state rule above) and stop the loop, awaiting a user decision via new controller methods
       (`approveToolCall`, `rejectToolCall`, `allowReferenceProject`, `denyReferenceProject`).
     - `ToolError` → append a `tool`-role message containing the error text; continue.
  3. If every requested tool call in the turn now has a `tool`-role answer, re-invoke `streamChat()` with the
     updated message history (+ tools) and repeat from step 1.
  4. Stop when a turn produces no `toolCalls` (final answer) or `kMaxAgentLoopSteps` is reached.
- Approval/rejection methods append the corresponding `tool`-role message (approved → executes the proposal
  now and records its real output; rejected → records a "rejected by user" result) and resume the loop from
  step 3. Allowing a reference project adds it to `trustedReferenceProjectIds` and re-attempts the same tool
  call.
- `_persist()` is called after every message-list mutation (including pending/awaiting states), so an
  in-progress agent loop survives an app restart (story 29).

### `CookbookEntry` / model capability (`domain/model/cookbook_entry.dart`)

- Gains `supportsTools: bool`.
- During `ChatController.refresh()`, for `ServiceType.ollama` cards, query `/api/show` per model and set
  `supportsTools` from whether its `capabilities` array contains `"tools"`. For all other `ServiceType`s,
  `supportsTools = true` (assumed).
- The agent-mode model picker filters the cookbook to `supportsTools == true` entries.

### Provider implementation order (this PRD covers all three; implemented in this order)

1. **Ollama** (`ollama_datasource.dart`): send `tools` in `/api/chat` (OpenAI function-calling JSON Schema
   shape) when non-empty; the final response chunk (`done: true`) carries `message.tool_calls` — map each to
   a `ToolCall` and emit a tool-call-requested event. Outgoing `tool`-role messages map to Ollama's
   `role: "tool"` message shape.
2. **OpenAI-compatible** (`openai_compatible_datasource.dart`): send `tools`; accumulate streamed
   `delta.tool_calls[].function.arguments` string fragments per call `id` until `finish_reason: "tool_calls"`,
   then parse each accumulated string as JSON arguments and emit the tool-call-requested event. `tool`-role
   messages map to `role: "tool"` with `tool_call_id`.
3. **Anthropic** (`anthropic_datasource.dart`): send `tools` (Anthropic's `input_schema` shape); accumulate
   `content_block_start` (`type: "tool_use"`) / `content_block_delta` (`type: "input_json_delta"`) /
   `content_block_stop` events into a `ToolCall`, emitted on `message_stop` (or when all tool-use blocks for
   the turn are complete). Outgoing `tool`-role messages map to a `user` message containing `tool_result`
   content blocks keyed by `tool_use_id`.

### Conversation creation / branching UI (`presentation/`)

- The new-conversation flow gains an "Agent mode" toggle. When enabled: a project picker (registered
  `Project`s) selects the working project, and the model picker is filtered to `supportsTools` cookbook
  entries. `workingProjectId` is set on the new `ChatConversation` at creation and never changes.
- A new "Branch into agent mode" action (conversation context menu / header) opens the same
  project+model picker, then creates a new `ChatConversation` whose `messages` are a copy of the source
  conversation's `messages` at branch time (source conversation is untouched).

### Step card UI (`presentation/widget/`)

- New collapsible step-card widget(s) render each `assistant` message's `toolCalls` paired with their
  `tool`-role answers (or pending state): collapsed shows tool name + a one-line summary (e.g. the `path`
  argument); expanded shows full arguments/output, and for `edit_file`/`write_file` a diff or
  file-creation preview plus Approve/Reject buttons when pending. A separate confirmation card style is used
  for `ToolReferenceConfirmationNeeded` ("Allow read access to [Project]?" / Allow / Deny).
- The final text-only assistant response continues to render via the existing `BotMsg` bubble.

---

## Testing Decisions

- **Good tests here assert on external behavior**: for the agent loop, that means the resulting
  `ChatConversation.messages` shape (tool calls, tool results, pending/approved/rejected states, final text)
  and what gets passed to `streamChat()` on each loop iteration — not internal controller method names.
- **Datasource tests** (`test/features/home/data/datasource/*_datasource_test.dart`): extend the existing
  `_FakeAdapter`/Dio pattern (see `ollama_datasource_test.dart`) to assert the outgoing request body includes
  `tools` when provided, and that a canned streaming response containing tool-call data is parsed into the
  expected `ChatStreamEvent` sequence. Existing text-only tests are updated for the new event-wrapped return
  type.
- **Agent tool execution** (new test file alongside the new repository): pure Dart tests using
  `Directory.systemTemp.createTemp()` as fake working/reference project roots — cover each of the 5 tools'
  happy paths, `edit_file`'s zero/multiple-match error, and path-boundary enforcement (working project
  read/write, reference project read-only, outside-all-projects denied).
- **`ChatController` agent loop** (`test/features/home/domain/controller/chat_controller_test.dart`): extend
  `FakeChatModelRepository` to emit scripted `ChatStreamEvent` sequences (including tool-call-requested
  events across multiple loop iterations) and add a fake `AgentToolRepository`. Cover: full loop to a final
  answer, pause/resume on a write proposal (approve and reject paths), reference-project
  confirmation/trust persistence within a conversation, and the `kMaxAgentLoopSteps` cutoff. All existing
  non-agent-mode tests (`workingProjectId == null`) must continue passing unchanged.
- **Persistence/back-compat** (model tests for `ChatMessage`/`ChatConversation`): round-trip `toJson`/
  `fromJson` for both old (no `toolCalls`/`workingProjectId`/etc.) and new message/conversation shapes.
- **UI** (step cards, approval dialogs, agent-mode conversation creation/branching): no automated widget
  tests — covered via `/qa`'s visual checklist, consistent with other Home/Settings UI in this codebase.

---

## Out of Scope

- `run_command` or any shell/process-execution tool — fully excluded, not deferred.
- More than one working project per conversation; reference projects are always read-only.
- Any in-app editor for files beyond what `write_file`/`edit_file` produce (diff preview only).
- Undo/revert of applied edits beyond the user's own VCS (git) — agent mode does not implement its own undo
  stack.
- Brain vault retrieval (long-term memory notes beyond `identity.md`/`soul.md`/`memory.md`) — the brain PRD
  explicitly deferred this to agent mode's tools, but wiring the brain's `memory.md` updates through
  `edit_file` etc. is not part of this PRD; it can reuse these tools later without further design work.
- Mobile/web platforms — agent mode assumes desktop filesystem access (consistent with `kanban`'s existing
  assumptions).
- Telemetry/analytics on tool usage or approval rates.
- Automated widget tests for the new step-card/approval UI.

---

## Further Notes

- `CONTEXT.md` has been updated with **Agent mode**, **Working project**, and **Reference project** —
  use this vocabulary in issue titles/descriptions.
- Given the scope (new tool-execution module, agent loop rework, persistence changes, and UI across three
  providers), `/to-issues` should slice this into vertical tracer-bullet issues ordered by the provider
  priority above — an Ollama-only tracer bullet (tool execution + agent loop + persistence + step-card UI,
  proven against Ollama) should land first, with OpenAI-compatible and Anthropic as smaller follow-on issues
  that reuse the same loop/UI.
- The original handoff (`docs/handoffs/handoff-home-chat-agent-mode.md`) floated `run_command` as a future
  direction; per this conversation that idea is now considered outdated for the current effort and has been
  removed rather than deferred. If process execution is wanted later, it should go through a fresh
  `/grill-with-docs` pass rather than being assumed from the old handoff.
