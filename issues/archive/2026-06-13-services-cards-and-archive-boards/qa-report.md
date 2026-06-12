# QA Report

_Date: 2026-06-13_

---

## Automated QA Results

| Issue | Title | Build | Tests Pass | Test Quality | Lint | Code Review | Result |
|-------|-------|-------|------------|--------------|------|--------------|--------|
| [007](qa/007-local-model-cookbook.md) | Local model cookbook (multi-card picker, routing & curation) | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [008](qa/008-api-llm-cookbook-integration.md) | API LLM cookbook integration (Claude Anthropic & Custom API in Home chat) | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |

**Build**: `flutter analyze` — clean (only the same 2 pre-existing, unrelated `activeColor` deprecation infos in `announcements_section.dart` / `project_form_dialog.dart`, present before this work).

**Tests**: `flutter test` — 123/123 passing, no skips, no failures (was 120 before this round's bug fixes; +3 new tests).

**Lint**: same `flutter analyze` run — no new warnings introduced by either bug fix.

**Bug regression checks**:
- **007** — both new bugs from the last rejection have a failing-then-passing test reproducing their root cause via the public interface: a `ServiceCardsController.toggleCardEnabled` test (enable/disable control was entirely missing before) and a `createChatController` concurrency test (which failed with two divergent controller instances before the fix, and now returns the same singleton).
- **008** — the crash bug has a new test that drives `ChatController.sendMessage()` against a repository whose stream emits an error, confirming the call resolves without throwing and the assistant's message ends up with non-empty content and `streaming: false`.

---

## Issues with automated failures

None. Both issues pass build, tests, lint, test-quality, and code review.

Non-blocking notes from code review (none require fixes before sign-off):

- **(007)** The new enable/disable `Switch` was added to the shared service-card tile widget, so it now appears for every category (Local LLM, API LLM, Services), not just Local LLM as the bug report specifically called out. This is a natural consequence of the shared widget and is consistent with how other per-card controls (Set Default, model curation) already work across categories — not a problem, just broader than the original bug description.
- **(008)** A failed response now shows a generic "⚠️ Something went wrong while generating a response. Please try again." message in the assistant's bubble, regardless of the underlying cause (bad API key, rate limit, network error, malformed request, etc.). This was an explicit minimal-scope choice. If users need to distinguish *why* a request failed, a follow-up issue could add more specific error messaging — not required for this fix.

---

## Acceptance Criteria Summary

Unchanged from the previous QA round — neither bug fix altered the underlying acceptance-criteria implementation, only fixed gaps in exercising/handling them.

| Issue | Criteria verified by code/tests (✅) | Needs visual check (👁) | Not met (❌) |
|-------|----------------------------------------|---------------------------|----------------|
| 007 | 4 / 6 | 2 / 6 | 0 |
| 008 | 2 / 8 | 6 / 8 | 0 |

Note: 007's acceptance criterion #3 ("disabled or unreachable card excluded, rest still populates") was already ✅ at the code/test level (a fake card with `enabled: false` was already excluded by `ChatController.refresh()`'s filter, and this is tested) — but a real user previously had **no way** to disable a card from the UI at all. The enable/disable `Switch` added this round doesn't change AC #3's code-verifiability, but it's what makes the "disabled" half of AC #3 visually checkable for the first time — see new visual QA item 007/#9 below.

---

## Visual QA Checklist

## Visual QA — 007 Local model cookbook (multi-card picker, routing & curation)

| # | What to check | Where | Expected |
|---|---|---|---|
| 1 | Multi-card model picker | Home chat, with two enabled Local LLM cards configured (e.g. one Ollama, one Custom Local) | The model picker lists models from both cards, each shown as "`<model> — <card name>`" |
| 2 | Routing to the right server | Select a model from each card in turn and send a message | The response streams from that card's configured server |
| 3 | Disabled/unreachable card excluded | Disable one Local LLM card (or point it at an unreachable address), reopen Home chat | That card's models are absent from the picker; the other card's models still appear |
| 4 | Active entry fallback | With a model from card B selected, disable or delete card B in Settings, then return to Home chat | The picker falls back to the first remaining entry from another enabled card, or shows an empty state if none remain |
| 5 | Per-model checklist in edit dialog | Settings > Services > Local LLM > Edit an Ollama/Custom Local card | A "Models" checklist appears, populated with that card's installed models, each individually togglable |
| 6 | Curation persists | Uncheck a model in the checklist and save, reopen Home chat, then later re-check it in the edit dialog | The unchecked model disappears from Home chat's picker on next load; re-checking it restores it on a subsequent load |
| 7 | Unreachable card in edit dialog | Edit a Local LLM card whose server is unreachable | The "Models" section shows "Unable to load models" instead of a checklist or an error |
| 8 | **(NEW — Bug A fix)** Enable/disable toggle on a service card | Settings > Services > Local LLM (and also visible on API LLM / Services cards) | Each card tile shows a Switch reflecting whether the card is enabled; tapping it toggles the card's enabled state immediately |
| 9 | **(NEW — Bug A fix, re-verifies AC #3)** Disabling a Local LLM card via the new Switch | Toggle a Local LLM card's Switch to off in Settings, then open/return to Home chat | That card's models disappear from the model picker; the other enabled card's models still appear (toggling it back on restores its models on next refresh) |
| 10 | **(NEW — Bug B fix)** Newly-added Ollama card appears without opening its edit dialog | Settings > Services > Local LLM > Add an Ollama card pointed at a reachable server, save, then go straight to Home chat (do NOT open the new card's edit dialog) | The new card's models appear in Home chat's model picker immediately, labeled "`<model> — <card name>`" |

**Note on the previous item 8 (provider-agnostic empty-state copy):** this is superseded — issue 008 changed the empty state again. See 008's item 8 below for the current expected copy.

**Edge cases to manually test:**
- [ ] A project whose `issues/archive/` folder contains several subfolders — confirm ordering (newest-first) and that the dropdown stays usable
- [ ] Switch models mid-conversation between two different cards and confirm both responses stream correctly with no crashes
- [ ] Start the app with a local model server stopped, then start the server and use Refresh/reload to confirm the cookbook picks up newly-available models

---

## Visual QA — 008 API LLM cookbook integration (Claude Anthropic & Custom API in Home chat)

| # | What to check | Where | Expected |
|---|---|---|---|
| 1 | Claude Anthropic models appear in the picker | Settings > Services > API LLM, add/enable a Claude Anthropic card with a valid API key; then open Home chat | The model picker lists Claude's models (e.g. "claude-3-5-sonnet-20241022 — `<card name>`"), alongside any Local LLM entries |
| 2 | Custom API models appear in the picker | Settings > Services > API LLM, add/enable a Custom API card pointed at a reachable OpenAI-compatible endpoint with a valid bearer token; then open Home chat | The model picker lists that server's models as "`<model> — <card name>`", alongside other entries |
| 3 | Claude streaming response | In Home chat, select a Claude Anthropic entry and send a message | The assistant's reply streams in incrementally (text appears progressively, not all at once) and the streaming indicator clears once the response finishes |
| 4 | Custom API streaming response | In Home chat, select a Custom API entry and send a message | The assistant's reply streams in incrementally via the configured server and bearer token, the same as a Custom Local entry |
| 5 | Per-model checklist for API LLM cards | Settings > Services > API LLM > Edit a Claude Anthropic or Custom API card | A "Models" checklist appears with that card's available models, each individually togglable, same as for Local LLM cards |
| 6 | disabledModels curation for API LLM cards | Uncheck a model in step 5's checklist and save, then reopen Home chat | The unchecked model no longer appears in the picker; re-checking it in the edit dialog restores it on the next load |
| 7 | Mid-session switching between Local and API LLM entries | In Home chat, send a message using a Local LLM entry, then switch to a Claude Anthropic or Custom API entry and send another | Both responses stream correctly from their respective backends, with no errors or leftover state from the previous entry |
| 8 | Empty-state copy | Home chat with no conversation started | The empty state reads "Assistant" / "Chat with your configured models — local or API." — no claim that chats stay local or private |
| 9 | **(NEW — Bug fix)** A rejected/failed request no longer crashes the app | In Home chat, select a Claude Anthropic entry (e.g. with an invalid API key, or send something the API responds to with a 4xx) and send a message | The app does not crash. The assistant's message displays "⚠️ Something went wrong while generating a response. Please try again." and the "generating…" indicator clears |

**Edge cases to manually test:**
- [ ] Configure a Claude Anthropic card with an invalid API key — confirm it contributes zero entries to the picker without affecting other cards (per-card isolation)
- [ ] With that invalid-key Claude Anthropic card, send a message — confirm it shows the new error message from item 9 above instead of crashing or getting stuck "generating…" (this replaces the previous "note what the UI does on failure" edge case, since that's now the behavior being verified)
- [ ] With both a Claude Anthropic card and a Custom API card enabled alongside a Local LLM card, confirm all three contribute entries to the picker in the expected order

---

## How to sign off

For each issue you visually verify:
- Approved → run `/qa-approve [issue number]`
- Something is wrong → run `/qa-reject [issue number] [what you saw]`
