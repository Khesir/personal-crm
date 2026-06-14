---
id: issue-011
title: "OpenAI-compatible datasource: tool-call parsing"
feature: home-chat-agent-mode
status: qa
created_at: 2026-06-14
tags: [afk, p2]
---

# [011] OpenAI-compatible datasource: tool-call parsing

**Type:** AFK
**Priority:** P2
**Blocked by:** 005, 008
**User stories covered:** 26 (OpenAI-compatible portion)

---

## What to build

Implement tool-calling for `openai_compatible_datasource.dart`/`openai_compatible_repository_impl.dart`,
reusing the same `ChatStreamEvent`/agent-loop contract proven against Ollama in issues 005-008. No changes to
`ChatController`'s agent loop — it is provider-agnostic.

- Send `tools` (when non-empty) in the request body using OpenAI's `tools` JSON Schema shape (same shape as
  Ollama's, per PRD).
- Accumulate streamed `delta.tool_calls[].function.arguments` string fragments per call `id` until
  `finish_reason: "tool_calls"`, then parse each accumulated string as JSON arguments and emit the
  tool-call-requested `ChatStreamEvent`.
- Outgoing `tool`-role `ChatMessage`s map to `role: "tool"` with `tool_call_id` set to the originating
  `ToolCall.id`.

---

## Acceptance criteria

- [ ] When `tools` is non-empty, the outgoing request body includes a `tools` array in OpenAI's expected
  shape.
- [ ] A canned streaming response with `delta.tool_calls` fragments across multiple chunks, ending in
  `finish_reason: "tool_calls"`, is parsed into a tool-call-requested `ChatStreamEvent` with correctly
  reassembled `ToolCall.arguments` (parsed from the accumulated JSON string).
- [ ] `tool`-role `ChatMessage`s in the outgoing `messages` array are serialized as `{ role: "tool",
  tool_call_id: ..., content: ... }`.
- [ ] A canned streaming response with `finish_reason: "stop"` and no `tool_calls` still emits only
  text-delta events (regression check).
- [ ] An agent-mode conversation using an OpenAI-compatible model completes the full agent loop (tool call →
  result → final answer) via `ChatController`, with no controller changes required.

---

## Tests required

Yes — extend `test/features/home/data/datasource/openai_compatible_datasource_test.dart`'s fake adapter
pattern: assert `tools` in the request body when provided, and that a canned streaming response with
accumulated `tool_calls` fragments parses into the expected `ChatStreamEvent` sequence, per the PRD's
Datasource testing decisions.

---

## Notes

- Depends on 005 (contract) and 008 (agent loop — this issue proves the loop is provider-agnostic by reusing
  it unchanged).
- Second of three provider-specific tool-call-parsing issues, per the PRD's provider implementation order.
- See PRD section "Provider implementation order", item 2.

---

## Log

_Updated as work progresses._

Implemented `tools` in OpenAI function-calling shape on the request body, per-index accumulation of
streamed `delta.tool_calls` fragments (id/name from first chunk, `arguments` concatenated as a string and
`jsonDecode`d on `finish_reason: "tool_calls"`), and `tool`-role messages serialized as
`{role: "tool", tool_call_id, content}`. Added
`test/features/home/data/datasource/openai_compatible_datasource_test.dart` (6 tests, all passing) covering:
tools omitted/included in request body, multi-chunk tool_calls reassembly, text-deltas-then-tool-calls
ordering, tool-role serialization, and the `finish_reason: "stop"` text-only regression. `flutter analyze`
clean (no new issues). Repository impl already forwarded `tools` (issue 005), no change needed.

**Update (issue 010 bugfix):** `_toOpenAiMessage` now also echoes an `assistant` message's `toolCalls` as
`tool_calls: [{id, type: "function", function: {name, arguments}}]` (with `arguments` as a JSON-encoded
string, per OpenAI's `/v1/chat/completions` shape) when non-empty — previously the second `streamChat` call
in the agent loop sent this assistant message as `{role: "assistant", content: ""}` with no `tool_calls`,
leaving the model without context for the following `tool`-role message and causing it to return an empty
response. New datasource test added: "echoes an assistant message's tool_calls (with stringified arguments)
ahead of the tool result".
