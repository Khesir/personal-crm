---
id: issue-022
title: "Deep Research mode"
feature: deep-research
status: done
created_at: 2026-06-14
tags: [afk, p2]
---

# [022] Deep Research mode

**Type:** AFK
**Priority:** P2
**Blocked by:** 021
**User stories covered:** 5, 6, 8, 9, 10, 11 (`prd-agent-capabilities-expansion.md`)

---

## What to build

Add a "Deep Research" mode alongside Chat/Agent (issue 013). Given a topic/question, a Deep
Research conversation plans and runs several `web_search`/`fetch_page` calls (issues 015/021)
across different angles via the existing `AgentLoopRunner` tool-call loop, then synthesizes a
final answer citing the sources it used. Not a new agent loop — the existing loop (issue 008) with
a different tool set, step ceiling, and system prompt.

---

## Acceptance criteria

- [x] A "Deep Research" mode is selectable alongside Chat/Agent (issue 013's mode toggle).
- [x] Deep Research conversations pass `[kWebSearchTool, kFetchPageTool]` to `streamChat()`,
  reusing `AgentLoopRunner`.
- [x] A new `kMaxDeepResearchSteps` constant governs the step ceiling, distinct from
  `kMaxAgentLoopSteps`.
- [x] A Deep Research system-prompt addition instructs the model to run multiple searches across
  different angles before answering, and to cite source URLs in its final answer.
- [x] `web_search`/`fetch_page` calls render as step cards (issue 010), same as agent mode.
- [x] If the step limit is reached before a conclusion, the assistant returns a best-effort
  partial answer noting the limit, with whatever sources were gathered.

---

## Tests required

Yes — `AgentLoopRunner`/`ChatController` agent-loop tests (fake-repository pattern from issue 015)
for a Deep Research turn dispatching `web_search`/`fetch_page` across several round-trips and
stopping at `kMaxDeepResearchSteps` with a partial-answer notice.

---

## Notes

- Not a new agent loop — the existing `AgentLoopRunner` (issue 008) with `[kWebSearchTool,
  kFetchPageTool]`, `kMaxDeepResearchSteps`, and a Deep-Research system-prompt addition.
- Re-read issue 013's implementation before starting, to confirm where/how a third mode slots into
  the existing UI and `ChatConversation` model.
- Streaming/partial Deep Research results mid-research are out of scope — the report is the final
  message, step cards render live as usual.

---

## Log

Added a third "Research" mode alongside Chat/Agent, reusing `AgentLoopRunner` (issue 008) with no
new agent loop. `ChatConversation` gained an immutable `isDeepResearch` flag (default `false`,
mirrors `shellAccessEnabled`). New constants in `agent_loop_constants.dart`:
`kMaxDeepResearchSteps = 15` and `kDeepResearchSystemPromptAddition`. New `kDeepResearchTools =
[kWebSearchTool, kFetchPageTool]` in `agent_tools.dart`.

`AgentLoopRunner._toolsFor` returns `kDeepResearchTools` for Deep Research conversations (checked
before the `shellAccessEnabled` branch). `_continueIfReady` branches its step ceiling and
stop-notice text on `conversation.isDeepResearch` (`kMaxDeepResearchSteps` vs `kMaxAgentLoopSteps`,
with a "best-effort summary based on the sources gathered so far" notice for Deep Research).
`ChatController._buildRequestMessages` appends `kDeepResearchSystemPromptAddition` to the system
prompt when `deepResearch: true`. New `ChatController.newDeepResearchConversation(entry)` mirrors
`newAgentConversation`, setting `isDeepResearch: true` and the active entry at creation. New
`startNewDeepResearchChat` helper in `agent_mode_flow.dart` picks the recommended tool-capable
cookbook entry (issue 020) for the new conversation. `ChatModeToggle` now renders a third
"Research" segment.

Fixed the step-card gating in `_MessageList` (home_chat_section.dart): it now shows
`AgentStepList` when `workingProjectId != null` OR `conversation.isDeepResearch`, so
`web_search`/`fetch_page` tool calls render as step cards in Deep Research conversations (which
have no `workingProjectId`).

Tests: `chat_conversation_test.dart` covers `isDeepResearch` round-trip, default, and copyWith
immutability. New `ChatController Deep Research mode` group covers `kDeepResearchTools` being
passed to `streamChat`, the system-prompt addition, a multi-round-trip `web_search`/`fetch_page`
turn producing a cited final answer, the `kMaxDeepResearchSteps` partial-answer notice, and
`newDeepResearchConversation`. `chat_mode_toggle_test.dart` covers starting a Deep Research
conversation from the "Research" segment and that segment being a no-op once active.
`flutter test` → 377 passed. `flutter analyze` clean except the 2 pre-existing
`deprecated_member_use` infos.

QA rejected on 2026-06-14. Bug appended — agent tool calling doesn't work, Deep Research returns
an empty message.

Bug fixed on 2026-06-14. Resolved by issue 010's datasource fix to AgentLoopRunner's
second-round-trip message serialization (`_toOllamaMessage`/`_toOpenAiMessage` now echo
`tool_calls`). Re-verified Deep Research's multi-round-trip loop and all original acceptance
criteria — `AgentLoopRunner._continueIfReady`'s recursive Deep Research branch
(`isDeepResearch`/`kMaxDeepResearchSteps`/partial-answer notice) was already correct at the domain
level; the existing fake-repository test only asserted the final message's content, not the
intermediate per-round-trip history. Strengthened the "dispatches web_search and fetch_page across
several round-trips" test to assert the full 6-message sequence (user, assistant with
`toolCalls: [web_search]`, tool result, assistant with `toolCalls: [fetch_page]`, tool result,
final cited assistant text) and `toolsPerCall` having 3 entries all equal to `kDeepResearchTools`
— confirming each round's history correctly carries forward prior assistant `toolCalls` plus tool
results, which is exactly what the fixed datasources now serialize correctly for round 2 and 3.
`flutter test` → 379 passed. `flutter analyze` clean except the 2 pre-existing
`deprecated_member_use` infos.

## Bug

**Reported:** 2026-06-14
**Found during:** Visual QA
**Description:** Starting a Deep Research conversation and asking a research question produces an
empty assistant message — no `web_search`/`fetch_page` step cards, no final cited answer (same
underlying tool-calling issue as 010/015/016).

### What to fix
_To be investigated during implementation._

### Acceptance Criteria
- [ ] Bug no longer reproduces
- [ ] Original acceptance criteria still met
- [ ] A test exists that would have caught this

QA rejected again on 2026-06-14 (real-world visual QA, after the "Bug fixed on 2026-06-14" note
above). Agent mode itself remains unusable in real-world testing (tool calls/step cards still
don't reliably trigger, and when they do the UI is broken — see issue 010's latest rejection), so
Deep Research still couldn't be exercised end-to-end. Agent and Research modes have been disabled
(Home chat is chat-only for now) via the `kAgentModeEnabled = false` switch in
`agent_loop_constants.dart`, and this feature area — including Deep Research — will be redesigned
under a new PRD. See `docs/handoffs/handoff-agent-mode-redesign.md`.

Moved to Done on 2026-06-15 — closing out this PRD cycle (not QA-approved; superseded by a new
PRD, see docs/handoffs/handoff-agent-mode-redesign.md).
