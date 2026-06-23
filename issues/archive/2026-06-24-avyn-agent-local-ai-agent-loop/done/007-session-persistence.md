---
id: issue-007
title: "Session persistence — SQLite, session list, resume"
feature: agent
status: done
created_at: 2026-06-16
tags: [afk, p2]
---

# [007] Session persistence — SQLite, session list, resume

**Type:** AFK
**Priority:** P2
**Blocked by:** 004
**User stories covered:** 14, 15, 16, 36

---

## What to build

Persist conversation history in SQLite so sessions survive app restarts. Store `agent.db` at `%APPDATA%\Avyn\agent\agent.db`.

Schema (two tables):

**sessions** — `id` (uuid), `created_at`, `updated_at`, `title` (first user message, truncated to 60 chars)

**messages** — `id` (uuid), `session_id` (fk), `role` (`user` | `assistant`), `content` (full text of the turn), `created_at`

On each `/chat` request:
- If `session_id` is null, create a new session and return its ID in the `done` event
- If `session_id` is provided, load the full message history for that session and prepend it to the LLM's context
- After the loop completes, append the user message and the full assistant response to the `messages` table

Expose two new endpoints:
- `GET /sessions` — returns list of sessions ordered by `updated_at` desc: `[{id, title, created_at, updated_at}]`
- `DELETE /sessions/{id}` — deletes the session and all its messages

Flutter uses `GET /sessions` to populate a session list in the `ChatPane` header so the user can resume a past conversation or start a new one.

---

## Acceptance criteria

- [ ] `agent.db` is created at `%APPDATA%\Avyn\agent\agent.db` on first use
- [ ] New session is created when `session_id` is null; ID returned in `done` event
- [ ] Full message history for an existing session is passed to the LLM on resume
- [ ] User message and assistant response are saved after each loop run
- [ ] `GET /sessions` returns sessions ordered by `updated_at` desc
- [ ] `DELETE /sessions/{id}` removes session and all messages
- [ ] Session title is the first user message truncated to 60 chars

---

## Tests required

Yes — in-memory SQLite for tests:
- Assert new session created when `session_id` is null
- Assert history loaded and passed to LLM on resume
- Assert messages saved after loop completes
- Assert `GET /sessions` returns correct list
- Assert `DELETE /sessions/{id}` removes the session

---

## Notes

All conversation data stays local in SQLite — never sent to any external service.

---

## Log

Implemented 2026-06-18. Created db.py with SQLite sessions/messages tables. /chat now creates/loads sessions and saves messages. Added GET /sessions and DELETE /sessions/{id} endpoints. test_session.py: all tests passing.

QA approved by user on 2026-06-24.
