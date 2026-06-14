---
id: issue-015
title: "Agent web search tool: SearXNG-backed web_search for agent-mode conversations"
feature: home-chat-agent-mode
status: qa
created_at: 2026-06-14
tags: [afk, p2]
---

# [015] Agent web search tool: SearXNG-backed `web_search` for agent-mode conversations

**Type:** AFK
**Priority:** P2
**Blocked by:** None

---

## What to build

First slice of the broader "Avyn as a general assistant" pivot (search, improved
Cookbook, Deep Research, etc. — see `issues/prd-agent-capabilities-expansion.md`
for the rest). This issue covers only the web search tool.

Add a `web_search` tool to the fixed agent tool set (`kAgentTools`) so agent-mode
conversations can search the web, following the same `ToolDefinition` /
`AgentLoopRunner` dispatch pattern as the existing file tools (issues 004-008).

- New `ToolDefinition kWebSearchTool`: `name: 'web_search'`, one required string
  argument `query`, one optional integer argument `count` (max results).
- New `WebSearchRepository` abstract interface (domain) with
  `Future<ToolExecutionResult> search(String query, {int? count})`.
- New `SearxngDatasource` (data) — `GET {baseUrl}/search?q=...&format=json&language=en`
  against a self-hosted SearXNG instance (mirrors the provider odysseus defaults to).
  No API key required.
- New `WebSearchRepositoryImpl` — calls the datasource and formats up to `count`
  (default 5) results as `ToolOutput` text: one block per result with title, URL,
  and snippet. Empty `results` → `ToolOutput('No results found.')`. Request
  failure → `ToolError` with a short message.
- `AgentLoopRunner` gains an optional `webSearchRepository` constructor param.
  In its single tool-call dispatch point (`_executeWithResolvedPaths`), `web_search`
  calls are routed to `webSearchRepository.search(...)` instead of
  `agentToolRepository.execute(...)`. If `webSearchRepository` is `null`, return
  `ToolError('Web search is not configured. Add a SearXNG service in Settings → Services.')`.
- `ChatController` accepts and forwards an optional `webSearchRepository` to
  `AgentLoopRunner`.
- Settings → Services: new `ServiceType.searxng` in `ServiceCategory.services`
  (alongside n8n / Custom URL), with a `baseUrl` field (default
  `http://localhost:8080`, matching odysseus's bundled SearXNG). Health check
  reuses the existing "any response = online" check used for n8n/Custom URL.
  `home/di.dart` builds `WebSearchRepositoryImpl` from
  `ServiceCardsCache.instance.field(ServiceType.searxng, 'baseUrl')` when
  non-empty, and passes `null` otherwise.
- Step-card summary (`toolCallSummary`): `web_search` calls show the `query`
  argument in the collapsed header (currently only `path`/`pattern` are handled).

---

## Acceptance criteria

- [ ] `kAgentTools` includes `kWebSearchTool` with `query` (required) and `count`
  (optional) parameters.
- [ ] `WebSearchRepositoryImpl.search()` returns a `ToolOutput` listing each
  result's title, URL, and snippet, capped to `count` (default 5).
- [ ] `WebSearchRepositoryImpl.search()` returns `ToolOutput('No results found.')`
  when SearXNG returns an empty `results` array.
- [ ] `WebSearchRepositoryImpl.search()` returns a `ToolError` when the SearXNG
  request fails (network error / non-2xx).
- [ ] A `web_search` tool call in an agent-mode conversation is dispatched to
  `WebSearchRepository` (not `AgentToolRepository`) and its result is appended as
  a `tool`-role message, same as file-tool results.
- [ ] When no SearXNG service is configured, a `web_search` tool call resolves to
  a `ToolError` explaining how to configure one — the agent loop still continues
  (does not crash or hang).
- [ ] `toolCallSummary` shows the `query` argument for `web_search` step cards.
- [ ] 👁 New `ServiceType.searxng` card is addable/editable/deletable under
  Settings → Services → Services, with health check status.

---

## Tests required

Yes:
- `WebSearchRepositoryImpl`/`SearxngDatasource`: parses a SearXNG JSON response
  into formatted `ToolOutput` text (multiple results, capped to `count`); empty
  `results` → `'No results found.'`; request failure → `ToolError`.
- `ChatController`/`AgentLoopRunner` (via `chat_controller_test.dart`, mirroring
  the existing `read_file` tool-call tests): a `web_search` tool call dispatches
  to a fake `WebSearchRepository` and its `ToolOutput`/`ToolError` is recorded as
  a `tool`-role message; with `webSearchRepository: null`, a `web_search` call
  resolves to the "not configured" `ToolError` and the loop continues.
- `toolCallSummary`: `web_search` call shows its `query` argument.
- `ServiceType.searxng` round-trips through `ServiceCard.toJson`/`fromJson`.

---

## Notes

- Mirrors odysseus's default search provider (`services/search/providers.py`,
  `searxng_search_api`): SearXNG JSON API, `format=json`, `language=en`,
  no API key. Odysseus also supports Brave/DuckDuckGo/Google PSE/Tavily/Serper —
  out of scope for v1; SearXNG only, since it's self-hostable and matches this
  app's local-first/privacy-first stance.
- Follows the existing `ServiceCategory.services` pattern (`n8n`, `customUrl`):
  add `ServiceType.searxng` to `ServiceCard`'s enum + `kServiceTypeLabels` +
  `_kBackCompatTypes` (`service_cards_cache.dart` and
  `service_cards_controller.dart`) + `services_section.dart`'s available types +
  `health_check_repository_impl.dart`'s exhaustive switch (`_checkUniformGet`,
  same as n8n/customUrl).
- `web_search` never produces a `ToolWriteProposal` — it's read-only, so it
  always resolves immediately (no approve/reject step), same as `read_file`/
  `list_dir`/`grep`.

---

## Log

- Added `kWebSearchTool` (`web_search`, `query` required, `count` optional) to `kAgentTools`.
- Added `WebSearchRepository` interface, `SearxngDatasource` (`GET {baseUrl}/search?format=json&q=...&language=en`),
  and `WebSearchRepositoryImpl` (formats results to `ToolOutput`, `'No results found.'` for empty, `ToolError` on
  request failure, capped to `count`/default 5).
- `AgentLoopRunner` gained an optional `webSearchRepository`; `web_search` calls are dispatched to it (or to a
  "not configured" `ToolError` when `null`) instead of `AgentToolRepository`. Threaded through `ChatController`
  and `home/di.dart` (built from `ServiceCardsCache.instance.field(ServiceType.searxng, 'baseUrl')`).
- Added `ServiceType.searxng` (label "SearXNG", default base URL `http://localhost:8080`) to the `Services`
  category in Settings, reusing the n8n/Custom URL health check.
- `toolCallSummary` shows the `query` argument for `web_search` step cards.
- Tests: `SearxngDatasource`/`WebSearchRepositoryImpl` unit tests (parsing, empty results, count cap, request
  failure); `chat_controller_test.dart` agent-loop tests for `web_search` dispatch (success via
  `FakeWebSearchRepository`, and "not configured" when `null`); `toolCallSummary` `web_search` case;
  `ServiceType` round trip updated for the new 15th type. `flutter test` passes (251 tests); `flutter analyze`
  clean (only the 2 pre-existing `deprecated_member_use` infos).

QA rejected on 2026-06-14. Bug appended — agent-mode chat doesn't work, so the web_search tool
couldn't be visually verified.

## Bug

**Reported:** 2026-06-14
**Found during:** Visual QA
**Description:** Agent-mode chat doesn't produce any visible response (see issue 010's bug —
empty assistant messages, no step cards), so a `web_search` tool call could not be triggered or
observed at all. This issue's visual checklist item could not be tested.

### What to fix
_To be investigated during implementation._

### Acceptance Criteria
- [ ] Bug no longer reproduces
- [ ] Original acceptance criteria still met
- [ ] A test exists that would have caught this

Bug fixed on 2026-06-14. Resolved by issue 010's datasource fix to AgentLoopRunner's
second-round-trip message serialization. Re-verified web_search's tool-call round trip +
acceptance criteria; strengthened the existing "web_search call is dispatched to
WebSearchRepository" test in `chat_controller_test.dart` to assert the second `streamChat`
call's history includes the assistant message's `toolCalls` (id `call-1`, name `web_search`)
and the corresponding `tool`-role result message with the search results text — confirming
the agent loop's domain-level round trip was always correct, and that issue 010's datasource
serialization fix is what unblocks the visual "Agent uses web search" checklist item.
