---
id: issue-007
title: "Ollama datasource: tool-call parsing (send tools, parse message.tool_calls)"
feature: home-chat-agent-mode
status: done
created_at: 2026-06-14
tags: [afk, p1]
---

# [007] Ollama datasource: tool-call parsing (send tools, parse message.tool_calls)

**Type:** AFK
**Priority:** P1
**Blocked by:** 005
**User stories covered:** 26 (Ollama portion)

---

## What to build

Implement tool-calling for `ollama_datasource.dart`/`ollama_repository_impl.dart`, building on the
`ChatStreamEvent`/`ToolDefinition` contract from issue 005.

- When `tools` is non-empty, send it in `/api/chat`'s request body using the OpenAI function-calling JSON
  Schema shape (`tools: [{ type: "function", function: { name, description, parameters } }]`).
- The final response chunk (`done: true`) carries `message.tool_calls`; map each entry to a `ToolCall`
  (`{ id, name, arguments }`) and emit the tool-call-requested `ChatStreamEvent` variant instead of (or in
  addition to, if there's also text content) the text-delta variant for that turn.
- Outgoing `tool`-role `ChatMessage`s (from `ChatController`'s agent loop, issue 008) map to Ollama's
  `role: "tool"` message shape in the outgoing `messages` array.

---

## Acceptance criteria

- [ ] When `tools` is non-empty, the outgoing `/api/chat` request body includes a `tools` array in Ollama's
  expected shape, built from the `ToolDefinition` list.
- [ ] When `tools` is empty, the request body has no `tools` key (unchanged from issue 005).
- [ ] A canned streaming response whose final chunk includes `message.tool_calls` is parsed into a
  tool-call-requested `ChatStreamEvent` containing the corresponding `ToolCall`s.
- [ ] `tool`-role `ChatMessage`s in the outgoing `messages` array are serialized with `role: "tool"` per
  Ollama's expected shape.
- [ ] A canned streaming response with no `tool_calls` still emits only text-delta events (regression check).

---

## Tests required

Yes — extend `test/features/home/data/datasource/ollama_datasource_test.dart`'s `_FakeAdapter`/Dio pattern:
assert the outgoing request body includes `tools` when provided, and that a canned streaming response
containing `message.tool_calls` is parsed into the expected `ChatStreamEvent` sequence (per PRD's Datasource
testing decisions).

---

## Notes

- Depends on 005 for `ChatStreamEvent`/`ToolDefinition`/`ToolCall` types and the updated `streamChat()`
  signature.
- This is the first of three provider-specific tool-call-parsing issues (Ollama → OpenAI-compatible →
  Anthropic), per the PRD's provider implementation order — Ollama is the user's daily driver and ships
  first.
- See PRD section "Provider implementation order", item 1.

---

## Log

- Implemented `OllamaDatasource.streamChat()`: sends `tools` (OpenAI function-calling JSON Schema shape, `{type: "function", function: {name, description, parameters}}`) only when non-empty; outgoing `messages` use a new `_toOllamaMessage` mapper so `ChatRole.tool` becomes `{role: "tool", content: message.content}` (kept simple per issue notes — no `tool_call_id`/`tool_name` echoed, since Ollama's `/api/chat` doesn't require it).
- Final chunk (`done: true`) parsing now checks `message.tool_calls`; each entry maps via `_toToolCall` to a `ToolCall { id, name: function.name, arguments: function.arguments }`. Ollama entries observed without an `id` field get a deterministic `call_<index>` id based on position in the `tool_calls` array. If `message.content` is non-empty on the final chunk, a `ChatStreamTextDelta` is emitted before the `ChatStreamToolCallsRequested` event.
- `OllamaRepositoryImpl` required no changes — it already passed `tools` through from issue 005.
- Added a `streamChat()` test group to `ollama_datasource_test.dart` (8 tests total now pass): empty-tools regression (no `tools` key), non-empty-tools request shape, `message.tool_calls` parsing into `ChatStreamToolCallsRequested`, tool-role message serialization, and a no-tool-calls regression (text-deltas only). `flutter test test/features/home/` (64 tests) and `flutter analyze` on touched files both pass clean.

**Update (issue 010 bugfix):** `_toOllamaMessage` now also echoes an `assistant` message's `toolCalls` as
`tool_calls: [{id, type: "function", function: {name, arguments}}]` (with `arguments` as a JSON object, per
Ollama's `/api/chat` shape) when non-empty — previously the second `streamChat` call in the agent loop sent
this assistant message as `{role: "assistant", content: ""}` with no `tool_calls`, leaving the model without
context for the following `tool`-role message and causing it to return an empty response. New datasource test
added: "echoes an assistant message's tool_calls (with object arguments) ahead of the tool result".

QA approved by user on 2026-06-14.
