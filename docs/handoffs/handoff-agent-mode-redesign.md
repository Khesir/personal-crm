# Handoff: Agent Mode / Deep Research — disabled pending redesign

**Date:** 2026-06-14
**For:** whoever picks up the next PRD for Home chat's Agent mode, Deep Research, and shell access.

---

## TL;DR

Issues 001-022 across three PRDs (`prd-home-chat-agent-mode.md`,
`prd-agent-capabilities-expansion.md`, `prd-agent-shell-access.md`) built out Home chat's Agent
mode: tool calling (file read/write/edit, grep, web search, fetch_page, run_command), step-card UI,
approve/reject flows, reference-project confirmations, a Deep Research mode, and cookbook
hardware-fit badges. All automated checks pass (379 tests, clean `flutter analyze`, clean code
review — see `issues/qa-report.md`).

**Real-world visual testing found it doesn't work as a usable feature.** Tool calls/step cards
don't reliably trigger, the step-card UI is broken when it does render, in some cases there isn't
even a way to get a normal chat reply, and the Chat/Agent/Research toggle doesn't read as a
distinct mode — it looks and behaves like plain chat.

**Decision:** rather than another fix-and-reverify loop on the existing issues, Agent and Research
modes are now **disabled** (Home chat is chat-only) via one flag, and this area will be
**redesigned under a new PRD**. The old implementation and its tests are left in place — don't
delete them yet, they may be salvageable building blocks.

---

## What's disabled, and how to re-enable / remove

A single switch: `kAgentModeEnabled = false` in
[`lib/features/home/domain/model/agent_loop_constants.dart`](../lib/features/home/domain/model/agent_loop_constants.dart).

While `false`:
- `ChatModeToggle` (Chat/Agent/Research segments) is not rendered in
  [`home_chat_section.dart`](../lib/features/home/presentation/section/home_chat_section.dart)'s header.
- Step cards (`AgentStepList`) are never rendered — `showStepCards` is forced `false` regardless of
  a conversation's `workingProjectId`/`isDeepResearch`.
- "Branch into agent mode" is hidden from the conversation menu in
  [`home_sidebar_section.dart`](../lib/features/home/presentation/section/home_sidebar_section.dart).
- The "New chat" flow (`startNewChat` in
  [`agent_mode_flow.dart`](../lib/features/home/presentation/helpers/agent_mode_flow.dart)) skips
  the Agent-mode dialog entirely and always starts a plain conversation.

Everything else — `AgentLoopRunner`, `AgentToolRepository`, `WebSearchRepository`,
`CommandExecutionRepository`, `FetchPageRepository`, the tool-call datasource parsing/serialization,
the step-card widgets, and all their tests — is untouched and still passes. Flipping
`kAgentModeEnabled` back to `true` restores the previous behavior exactly (it's the only switch).

If the redesign ends up replacing this machinery rather than reusing it, search for
`kAgentModeEnabled` to find every gated call site before deleting.

---

## Real-world QA findings (verbatim, 2026-06-14)

From the user, after manually testing the build:

- "Tool calls/step cards still don't trigger"
- "Step cards/UI render but are broken"
- "Not even a way to reply normally"
- "it still in chat mode etc.. the ui is generating similar to chat and not like agent mode type
  of things"

This is a stronger signal than the prior QA-rejection cycle (which was traced to one datasource
serialization bug, fixed and re-verified at the unit/integration level — see issue 010's Log). The
gap between "379/379 tests pass, clean analyze, clean code review" and "doesn't work in practice"
suggests the test coverage doesn't reach the failure modes that matter. Candidate causes, **not yet
investigated**:

1. **Model capability mismatch.** Issue 014 added a live capability probe specifically because some
   Ollama models claim `tools` support in `/api/show` but don't reliably emit `message.tool_calls`
   for real prompts. The only model installed before this session was `llama3.2:1b` (1.3GB) — quite
   small for reliable tool-calling. `qwen3:4b` (2.5GB, tool-capable, "GOOD" hardware fit) was
   installed this session but not yet tried in-app by anyone.
2. **UI-layer bugs not covered by tests.** Issue 010 explicitly shipped with no widget tests for the
   step-card UI ("covered via `/qa`'s visual checklist" — see its Notes section), so layout/state
   bugs in `AgentStepList`/`ToolCallStepCard`/`ReferenceConfirmationCard` would not be caught.
3. **UX framing.** Even when working, a small segmented toggle in the header may not be enough for
   "agent mode" to feel like a distinct mode from chat — this may need a different surface
   entirely (separate view, distinct visual treatment, etc.), not just a bugfix.
4. **"Not even a way to reply normally"** is the most concerning report and is unexplained — it
   suggests something can get a conversation (agent-mode or not) into a state with no usable
   reply path. Worth reproducing first, since if this also affects plain chat it's a regression
   beyond just "agent mode."

---

## Context for the new PRD

- **Domain language**: see `CONTEXT.md` — Brain, Home chat, Agent mode, Working project, Reference
  project are all defined there and should be reused/extended rather than re-coined.
- **Prior PRDs** (for what was attempted and why, don't re-litigate from scratch):
  - `issues/prd-home-chat-agent-mode.md` — original agent-mode PRD (issues 004-013: domain model,
    streamChat contract, file tools, tool-call parsing per provider, agent loop, step-card UI,
    mode toggle).
  - `issues/prd-agent-capabilities-expansion.md` — web search, fetch_page, cookbook fit badges,
    Deep Research (issues 014/015/018/020/021/022).
  - `issues/prd-agent-shell-access.md` — `run_command` + shell-access toggle (issues 016/017).
- **Done work** (`issues/done/`) — issues 001-009, 011-014, 017-021 are QA-approved and not part of
  this redo; brain/memory (001-003), domain model/contracts/parsing per-provider (004-008,
  011-012), mode toggle (013), capability probe (014), shell toggle (017), cookbook fit (018-020),
  fetch_page (021) all stand on their own merits. The redo is scoped to **how Agent mode surfaces
  and behaves** (010, 015, 016, 022's UI/integration), not necessarily these foundations.
- **Hardware constraints** (detected this session, relevant to "what's realistically testable
  locally"):
  - GPU: NVIDIA GeForce MX550, 2048 MB VRAM, CUDA available.
  - RAM: ~7.86 GB total.
  - Installed Ollama models: `llama3.2:1b` (1.3GB) and `qwen3:4b` (2.5GB, tool-capable, "GOOD" fit
    per issue 018/020's fit scorer — recommended as the first model to manually test agent mode
    against once redesigned).

---

## Suggested skills for the next session

- `/new-feature` — archive this cycle's `issues/` (including this handoff doc, the PRDs above, and
  `issues/done/`) into `issues/archive/`, and create a fresh empty structure for the new PRD.
- `/to-prd` (after `/new-feature`) — draft the new PRD. Worth scoping small: get ONE tool (e.g.
  `read_file`) working end-to-end with manual verification against `qwen3:4b` *before* rebuilding
  the full tool set, step-card UI, and Deep Research mode.
- `/grill-with-docs` or `/grill-me` — stress-test the new PRD's approach, per `/new-feature`'s own
  recommendation.
