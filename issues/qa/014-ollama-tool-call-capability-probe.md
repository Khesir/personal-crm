---
id: issue-014
title: "Ollama supportsTools: live capability probe to catch models that don't actually emit tool_calls"
feature: home-chat-agent-mode
status: qa
created_at: 2026-06-14
tags: [afk, p3]
---

# [014] Ollama supportsTools: live capability probe to catch models that don't actually emit tool_calls

**Type:** AFK
**Priority:** P3
**Blocked by:** None

---

## What to build

Visual QA on agent mode (issues 009/010) showed the assistant responding with literal JSON text
describing a function call (e.g. `{"type": "function", "name": "read_file", "parameters": {...}}`)
inside its normal message content, instead of Ollama's structured `message.tool_calls` field. When
this happens, `ChatStreamToolCallsRequested` is never emitted, `message.toolCalls` stays empty, and
the agent-loop/step-card UI (correctly) never activates — the turn just renders as a plain
streaming text reply.

Root cause: `OllamaRepositoryImpl.supportsTools()` (issue 009) only checks `/api/show`'s
`capabilities` array for `"tools"`. A model's Ollama metadata can list `"tools"` as a capability
while its actual chat template never populates `tool_calls` for real prompts — `/api/show` is
aspirational, not a guarantee.

Fix: make `supportsTools()` a two-stage check:

1. Cheap pre-filter (unchanged): if `/api/show`'s `capabilities` omit `"tools"`, return `false`
   immediately — no further requests.
2. Live probe: if `"tools"` is present, send one non-streaming `/api/chat` request with a trivial
   no-arg probe tool (`__capability_probe__`) and a prompt instructing the model to call it,
   capped to a small `num_predict`. `supportsTools()` returns `true` only if the response's
   `message.tool_calls` actually includes a call to the probe tool.

---

## Acceptance criteria

- [x] `supportsTools()` returns `false` without any `/api/chat` request when `/api/show`'s
  `capabilities` omit `"tools"`.
- [x] `supportsTools()` returns `true` when `capabilities` include `"tools"` and the probe
  request's response includes a `tool_calls` entry for the probe tool.
- [x] `supportsTools()` returns `false` when `capabilities` include `"tools"` but the probe
  request's response contains no `tool_calls` (e.g. plain text describing a call) — this is the
  scenario from scan2.png.
- [x] The probe tool, prompt, and token cap are named constants, not inline literals.

---

## Tests required

Yes — extended `ChatController`'s `refresh()`/`supportsTools` coverage in
`chat_controller_test.dart` (via the existing fake-Dio-backed `OllamaRepositoryImpl`) with the three
scenarios above.

---

## Notes

- Surfaced during visual QA of issues 009/010 (see `issues/qa-report.md`, 2026-06-14).
- Related but independent of issues 007/011's `tool_calls` *serialization* fix (assistant messages
  with `toolCalls` on the second round-trip) — that fix is necessary for multi-step turns but does
  not address a model that never produces `tool_calls` in the first place.
- Tradeoff accepted: one extra small (`num_predict`-capped) generation request per Ollama model
  during `refresh()`, but only for models that pass the `/api/show` capability pre-filter.

---

## Log

- Added `lib/features/home/domain/model/tool_call_capability_probe.dart` with named constants:
  `kToolCallProbeName` (`__capability_probe__`), `kToolCallProbeTool` (a no-arg `ToolDefinition`),
  `kToolCallProbePrompt`, and `kToolCallProbeMaxTokens` (32).
- Added `OllamaDatasource.probeToolCall({model, tool, prompt, maxTokens})`: a single non-streaming
  `POST /api/chat` request with `tools: [tool]`, `options: {num_predict: maxTokens}`; returns
  whether `message.tool_calls` includes a call to `tool.name`.
- `OllamaRepositoryImpl.supportsTools()` now checks `/api/show` capabilities first (unchanged, fails
  closed/no probe if `"tools"` absent), then runs `probeToolCall` with the new constants — only
  returns `true` if both pass.
- Tests: rewrote the existing "`supportsTools: true`" test in `chat_controller_test.dart` to also
  stub a `/api/chat` probe response with matching `tool_calls`; added two new tests — capabilities
  omit `"tools"` (asserts zero `/api/chat` requests), and capabilities include `"tools"` but the
  probe response is plain text (asserts `supportsTools: false`, reproducing the scan2.png scenario).
  `flutter test` passes (317 tests, was 316); `flutter analyze` clean (only the 2 pre-existing
  `deprecated_member_use` infos).
