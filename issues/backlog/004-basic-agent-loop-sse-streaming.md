---
id: issue-004
title: "Basic agent loop + SSE streaming (no tools, plain chat)"
feature: agent
status: backlog
created_at: 2026-06-16
tags: [afk, p1]
---

# [004] Basic agent loop + SSE streaming (no tools, plain chat)

**Type:** AFK
**Priority:** P1
**Blocked by:** 003
**User stories covered:** 1, 10

---

## What to build

Implement the core agent loop and expose it as a streaming SSE endpoint. At this stage the loop has no tools — it simply calls the LLM with the user's message and streams the response back. This establishes the SSE event format that all future issues (Flutter client, tools, Brain injection) will build on.

Endpoint: `POST /chat`

Request body:
```json
{
  "session_id": "string | null",
  "message": "string",
  "local_path": "string | null"
}
```

Response: `Content-Type: text/event-stream`, streaming SSE. Each SSE event has a `type` field and type-specific fields:

| type | fields |
|---|---|
| `thinking` | `text` |
| `tool_call` | `tool`, `input` |
| `tool_result` | `tool`, `output` |
| `text` | `text` (streamed token by token) |
| `done` | `summary`, `success` |
| `error` | `message` |

The loop for this issue: receive message → call LLM → stream `text` events as tokens arrive → emit `done` when finished.

A `session_id` of `null` means a new session (server assigns one and includes it in the `done` event so Flutter can store it).

---

## Acceptance criteria

- [ ] `POST /chat` accepts the request body and responds with `text/event-stream`
- [ ] `text` events stream token by token as the LLM responds
- [ ] `done` event is emitted when the LLM finishes, with `success: true`
- [ ] `error` event is emitted if the LLM call fails
- [ ] A new session ID is assigned when `session_id` is null and returned in `done`
- [ ] SSE connection closes after `done` or `error`

---

## Tests required

Yes:
- Mock LLM provider returning deterministic tokens — assert `text` events arrive in order and `done` is last
- LLM failure — assert `error` event is emitted and connection closes
- FastAPI `TestClient` SSE integration test — POST a message, collect all events, assert sequence

---

## Notes

This issue defines the canonical SSE event format. All subsequent issues that add tools or Brain injection add events of existing types — they do not add new types. The Flutter issue (005) builds its event model directly from this spec.

---

## Log

_Updated as work progresses._
