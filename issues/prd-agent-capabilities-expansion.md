# PRD: Agent Capabilities Expansion (Cookbook hardware-fit recommendations + Deep Research)

**Status:** Draft
**Date:** 2026-06-14

---

## Problem Statement

Issue 015 gave Home chat's agent mode a `web_search` tool, the first step toward making Avyn (the Home chat
assistant) behave less like a code-only agent (Claude Code) and more like a general-purpose assistant in the
style of self-hosted AI workspaces (e.g. the user's `odysseus` project): able to search the web, recommend
the right local model for the user's hardware, and do multi-step research instead of a single search.

Two gaps remain:

1. **Cookbook is hardware-blind.** The Home chat Cookbook (`CookbookEntry` list backing the model switcher)
   lists every enabled model from every Local LLM/API LLM service card, but gives no indication of which
   *local* models will actually run well on the user's machine. Settings → Local LLM → "Search Hugging Face"
   already computes this via `FitScorer`/`ModelFitResult`/`HardwareInfo` (perfect/good/cpuOnly/tooBig,
   estimated tokens/sec, 0-100 score) when *discovering new models to download* — but that scoring is never
   surfaced for models the user has *already* added to the Cookbook.
2. **No multi-step research.** `web_search` (issue 015) returns one page of results for one query. There's
   no way for the assistant to plan several searches, follow up on what it finds, and synthesize a single
   answer — the "Deep Research" pattern from `odysseus` (`services/research/`, `src/deep_research.py`).

---

## Solution

### 1. Cookbook hardware-fit recommendations

Reuse the existing `FitScorer`/`ModelFitResult`/`HardwareInfo` machinery (already shipped for Hugging Face
model discovery) to score every **Local LLM** `CookbookEntry` against the user's detected hardware, and
surface that score in the Home chat model switcher:

- Each local `CookbookEntry` gets an attached `ModelFitResult` (`fit`, `mode`, `speedTokensPerSec`, `score`),
  computed from the model's parameter count + quantization (parsed from the model name/tag, same as the HF
  discovery flow) and the cached `HardwareInfo`.
- The model switcher (`ModelSwitcher`/cookbook list) shows a small Fit badge (Perfect/Good/CPU-only/Too big)
  next to each local model, using the same color scheme as the HF search dialog's fit badges.
- API LLM entries (cloud-hosted — Claude, OpenAI, Groq, etc.) are unaffected: hardware fit is meaningless for
  them, so they show no badge.
- **Recommended pick**: when starting a *new* conversation (or new agent-mode conversation) without an
  explicit model choice, default the selection to the local entry with the highest `score` among models that
  `supportsTools` (for agent mode) — falling back to the existing default-card behavior if no local entries
  exist or hardware info isn't available.

### 2. Deep Research

Add a **Deep Research** mode alongside the existing Chat/Agent mode toggle (issue 013). A Deep Research
conversation, given a topic/question:

1. Plans a small fixed number of `web_search` queries covering different angles of the topic (the model
   itself proposes the queries via the normal tool-call loop — no separate planning model).
2. Runs each search via the same `web_search` tool/`WebSearchRepository` from issue 015, optionally followed
   by an additional read of a promising result page (new `fetch_page` tool — `GET` a URL, strip to readable
   text, mirroring `odysseus`'s page-fetch step).
3. Synthesizes a single final report citing the sources it used (URLs from the `web_search`/`fetch_page`
   results it was fed).

Mechanically, Deep Research is **not a new agent loop** — it's the existing `AgentLoopRunner` loop
(issue 008) with `web_search` + `fetch_page` as the tool set, a higher `kMaxAgentLoopSteps`-equivalent ceiling
(since research needs more round-trips than file edits), and a system-prompt addition instructing the model
to research thoroughly and cite sources before answering. The step-card UI (issue 010) already renders
arbitrary tool calls, so `web_search`/`fetch_page` steps render for free.

---

## User Stories

### Cookbook hardware-fit

1. As a user, I want each local model in the Home chat model switcher to show a fit badge (Perfect/Good/
   CPU-only/Too big) for my current machine, so I can tell at a glance which models will actually run well.
2. As a user, I want cloud/API models in the switcher to show no fit badge, so I'm not confused by
   irrelevant hardware info for models that don't run on my machine.
3. As a user starting a new conversation without picking a model, I want the assistant to default to the
   local model that best fits my hardware (among tool-capable models, for agent mode), so I don't have to
   manually figure out which local model to use every time.
4. As a developer, I want the fit-scoring logic reused from `FitScorer`/`ModelFitResult`/`HardwareInfo`
   (Settings → Hugging Face search) rather than duplicated, so the two surfaces never disagree.

### Deep Research

5. As a user, I want a "Deep Research" mode I can pick when starting a conversation (alongside Chat/Agent),
   so I can ask an open-ended question and get a researched, multi-source answer instead of a single search.
6. As a user, I want Deep Research to run several searches on different angles of my question automatically,
   so I get broader coverage than one search would give.
7. As a user, I want Deep Research to be able to open a specific page from search results (`fetch_page`) when
   a snippet isn't enough, so it can pull in more detail than a search snippet provides.
8. As a user, I want Deep Research's final answer to cite the URLs it used, so I can verify its sources.
9. As a user, I want each search/fetch step to appear as a step card (like agent-mode file tools), so I can
   see what the assistant looked at while researching.
10. As a user, if Deep Research can't reach a conclusion within its step limit, I want it to say so and give
    me its best-effort partial answer (with whatever sources it did gather), so I'm not left with nothing.
11. As a developer, I want Deep Research to reuse `AgentLoopRunner`/`web_search`/the step-card UI rather than
    a parallel implementation, so the two tool-calling surfaces (Agent mode, Deep Research) stay consistent.

---

## Implementation Decisions

### Cookbook hardware-fit (`lib/features/home/`, `lib/features/settings/domain/model/`)

- `CookbookEntry` gains an optional `ModelFitResult? fitResult` (null for API LLM entries, and for local
  entries when `HardwareInfo`/param-count parsing is unavailable).
- Parameter-count + quantization parsing from a model name/tag: reuse whatever parsing the Hugging Face
  search flow already does (`model_discovery_controller.dart`/`model_discovery_result.dart`) — do not write a
  second parser. If a model's name doesn't parse cleanly, leave `fitResult` null (no badge) rather than
  guessing.
- `HardwareInfo` is read from wherever the HF search dialog currently sources it (cached detection result) —
  Deep Research/Cookbook must not re-run hardware detection on every `refresh()`.
- Fit badge widget: extract the existing fit-badge rendering from the HF search dialog into a shared
  `presentation/widget/` component (in whichever feature currently owns it) so both surfaces use identical
  colors/labels — do not duplicate the switch-on-`Fit` styling.
- "Recommended pick" default-selection logic lives in `ChatController`/`createChatController` (`home/di.dart`),
  alongside the existing default-card selection — extend, don't replace, the current "no model selected yet"
  fallback.

### Deep Research (`lib/features/home/`)

- New `ChatMode` (or equivalent) value alongside Chat/Agent from issue 013's mode toggle — naming and exact
  enum/UI placement to be confirmed against issue 013's implementation before breakdown.
- New `kFetchPageTool` `ToolDefinition` (`fetch_page`, one required `url` argument) added to a
  Deep-Research-specific tool set — **not** appended to `kAgentTools` (agent mode's file-tool set stays
  fixed per issue 015's notes); Deep Research conversations pass `[kWebSearchTool, kFetchPageTool]` to
  `streamChat()` instead.
- `fetch_page`: `GET {url}`, strip HTML to readable text (need to confirm: reuse a markdown/HTML-to-text
  conversion if one already exists in the Flutter dependency set — **no new packages** without approval, per
  CLAUDE.md; if nothing suitable exists, this becomes a blocker/HITL slice to pick an approach).
- Step limit: Deep Research needs its own ceiling distinct from `kMaxAgentLoopSteps` (file-editing turns are
  usually done in 1-3 round-trips; research needs more). New named constant, not a hardcoded number.
- System prompt addition for Deep Research conversations: instructs the model to (a) run multiple searches
  covering different angles before answering, (b) cite source URLs in its final answer. Exact wording is an
  implementation detail for the breakdown phase.

---

## Testing Decisions

- Cookbook fit: unit tests for the param/quant parsing → `FitScorer.score` → `ModelFitResult` pipeline applied
  to `CookbookEntry` (reuse existing `FitScorer`/parsing test fixtures where possible); widget test for the
  shared fit-badge component rendering each `Fit` value; `ChatController`/`home/di.dart` test for "recommended
  pick" default selection (local, tool-capable, highest score wins; falls back correctly when no local
  entries or no hardware info).
- Deep Research: `AgentLoopRunner`/`ChatController` agent-loop tests (same fake-repository pattern as issue
  015) for a Deep Research turn dispatching `web_search`/`fetch_page` calls, looping across several
  round-trips, and stopping at its step limit with a partial-answer notice. `fetch_page` datasource test
  (HTML → text extraction) once the conversion approach is decided.

---

## Out of Scope

- Brave/DuckDuckGo/Google PSE/Tavily/Serper search providers (SearXNG only, per issue 015).
- Discord integration, tasks/reminders, calendar, email, notes — mentioned in the original scope-pivot
  request but not prioritized; not covered by this PRD. May warrant a future PRD.
- Re-running hardware detection on a schedule (e.g. on every Cookbook refresh) — fit scores use the existing
  cached `HardwareInfo` snapshot.
- A standalone "Cookbook" screen/section separate from the existing Home chat model switcher — this PRD only
  adds fit information to what already exists.
- Streaming/partial Deep Research results mid-research (the user sees step cards live, same as agent mode,
  but the "report" itself is the final message, not progressively rewritten).

---

## Further Notes

- Mirrors `odysseus`'s Cookbook (hwfit/llmfit-style hardware-aware recommendations) and Deep Research
  (`services/research/`, `src/deep_research.py`) features, scoped to what's reusable from this app's existing
  `FitScorer`/agent-loop infrastructure rather than ported wholesale.
- The `fetch_page` HTML-to-text approach is the main open question for the breakdown phase — flag as HITL if
  no existing dependency covers it cleanly.
- Issue 013 (Chat/Agent mode toggle) should be re-read before breakdown to confirm where/how a third
  "Deep Research" mode slots into the existing UI and `ChatConversation` model.
