# QA Report

_Date: 2026-06-14_

---

## Context

This report covers the 4 issues remaining in `issues/qa/` (010, 015, 016, 022). All four were
previously **QA-rejected** for the same underlying bug: in an agent-mode/Deep Research
conversation, the second `streamChat()` round-trip sent the assistant's tool-call message as
`{role: "assistant", content: ""}` with no `tool_calls`, so Ollama/OpenAI-compatible models
returned an empty response — no step cards, no final answer, nothing to visually verify.

That bug was fixed (issue 010's `_toOllamaMessage`/`_toOpenAiMessage` now echo `toolCalls`) and
each of the 4 issues was re-verified at the domain/test level. This automated QA pass re-confirms
build/tests/lint/code-review now that the fix is in, and the Visual QA checklists below are now
unblocked and ready for human review.

---

## Automated QA Results

| Issue | Title | Build | Tests Pass | Test Quality | Lint | Code Review | Result |
|-------|-------|-------|------------|--------------|------|--------------|--------|
| [010](qa/010-step-card-ui.md) | Step-card UI | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [015](qa/015-agent-web-search-tool.md) | Agent web search tool (SearXNG) | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [016](qa/016-run-command-tool.md) | run_command tool | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [022](qa/022-deep-research-mode.md) | Deep Research mode | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |

**Global checks**: `flutter test` — all 379 tests pass. `flutter analyze` is clean except the 2
pre-existing `deprecated_member_use` infos (`activeColor` → `activeThumbColor`) in
`announcements_section.dart`/`project_form_dialog.dart`, unrelated to this batch.

**Bugfix verification**: `_toOllamaMessage`/`_toOpenAiMessage` now serialize an `assistant`
message's `toolCalls` as a `tool_calls` array on the second `streamChat()` call (Ollama: object
arguments; OpenAI-compatible: JSON-encoded string arguments), matching `AnthropicDatasource`'s
existing behavior. Regression tests assert the outgoing request body for both datasources
("echoes an assistant message's tool_calls ... ahead of the tool result"). The `run_command`
preview path (`previewPendingToolCall` → `_executeRunCommand`) was confirmed side-effect-free —
it returns a `ToolWriteProposal(CommandExecution(...))` derived purely from the call's arguments
and never invokes `CommandExecutionRepository`; only `approveToolCall` actually runs the command.

---

## Acceptance criteria

| Issue | Criterion | Status |
|-------|-----------|--------|
| 010 | All 8 criteria (step card rendering, expand/collapse, diffs, approve/reject, reference-project confirmation, final answer placement, non-agent regression, reopen-with-pending) | 👁 needs visual check (no automated widget tests, per issue's testing decision) |
| 015 | `kWebSearchTool` in `kAgentTools`; result formatting/capping; empty-results message; request-failure `ToolError`; dispatch to `WebSearchRepository`; "not configured" `ToolError`; `toolCallSummary` query | ✅ verified by code/tests |
| 015 | New `ServiceType.searxng` card addable/editable/deletable with health check | 👁 needs visual check (explicitly marked 👁 in issue) |
| 016 | `kRunCommandTool`; `CommandExecutionRepository` via `ProcessRunner`; pending `ToolWriteProposal`/`CommandExecution`; approve→execute→feedback; reject→no-execute; `kRunCommandTimeout` kill→`ToolError`; `tool_call_summary` | ✅ verified by code/tests |
| 016 | `ToolCallStepCard` renders `CommandExecution` preview + Approve/Reject row | 👁 needs visual check (explicitly marked "Visual — requires human QA" in issue) |
| 022 | `[kWebSearchTool, kFetchPageTool]` passed to `streamChat`; `kMaxDeepResearchSteps`; system-prompt addition; partial-answer notice at step limit | ✅ verified by code/tests |
| 022 | "Research" mode selectable in toggle; `web_search`/`fetch_page` render as step cards | 👁 needs visual check |

---

## Issues with automated failures

None. All 4 issues pass build, full test suite, lint, and code review.

---

## Visual QA Checklist

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
| 13 | A request that refers to a file in the working project (e.g. an image file) | Agent-mode conversation, ask the assistant about a file present on disk | **Regression check for the previously-fixed bug**: the assistant actually calls a tool and produces a visible step card + non-empty response — not an empty message. |

**Edge cases to manually test:**
- [ ] A turn where the model requests multiple tool calls at once (e.g. reads two files) — confirm multiple step cards render in order.
- [ ] A turn that mixes an auto-resolved read with a pending write in the same turn — confirm the resolved read's card shows its result while the write's card shows pending Approve/Reject.
- [ ] Very long tool output (e.g. a large file read) inside an expanded step card — confirm it doesn't break the layout (scrolls/truncates sensibly).

---

## Visual QA — [015] SearXNG service card in Settings + agent web search

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

---

## Outcome: Real-world visual QA — REJECTED (2026-06-14)

Real-world visual testing (beyond this report's automated re-verification) found agent mode still
does not work as a usable feature:

- Tool calls/step cards still don't reliably trigger.
- When step cards do render, the UI is broken.
- In some cases there isn't even a way to get a normal chat reply.
- The Chat/Agent/Research mode toggle doesn't read as a distinct "agent mode" — it looks and
  behaves like plain chat.

**Decision**: rather than another fix-and-reverify cycle on 010/015/016/022 individually, Agent and
Research modes have been **disabled** — Home chat is **chat-only for now** — via a single
`kAgentModeEnabled = false` switch in `agent_loop_constants.dart`. The underlying agent-loop
implementation and its passing unit/integration tests are left intact for a redesign. This area
(issues 004-022's agent-mode/Deep Research/shell-access work) will be redone under a **new PRD**.
See `docs/handoffs/handoff-agent-mode-redesign.md` for the full handoff.
