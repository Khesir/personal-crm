---
id: issue-008
title: "web_search + web_fetch tools"
feature: agent
status: backlog
created_at: 2026-06-16
tags: [afk, p2]
---

# [008] web_search + web_fetch tools

**Type:** AFK
**Priority:** P2
**Blocked by:** 004
**User stories covered:** 2, 3, 34

---

## What to build

Add two tools to the agent loop: `web_search` and `web_fetch`.

**web_search** — queries the local SearXNG instance. SearXNG URL defaults to `http://localhost:8080` (configurable in `config.json`). Input: `{"query": "string", "max_results": 5}`. Returns a list of `{title, url, snippet}` objects. If SearXNG is unreachable, the tool returns an error result (not a server crash) and the loop emits a `tool_result` event with an error message. The `ChatPane` in Flutter surfaces a visible warning when this happens.

**web_fetch** — fetches a URL and returns its text content. Strips HTML tags to plain text. Input: `{"url": "string"}`. Returns the page content truncated to a configurable max length (default 8000 chars). If the URL is unreachable or returns a non-200 response, returns an error result.

Both tools emit `tool_call` and `tool_result` SSE events so Flutter can render them inline.

---

## Acceptance criteria

- [ ] `web_search` tool is registered in the agent loop and callable by the LLM
- [ ] `web_search` queries SearXNG and returns structured results
- [ ] `web_search` returns an error result (not a crash) when SearXNG is unreachable
- [ ] `web_fetch` fetches a URL and returns stripped plain text
- [ ] `web_fetch` returns an error result when the URL fails
- [ ] Both tools emit `tool_call` + `tool_result` SSE events
- [ ] SearXNG URL is configurable in `config.json`

---

## Tests required

Yes — mock SearXNG HTTP server:
- Assert `web_search` returns structured results for a successful query
- Assert `web_search` returns error result when SearXNG returns 500 or is unreachable
- Assert `web_fetch` returns stripped text for a successful URL
- Assert `web_fetch` returns error result for a bad URL

---

## Notes

SearXNG runs via Docker — if it is not running, these tools degrade gracefully with error results. The Flutter `ChatPane` should detect `tool_result` error messages from these tools and surface a "SearXNG not running" hint to the user.

---

## Log

_Updated as work progresses._
