---
id: issue-021
title: "fetch_page tool: fetch a URL and return readable text"
feature: deep-research
status: qa
created_at: 2026-06-14
tags: [afk, p2]
---

# [021] fetch_page tool: fetch a URL and return readable text

**Type:** AFK
**Priority:** P2
**Blocked by:** None
**User stories covered:** 7 (`prd-agent-capabilities-expansion.md`)

---

## What to build

A new `fetch_page` tool that `GET`s a URL and returns its readable text content, mirroring
`odysseus`'s page-fetch step. This issue covers the tool definition, datasource, and
`AgentLoopRunner` dispatch only — it is added to the Deep Research tool set in issue 022, not to
`kAgentTools`.

---

## Acceptance criteria

- [x] `kFetchPageTool` `ToolDefinition` exists (`fetch_page`, one required `url: string`
  argument), kept separate from `kAgentTools`.
- [x] A datasource performs `GET {url}` and strips the HTML response down to readable text
  (tag-stripping + entity-decoding — no new package).
- [x] `AgentLoopRunner` dispatches `fetch_page` calls to this repository, mirroring the
  `web_search` dispatch added in issue 015.
- [x] Empty or unreadable content returns a `ToolOutput` with a clear "no readable content"
  message — not an error.
- [x] Request failures (network error, non-2xx response) return a `ToolError`.
- [x] `tool_call_summary.dart` returns the URL for `fetch_page`.

---

## Tests required

Yes — datasource tests (HTML → text extraction, empty body, non-2xx → `ToolError`) using the
`_FakeAdapter`/`_dioWith` pattern from `searxng_datasource_test.dart`; `AgentLoopRunner`/
`ChatController` dispatch test mirroring issue 015's `web_search` tests.

---

## Notes

- No new package, per CLAUDE.md — use a regex-based tag-strip/entity-decode for HTML → text. If
  this proves insufficient during implementation, append a `## Flagged` section describing the gap
  rather than adding a dependency.
- `fetch_page` is only added to the Deep Research tool set (issue 022), not `kAgentTools` — agent
  mode's file-tool set stays fixed per issue 015's notes.

---

## Log

Added `kFetchPageTool` (`agent_tools.dart`, kept out of `kAgentTools`), `PageFetchDatasource`
(`GET` + regex-based script/style/tag stripping and entity-decoding, no new package), and
`FetchPageRepositoryImpl` (wraps results as `ToolOutput`/`ToolError`, "no readable content"
message for empty pages). Wired `FetchPageRepository` into `AgentLoopRunner._executeWithResolvedPaths`
and `ChatController`, with DI registration in `home/di.dart`. Added the `fetch_page` case to
`tool_call_summary.dart` (returns the `url` argument).

Tests added: `page_fetch_datasource_test.dart` (GET request shape, HTML→text stripping, empty
body, non-2xx throws), `fetch_page_repository_impl_test.dart` (ToolOutput with text, "no readable
content" for empty page, ToolError on request failure/non-2xx), `tool_call_summary_test.dart`
(`fetch_page` → url), and two `ChatController` agent-loop tests mirroring issue 015's `web_search`
dispatch tests (dispatched to `FetchPageRepository` not `AgentToolRepository`; "not configured"
`ToolError` when unset).

`flutter test` → 356 passed, 0 failed. `flutter analyze` → clean except the 2 pre-existing
`deprecated_member_use` infos.
