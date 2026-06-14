# Kanban Board

_Last updated: 2026-06-14_

_Issues 004-008, 011, 012, 014, 018, 020, 021 (no UI surface, fully covered by automated tests)
QA-approved and moved to Done. Issues 010, 015, 016, 022 were rejected again on real-world visual
QA — agent mode is unusable in practice (tool calls/step cards don't reliably trigger, broken
step-card UI, no clear "agent mode" distinction from chat). Agent/Research modes are now disabled
(`kAgentModeEnabled = false`, Home chat is chat-only) and moved to Done to close out this cycle;
this area will be redesigned under a new PRD — see `docs/handoffs/handoff-agent-mode-redesign.md` and
`issues/qa-report.md`._

---

## Backlog
Issues with unresolved blockers.

| Issue | Title | Type | Priority | Blocked by |
|-------|-------|------|----------|------------|

---

## Ready
No blockers. Ready to be picked up.

| Issue | Title | Type | Priority |
|-------|-------|------|----------|

---

## In Progress
Currently being implemented.

| Issue | Title | Type | Priority |
|-------|-------|------|----------|

---

## QA
Implementation done. Tests pass. Waiting for review.

| Issue | Title | Type | Priority |
|-------|-------|------|----------|

---

## Done
Approved and complete, or closed out as superseded (see notes below).

| Issue | Title | Type | Priority |
|-------|-------|------|----------|
| [001](done/001-brain-repository-seed-read-assemble.md) | Brain repository: seed, read & assemble system prompt | AFK | P1 |
| [002](done/002-inject-brain-into-chat-system-prompt.md) | Inject brain into Home chat's system prompt | AFK | P1 |
| [003](done/003-settings-open-brain-folder.md) | Settings: "Brain" section with Open brain folder button | AFK | P2 |
| [004](done/004-agent-mode-domain-model.md) | Agent-mode domain model: ChatRole.tool, ToolCall, ChatMessage/ChatConversation fields | AFK | P1 |
| [005](done/005-chatmodelrepository-streamchat-event-contract.md) | ChatModelRepository.streamChat() contract change: ChatStreamEvent + ToolDefinition | AFK | P1 |
| [006](done/006-agent-tool-repository-file-tools.md) | AgentToolRepository: file tools with path-boundary enforcement | AFK | P1 |
| [007](done/007-ollama-tool-call-parsing.md) | Ollama datasource: tool-call parsing | AFK | P1 |
| [008](done/008-chatcontroller-agent-loop.md) | ChatController agent loop: tool execution, approvals, step limit | AFK | P1 |
| [009](done/009-agent-mode-conversation-creation-and-branching.md) | Agent-mode conversation creation + branching UI, CookbookEntry.supportsTools | AFK | P2 |
| [011](done/011-openai-compatible-tool-call-parsing.md) | OpenAI-compatible datasource: tool-call parsing | AFK | P2 |
| [012](done/012-anthropic-tool-call-parsing.md) | Anthropic datasource: tool-call parsing | AFK | P2 |
| [013](done/013-home-chat-mode-toggle.md) | Home chat: Chat/Agent mode segmented toggle in header | AFK | P2 |
| [014](done/014-ollama-tool-call-capability-probe.md) | Ollama supportsTools: live capability probe to catch models that don't actually emit tool_calls | AFK | P3 |
| [017](done/017-shell-access-toggle.md) | Per-conversation Shell access toggle | AFK | P1 |
| [018](done/018-cookbook-fit-result.md) | Cookbook fit-result computation for local models | AFK | P2 |
| [019](done/019-cookbook-fit-badges.md) | Fit badges in the Home chat model switcher | AFK | P2 |
| [020](done/020-recommended-pick-default-model.md) | Recommended pick: default model selection by hardware fit | AFK | P2 |
| [021](done/021-fetch-page-tool.md) | fetch_page tool: fetch a URL and return readable text | AFK | P2 |
| [010](done/010-step-card-ui.md) | Step-card UI: collapsible tool-call cards, diffs, approve/reject — **superseded, see handoff** | AFK | P2 |
| [015](done/015-agent-web-search-tool.md) | Agent web search tool: SearXNG-backed web_search for agent-mode conversations — **superseded, see handoff** | AFK | P2 |
| [016](done/016-run-command-tool.md) | run_command tool: cwd-scoped execution with mandatory Approve/Reject — **superseded, see handoff** | AFK | P1 |
| [022](done/022-deep-research-mode.md) | Deep Research mode — **superseded, see handoff** | AFK | P2 |
