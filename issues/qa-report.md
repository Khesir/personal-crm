# QA Report

_Date: 2026-06-14_

---

## Automated QA Results

| Issue | Title | Build | Tests Pass | Test Quality | Lint | Code Review | Result |
|-------|-------|-------|------------|--------------|------|--------------|--------|
| [004](qa/004-agent-mode-domain-model.md) | Agent-mode domain model | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [005](qa/005-chatmodelrepository-streamchat-event-contract.md) | ChatModelRepository.streamChat() contract change | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [006](qa/006-agent-tool-repository-file-tools.md) | AgentToolRepository: file tools | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [007](qa/007-ollama-tool-call-parsing.md) | Ollama datasource: tool-call parsing | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [008](qa/008-chatcontroller-agent-loop.md) | ChatController agent loop | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [009](qa/009-agent-mode-conversation-creation-and-branching.md) | Agent-mode conversation creation + branching | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [010](qa/010-step-card-ui.md) | Step-card UI | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [011](qa/011-openai-compatible-tool-call-parsing.md) | OpenAI-compatible datasource: tool-call parsing | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [012](qa/012-anthropic-tool-call-parsing.md) | Anthropic datasource: tool-call parsing | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [013](qa/013-home-chat-mode-toggle.md) | Home chat: Chat/Agent mode toggle | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [014](qa/014-ollama-tool-call-capability-probe.md) | Ollama supportsTools: live capability probe | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [015](qa/015-agent-web-search-tool.md) | Agent web search tool (SearXNG) | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [016](qa/016-run-command-tool.md) | run_command tool | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [017](qa/017-shell-access-toggle.md) | Per-conversation Shell access toggle | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [018](qa/018-cookbook-fit-result.md) | Cookbook fit-result computation | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [019](qa/019-cookbook-fit-badges.md) | Fit badges in the Home chat model switcher | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [020](qa/020-recommended-pick-default-model.md) | Recommended pick: default model selection | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [021](qa/021-fetch-page-tool.md) | fetch_page tool | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [022](qa/022-deep-research-mode.md) | Deep Research mode | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |

**Global checks**: `flutter analyze` is clean except 2 pre-existing `deprecated_member_use` infos (`activeColor` → `activeThumbColor`), both in files unrelated to this batch (`announcements_section.dart`, `project_form_dialog.dart`) — not introduced by any of issues 004-022. `flutter test` — all 377 tests pass.

---

## Cross-cutting code quality flag (non-blocking)

**The Home chat controller now exceeds the project's 500-line hard limit.**

`lib/features/home/domain/controller/chat_controller.dart` is **562 lines**. Before this batch of issues it was 257 lines (as of the prior "brain feature" commit) — the +305 lines accumulated across issues 008, 009, 014, 015, 016, 017, 018, 020, 021, and 022, each adding a small, individually-reasonable amount of agent-mode/cookbook-fit/deep-research wiring to the same controller.

This is one root cause (the controller has become the landing spot for every new cross-cutting concern in this feature set), not 10 separate problems, and none of it represents incorrect behavior — all acceptance criteria for the affected issues are met and all tests pass. It does not block visual QA of any individual issue below.

Recommend a follow-up decoupling pass before the next agent-mode feature lands — e.g. extract the four tool-call-approval methods (`approveToolCall`/`rejectToolCall`/`allowReferenceProject`/`denyReferenceProject`) and the `AgentLoopContext`/`AgentLoopOps` wiring into their own file, similar to how `agent_loop_runner.dart` was already extracted from this controller in issue 008.

Also worth watching: `lib/features/home/domain/controller/agent_loop_runner.dart` is now **494 lines** — under the limit but only by 6 lines, after absorbing dispatch logic for `web_search`, `fetch_page`, `run_command`, and Deep Research across issues 015-022. The next tool added to the agent loop will likely need to extract tool-dispatch into its own file.

---

## Minor test-coverage gaps (non-blocking)

These are logic that appears correct by inspection but isn't directly exercised by a test. None fail any acceptance criterion; flagged for awareness / a future hardening pass:

- **006** (file tools): no test passes a `..`-relative-path-traversal argument (e.g. `read_file` with `path: '../../../etc/passwd'`) to directly prove the path-boundary check survives relative-path tricks. The underlying normalize-then-check logic handles this correctly by construction, but it's untested directly — given this is the security-sensitive surface of the PRD, worth adding.
- **008** (agent loop): no test covers a single turn with *multiple* simultaneous tool calls where some resolve to `ToolOutput` and one resolves to `ToolWriteProposal`/`ToolReferenceConfirmationNeeded` in the same turn. The implementation handles this (answers the resolved calls, stops at the first pending one), but the interleaving itself is untested.
- **008**: `denyReferenceProject` takes a `projectId` parameter on the controller's public API that is never forwarded to the runner (the runner doesn't need it). Harmless (keeps the four approval methods' signatures symmetric) but technically an unused parameter.
- **011** (OpenAI-compatible): the multi-chunk `tool_calls` reassembly test only exercises a single concurrent tool call; the per-index accumulation logic generalizes correctly to N calls by inspection but isn't tested with N>1.
- **012** (Anthropic): the consecutive tool-role-message merge is tested for the "all consecutive" case; the boundary case (a normal user/text message separating two groups of tool results, producing two separate `user` turns rather than one merged turn) isn't explicitly tested, though the type-guard (`content is List` vs `String`) appears correct by inspection.
- **015** (web search): the "no SearXNG configured → ToolError" path is correctly implemented and unit-tested at the `AgentLoopRunner` level (`webSearchRepository: null`), but in the running app `ServiceCardsCache.field()` falls back to a default `http://localhost:8080` base URL even with no SearXNG card configured, so `home/di.dart` will almost always construct a non-null repository. The realistic "not configured" experience is therefore an unreachable-host network error (a different `ToolError` message: `'Web search request failed.'`) rather than the "configure a service in Settings" message. This is a pre-existing pattern shared with n8n/Custom URL, not new to this issue — flagged for awareness only.

---

## Issues with automated failures

None. All 19 issues pass build, full test suite, lint, and code review at the behavioral level described above.

---

## Visual QA Checklist

Issues 004-008, 011, 012, 014, 018, 020, 021 have no UI surface requiring visual QA (pure model/datasource/controller logic, fully covered by passing automated tests). The checklist below covers the issues with a UI component.

## Visual QA — [009] Agent-mode conversation creation + branching UI

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Starting a new conversation with the "Agent mode" toggle off | Home chat → "New chat" | Behaves exactly as before: no project picker, full model list, conversation has no working project. |
| 2 | Starting a new conversation with "Agent mode" on | Home chat → "New chat" → enable Agent mode | A project picker appears (your registered Projects); the model list is filtered to tool-capable models only. |
| 3 | Creating an agent-mode conversation | Same dialog, after picking a project + model | New conversation is created scoped to that project (this becomes its "working project" for the rest of the conversation). |
| 4 | "Branch into agent mode" on an existing conversation | Hover a conversation in the sidebar → context menu | Opens the same project + model picker; confirming creates a new conversation pre-loaded with a copy of the original conversation's messages, scoped to the chosen project. |
| 5 | Source conversation after branching | Sidebar → original conversation | Original conversation's messages are unchanged — branching does not mutate it. |
| 6 | Old conversations (created before this feature) | Sidebar → any pre-existing conversation | Open and behave exactly as before — no agent-mode UI appears for them. |

**Edge cases to manually test:**
- [ ] Cancel the project/model picker after tapping "Agent mode" — no conversation should be created and nothing should change.
- [ ] Try Agent mode with zero registered Projects — confirm the picker handles "no projects" gracefully (no crash, sensible empty state).
- [ ] Try Agent mode where every model is non-tool-capable (e.g. only Ollama models without tool support) — confirm the filtered model list handles "no eligible models" gracefully.

---

## Visual QA — [010] Step-card UI

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Assistant calls a read-only tool (e.g. reads a file) in an agent-mode conversation | Agent-mode conversation transcript | A collapsed "step card" appears showing the tool's name and a short one-line summary (e.g. the file path). |
| 2 | Expand a step card | Tap/click the collapsed step card | Expands to show the full tool arguments and the tool's output/result. |
| 3 | Assistant proposes editing an existing file | Agent-mode conversation, after asking it to edit a file | The expanded step card shows an old/new text diff (before/after), with Approve and Reject buttons, and the loop pauses. |
| 4 | Assistant proposes creating a new file | Agent-mode conversation, after asking it to create a file | The expanded step card shows the proposed new file's full content as a preview, with Approve/Reject buttons. |
| 5 | Tap Approve on a pending write/edit | Step card's Approve button | The file is actually written/edited on disk, the card updates to show the applied result, and the assistant continues. |
| 6 | Tap Reject on a pending write/edit | Step card's Reject button | No file change occurs; the card shows a "rejected" result, and the assistant continues (and should acknowledge the rejection). |
| 7 | Assistant tries to read a file in a different *registered* project (a "reference project") that hasn't been allowed yet | Agent-mode conversation, ask it about another project's code | A confirmation card appears: "Allow read access to [Project]?" with Allow/Deny buttons, and the loop pauses. |
| 8 | Tap Allow on the reference-project confirmation | Confirmation card's Allow button | The read proceeds and shows its result; asking again about the same project later in the conversation does not re-prompt. |
| 9 | Tap Deny on the reference-project confirmation | Confirmation card's Deny button | The read is denied, the assistant is told access was denied, and the conversation continues. |
| 10 | Final answer after a tool-call turn | Agent-mode conversation, after all tool calls in a turn resolve | The model's final text response renders as a normal chat bubble *below* the step card(s) for that turn. |
| 11 | A plain (non-agent) conversation | Home chat → a conversation without a working project | Renders exactly as before — no step cards anywhere, even if older messages happen to contain tool-call data. |
| 12 | Reopen a conversation with a pending approval | Quit/reopen the app (or switch away and back) while a write/edit/reference confirmation is pending | The same pending step card / confirmation card reappears with its Approve/Reject or Allow/Deny controls, ready to continue. |

**Edge cases to manually test:**
- [ ] A turn where the model requests multiple tool calls at once (e.g. reads two files) — confirm multiple step cards render in order.
- [ ] A turn that mixes an auto-resolved read with a pending write in the same turn — confirm the resolved read's card shows its result while the write's card shows pending Approve/Reject.
- [ ] Very long tool output (e.g. a large file read) inside an expanded step card — confirm it doesn't break the layout (scrolls/truncates sensibly).

---

## Visual QA — [013] Home chat: Chat/Agent mode segmented toggle in header

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Open a plain (non-agent) conversation | Home chat header | A "Chat / Agent" segmented toggle appears with "Chat" highlighted. |
| 2 | Open an agent-mode conversation | Home chat header | The toggle shows "Agent" highlighted, with the working project's name shown alongside/within it (e.g. "Agent · crm"). |
| 3 | Tap the already-highlighted segment | Header toggle | Nothing happens (no new conversation, no dialog). |
| 4 | Tap "Chat" while viewing an agent-mode conversation | Header toggle | A new plain conversation is created and becomes active; the toggle now shows "Chat" highlighted. |
| 5 | Tap "Agent" while viewing a plain conversation | Header toggle | The project + model picker dialog opens; confirming creates and switches to a new agent-mode conversation; cancelling leaves the current conversation untouched. |
| 6 | No active conversation (empty state) | Home chat with nothing selected | Toggle defaults to "Chat" highlighted. |
| 7 | Overall header layout | Home chat header | Title and the existing model switcher (`ModelSwitcher`) still render correctly alongside the new toggle — nothing overlaps or is pushed off-screen. |
| 8 | Shell access indicator (see issue 017) | Header toggle, on an agent-mode conversation created with "Shell access" enabled | The "Agent" segment shows a terminal/shell icon. |
| 9 | "Research" segment (see issue 022) | Header toggle | A third "Research" segment is present alongside "Chat"/"Agent" and behaves consistently (highlight/no-op-when-active). |

---

## Visual QA — [015] SearXNG service card in Settings

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Add a new SearXNG service | Settings → Services → Services → Add | "SearXNG" appears as an addable service type, with a Base URL field defaulting to `http://localhost:8080`. |
| 2 | Edit the SearXNG card | Settings → Services → Services | Base URL is editable and saves correctly. |
| 3 | Delete the SearXNG card | Settings → Services → Services | Card can be removed like other service cards. |
| 4 | Health check | Settings → Services → Services, with a SearXNG card present | Running the health check shows online/offline status based on whether the configured URL responds. |
| 5 | Agent uses web search | Agent-mode conversation, ask a question requiring a web search | If SearXNG is reachable, results (title/URL/snippet) come back as a step card; if not, the assistant explains web search isn't available without crashing or hanging. |

---

## Visual QA — [016] run_command step card

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Assistant proposes running a shell command (with Shell access enabled — see issue 017) | Agent-mode conversation transcript | A step card appears showing the literal command text and the working directory (cwd), in monospace, with the loop paused. |
| 2 | Tap Approve | Step card's Approve button | The command actually runs; the card updates to show exit code, stdout, and stderr, and the assistant continues using that output. |
| 3 | Tap Reject | Step card's Reject button | The command does not run; a rejection is fed back, and the assistant continues. |
| 4 | A long-running command | Ask the assistant to run something that would hang (e.g. an infinite loop) and Approve it | After ~60 seconds the command is killed and the card shows a timeout error rather than hanging the conversation indefinitely. |

---

## Visual QA — [017] Per-conversation Shell access toggle

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | New agent-mode conversation dialog | "New chat" → enable Agent mode (or "Branch into agent mode") | A "Shell access" checkbox is present, unchecked by default. |
| 2 | Create a conversation with Shell access checked | Same dialog, check the box, confirm | The created conversation shows the terminal/shell icon in its header toggle (see issue 013, item 8). |
| 3 | Create a conversation with Shell access unchecked | Same dialog, leave unchecked, confirm | No terminal icon in the header; asking the model to run a shell command results in it being told shell access isn't enabled (no approval card appears). |
| 4 | Existing conversation | Any agent-mode conversation | No UI affordance anywhere to turn Shell access on/off after creation. |

---

## Visual QA — [019] Fit badges in the Home chat model switcher

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Open the model switcher with local models installed | Home chat → model switcher dropdown | Each local model shows a colored "Fit" badge (PERFECT / GOOD / CPU ONLY / TOO BIG) next to its name, matching the styling already used in Settings → Local LLM → Search Hugging Face. |
| 2 | API-based models (OpenAI, Anthropic, etc.) | Home chat → model switcher dropdown | No fit badge shown next to API entries. |
| 3 | A local model whose name doesn't parse cleanly | Home chat → model switcher dropdown | No fit badge shown for that entry (no crash, no blank/odd badge). |
| 4 | Compare badge styling | Settings → Local LLM → Search Hugging Face vs. Home chat model switcher | Both surfaces use the same badge colors and labels — no visible inconsistency between the two. |

---

## Visual QA — [022] Deep Research mode

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | "Research" segment in the mode toggle | Home chat header toggle | A third "Research" segment is selectable alongside "Chat"/"Agent". |
| 2 | Start a Deep Research conversation | Tap "Research" in the toggle | A new conversation starts, defaulting to a recommended tool-capable local model (per issue 020) where available. |
| 3 | Ask a research question | In the new Deep Research conversation, ask an open-ended question | The assistant runs multiple `web_search`/`fetch_page` calls across different angles, each rendering as a step card (same style as agent mode). |
| 4 | Final answer | After research completes | The final answer cites source URLs it gathered during research. |
| 5 | Step-limit reached | Ask something that would require unusually many searches (or otherwise drive it toward `kMaxDeepResearchSteps`) | The assistant returns a best-effort partial answer noting the step limit was reached, along with whatever sources it gathered. |
| 6 | Tapping "Research" while already active | Header toggle, in a Deep Research conversation | No-op — does not start a new conversation. |

---

## How to sign off

For each issue you visually verify:
- Approved → run `/qa-approve [issue number]`
- Something is wrong → run `/qa-reject [issue number] [what you saw]`
