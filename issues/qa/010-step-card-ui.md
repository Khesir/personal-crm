---
id: issue-010
title: "Step-card UI: collapsible tool-call cards, diffs, approve/reject, reference-project confirmation"
feature: home-chat-agent-mode
status: qa
created_at: 2026-06-14
tags: [afk, p2]
---

# [010] Step-card UI: collapsible tool-call cards, diffs, approve/reject, reference-project confirmation

**Type:** AFK
**Priority:** P2
**Blocked by:** 008, 009
**User stories covered:** 17, 18, 19, 20

---

## What to build

Render the agent loop's tool calls (from issue 008) live in the chat transcript.

- New collapsible step-card widget(s) (`presentation/widget/`) render each `assistant` message's `toolCalls`
  paired with their `tool`-role answers (or pending state):
  - Collapsed: tool name + a one-line summary (e.g. the `path` argument).
  - Expanded: full arguments/output, and for `edit_file`/`write_file` a diff (or file-creation preview) plus
    Approve/Reject buttons when pending — wired to `ChatController.approveToolCall`/`rejectToolCall`.
- A separate confirmation card style for `ToolReferenceConfirmationNeeded` ("Allow read access to
  [Project]?" / Allow / Deny) — wired to `allowReferenceProject`/`denyReferenceProject`.
- The final text-only assistant response continues to render via the existing `BotMsg` bubble, after all tool
  calls for that turn finish.
- Step cards only render for agent-mode conversations; non-agent conversations render exactly as before.

---

## Acceptance criteria

- [ ] Each tool call in an agent-mode conversation renders as a collapsed step card showing tool name + a
  short summary, by default.
- [ ] Expanding a step card shows full tool input/output.
- [ ] `write_file`/`edit_file` step cards show a diff (edit) or file-creation preview (write) when expanded.
- [ ] A pending `write_file`/`edit_file` step card shows Approve/Reject buttons; tapping them calls
  `approveToolCall`/`rejectToolCall` and the card updates to reflect the resulting `tool`-role message.
- [ ] A pending `ToolReferenceConfirmationNeeded` renders as a confirmation card ("Allow read access to
  [Project]?") with Allow/Deny, wired to the corresponding controller methods.
- [ ] After all tool calls in a turn are resolved and the model returns a final text-only response, that
  response renders as a normal `BotMsg` bubble below the step cards.
- [ ] Non-agent conversations (`workingProjectId == null`) render unchanged — no step cards.
- [ ] Reopening an agent-mode conversation with a pending approval shows the same pending step
  card/confirmation card again (derived from persisted message state).

---

## Tests required

No automated widget tests — covered via `/qa`'s visual checklist, per the PRD's UI testing decisions.

---

## Notes

- Depends on 008 (agent loop produces the `toolCalls`/`tool`-role message shapes this UI renders) and 009
  (need an agent-mode conversation to exist to exercise this UI).
- See PRD section "Step card UI".

---

## Log

- Added `StepCard` (collapsible shell), `ToolCallStepCard` (collapsed summary, expanded args/result, write/edit
  diff preview, Approve/Reject), `ReferenceConfirmationCard`, and `LabeledTextBlock` under `presentation/widget/`,
  plus pure helpers `isWriteOrEditTool`/`toolCallSummary`/`toolCallWritePreview` in `presentation/helpers/`. New
  `presentation/section/agent_step_list.dart` derives step cards from `conversation.messages` and wires
  approve/reject/allow/deny to `ChatController`. `_MessageList` in `home_chat_section.dart` now renders step
  cards + final `BotMsg` for agent-mode assistant messages with `toolCalls`; non-agent rendering unchanged.
- Tested: `flutter analyze` clean (only the 2 pre-existing `deprecated_member_use` warnings), `flutter test`
  passes (311 tests) including new unit tests for `toolCallSummary`/`toolCallWritePreview`/`isWriteOrEditTool`
  and for the new `ChatController.previewPendingToolCall`.
- Judgment call: `write_file`/`edit_file` pending proposals (and resolved diffs) are derived purely from
  `ToolCall.arguments` via `toolCallWritePreview` — no repo call needed. For pending `read_file`/`list_dir`/`grep`
  calls, added a read-only `AgentLoopRunner.previewPendingToolCall`/`ChatController.previewPendingToolCall` that
  re-resolves the call (side-effect-free) to detect `ToolReferenceConfirmationNeeded` and look up the reference
  project's name for the confirmation card; this is fetched lazily via `FutureBuilder` in `agent_step_list.dart`.

QA rejected on 2026-06-14. Bug appended — agent shows empty messages when a request refers to a
file (e.g. scan.png); no step cards appear, only plain chat streaming works.

## Bug

**Reported:** 2026-06-14
**Found during:** Visual QA
**Description:** In an agent-mode conversation, asking the assistant about a file in the working
project (e.g. `scan.png`) results in an empty assistant message — no step card is rendered for any
tool call, and no final text response appears. Only plain chat streaming (no tool calls) currently
produces visible output.

### What to fix
_To be investigated during implementation._

### Acceptance Criteria
- [ ] Bug no longer reproduces
- [ ] Original acceptance criteria still met
- [ ] A test exists that would have caught this

Bug fixed on 2026-06-14. `OllamaDatasource._toOllamaMessage` and `OpenAiCompatibleDatasource._toOpenAiMessage`
now echo an `assistant` message's `toolCalls` as a `tool_calls` array (Ollama: `arguments` as a JSON object;
OpenAI-compatible: `arguments` as a JSON-encoded string) when non-empty. Previously, `AgentLoopRunner`'s
second `streamChat` call (after a tool result is appended) sent that assistant message as
`{role: "assistant", content: ""}` with no `tool_calls`, so the model received an incomplete history and
returned an empty response — rendering as an empty bubble with no step card. `AnthropicDatasource` already
serialized this correctly and was left unchanged. Added datasource-level regression tests for both providers
asserting the request body includes the echoed `tool_calls`.
