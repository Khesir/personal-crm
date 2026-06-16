---
id: issue-005
title: "Flutter agent feature — AgentController + ChatPane rewrite"
feature: agent
status: backlog
created_at: 2026-06-16
tags: [afk, p1]
---

# [005] Flutter agent feature — AgentController + ChatPane rewrite

**Type:** AFK
**Priority:** P1
**Blocked by:** 004
**User stories covered:** 1, 10, 11

---

## What to build

Create the new `features/agent/` Flutter module and rewrite `ChatPane` to use it. This replaces the current `ChatPane` which wraps `HomeChatSection` with a new implementation backed by `AgentController`.

The module follows standard structure: `AgentController` (StreamState), `AgentRepository` (abstract interface), `AgentRepositoryImpl` (SSE client), `AgentDatasource` (HTTP). Expose via `agent/api.dart` and register in `agent/di.dart`.

`AgentController` owns:
- Active session ID (null until first message sent)
- Current working project path (null = general-purpose mode)
- List of events received from the SSE stream
- Status: `idle | running | done | error | stopped`

`AgentDatasource` connects to `localhost:8765` (port read from settings), POSTs to `/chat`, and parses the SSE stream into typed event models matching the format defined in issue 004: `AgentTextEvent`, `AgentThinkingEvent`, `AgentToolCallEvent`, `AgentToolResultEvent`, `AgentDoneEvent`, `AgentErrorEvent`.

`ChatPane` is rewritten as a proper chat UI:
- Scrollable transcript of turns (user messages + assistant events)
- Text input at the bottom with send button
- Thinking steps, tool calls, and tool results rendered as collapsible tiles within the assistant's turn
- Streaming text rendered token by token as `text` events arrive

---

## Acceptance criteria

- [ ] `features/agent/` module exists with full clean-architecture structure
- [ ] `AgentController` transitions `idle → running → done/error/stopped` correctly
- [ ] SSE events are parsed and appended to the event list in order
- [ ] `ChatPane` renders a message input and scrollable transcript
- [ ] Sending a message triggers a loop run and streams the response into the transcript
- [ ] Thinking and tool events render as collapsible tiles
- [ ] Agent server unreachable shows an error state in the pane (not a crash)

---

## Tests required

Yes:
- `AgentController` state machine with fake `AgentRepository` — same pattern as the deleted `agent_run_controller_test.dart`
- `AgentDatasource` SSE parsing — mock HTTP server emitting raw SSE lines, assert correct typed events
- `ChatPane` widget test — assert input renders, submit triggers controller, event tiles appear

---

## Notes

`AgentController` reads the port from settings (not hardcoded). If settings have no port configured, default to `8765`. The `ChatPane` no longer wraps `HomeChatSection` — they are now independent surfaces with separate controllers.

---

## Log

_Updated as work progresses._
