---
id: issue-012
title: "Deep research pipeline (trigger_research + manage_research)"
feature: agent
status: backlog
created_at: 2026-06-16
tags: [afk, p2]
---

# [012] Deep research pipeline (trigger_research + manage_research)

**Type:** AFK
**Priority:** P2
**Blocked by:** 008
**User stories covered:** 8, 9

---

## What to build

Add two tools to the agent loop: `trigger_research` and `manage_research`. Together they expose a multi-step deep research pipeline that the LLM can invoke to produce a thorough, cited report on any topic.

**trigger_research** — starts the research pipeline asynchronously. Input: `{"query": "string"}`. The pipeline runs as a background task: query decomposition → multiple SearXNG searches → page fetching → synthesis → structured report. Returns a `research_id` immediately so the loop can continue. The LLM is told the research is running and can proceed with other work or wait.

Pipeline steps:
1. Decompose the query into 3–5 sub-questions
2. Run a `web_search` for each sub-question
3. `web_fetch` the top result for each search
4. Synthesise all fetched content into a structured report with citations
5. Save the report to `%APPDATA%\Avyn\agent\research\{research_id}.json`

**manage_research** — reads research results. Input: `{"research_id": "string", "action": "status" | "read"}`. `status` returns the pipeline state (`running | done | error`). `read` returns the full report when done. If the research is still running, `read` returns the current status instead.

Both tools emit `tool_call` and `tool_result` SSE events. The pipeline's intermediate steps (each sub-search, each fetch) also emit `tool_call`/`tool_result` events so Flutter can show progress inline.

---

## Acceptance criteria

- [ ] `trigger_research` starts the pipeline and returns a `research_id` immediately
- [ ] Pipeline runs: decompose → search → fetch → synthesise → save report
- [ ] Report is saved to `%APPDATA%\Avyn\agent\research\{research_id}.json`
- [ ] `manage_research` with `action: "status"` returns pipeline state
- [ ] `manage_research` with `action: "read"` returns the full report when done
- [ ] Intermediate pipeline steps emit SSE events visible in Flutter
- [ ] SearXNG unreachable degrades gracefully (error result, not crash)

---

## Tests required

Yes — mock SearXNG and web fetch:
- Assert pipeline produces a report for a known query with mocked search results
- Assert `manage_research` returns `running` while pipeline is in progress
- Assert `manage_research` returns the report when done
- Assert graceful degradation when SearXNG is unreachable

---

## Notes

Adapted from Odysseus's research pipeline pattern — not a code fork. The decomposition and synthesis steps call the same LLM provider as the main loop.

---

## Log

_Updated as work progresses._
