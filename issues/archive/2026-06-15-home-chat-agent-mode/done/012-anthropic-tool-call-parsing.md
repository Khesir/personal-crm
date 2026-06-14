---
id: issue-012
title: "Anthropic datasource: tool-call parsing"
feature: home-chat-agent-mode
status: done
created_at: 2026-06-14
tags: [afk, p2]
---

# [012] Anthropic datasource: tool-call parsing

**Type:** AFK
**Priority:** P2
**Blocked by:** 005, 008
**User stories covered:** 26 (Anthropic portion)

---

## What to build

Implement tool-calling for `anthropic_datasource.dart`/`anthropic_repository_impl.dart`, reusing the same
`ChatStreamEvent`/agent-loop contract proven against Ollama in issues 005-008. No changes to
`ChatController`'s agent loop — it is provider-agnostic.

- Send `tools` (when non-empty) using Anthropic's `input_schema` shape (`tools: [{ name, description,
  input_schema }]` — same JSON Schema content as the other providers' `parameters`, different wrapping key).
- Accumulate `content_block_start` (`type: "tool_use"`) / `content_block_delta` (`type: "input_json_delta"`) /
  `content_block_stop` events into a `ToolCall`, emitted as a tool-call-requested `ChatStreamEvent` on
  `message_stop` (or once all tool-use blocks for the turn are complete).
- Outgoing `tool`-role `ChatMessage`s map to a `user` message containing `tool_result` content blocks keyed
  by `tool_use_id` (set to the originating `ToolCall.id`).

---

## Acceptance criteria

- [ ] When `tools` is non-empty, the outgoing request body includes a `tools` array in Anthropic's
  `input_schema` shape.
- [ ] A canned SSE stream containing `content_block_start`(`tool_use`)/`content_block_delta`
  (`input_json_delta`)/`content_block_stop` events is parsed into a tool-call-requested `ChatStreamEvent`
  with correctly reassembled `ToolCall.arguments`.
- [ ] `tool`-role `ChatMessage`s are serialized as a `user` message with `tool_result` content blocks,
  `tool_use_id` set to the originating `ToolCall.id`.
- [ ] A canned SSE stream with only `text_delta` content blocks still emits only text-delta
  `ChatStreamEvent`s (regression check).
- [ ] An agent-mode conversation using an Anthropic model completes the full agent loop (tool call → result →
  final answer) via `ChatController`, with no controller changes required.

---

## Tests required

Yes — extend `test/features/home/data/datasource/anthropic_datasource_test.dart`'s fake adapter pattern:
assert `tools` in the request body (Anthropic's `input_schema` shape) when provided, and that a canned SSE
stream containing tool-use content blocks parses into the expected `ChatStreamEvent` sequence, per the PRD's
Datasource testing decisions.

---

## Notes

- Depends on 005 (contract) and 008 (agent loop — this issue proves the loop is provider-agnostic by reusing
  it unchanged).
- Third of three provider-specific tool-call-parsing issues, per the PRD's provider implementation order —
  this is the final issue completing the PRD's scope.
- See PRD section "Provider implementation order", item 3.

---

## Log

_Updated as work progresses._

Implemented `tools` -> `input_schema` shape in the outgoing request body, accumulation of
`content_block_start`(`tool_use`)/`content_block_delta`(`input_json_delta`)/`content_block_stop` events
per content-block `index` via a `_ToolUseBuilder`, emitting `ChatStreamToolCallsRequested` at `message_stop`.
Outgoing message mapping now serializes assistant messages with `toolCalls` as `assistant` messages
containing `tool_use` blocks, and `tool`-role messages as `user` messages with `tool_result` blocks.
Judgment call: consecutive `tool`-role `ChatMessage`s are merged into a single `user` message with one
`tool_result` block per tool result, since Anthropic's API rejects consecutive `user` turns — this mirrors
the common multi-tool-call agent-loop pattern (one assistant turn requesting N tools, followed by N tool
results in a single user turn).
Extended `test/features/home/data/datasource/anthropic_datasource_test.dart` with 6 new tests covering:
tools omitted/included in `input_schema` shape, tool_use SSE accumulation into `ChatStreamToolCallsRequested`,
text-only SSE regression (no tool-calls event), tool-role -> `tool_result` mapping, and consecutive
tool-role merging. All 11 tests in the file pass; `flutter analyze` on touched files is clean.

QA approved by user on 2026-06-14.
