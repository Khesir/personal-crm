# QA Report

_Date: 2026-06-13_

---

## Automated QA Results

| Issue | Title | Build | Tests Pass | Test Quality | Lint | Code Review | Result |
|-------|-------|-------|------------|--------------|------|-------------|--------|
| [001](qa/001-groq-first-new-api-llm-provider.md) | Groq as first new API LLM provider | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [002](qa/002-remaining-api-llm-providers.md) | Remaining 7 API LLM providers | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [003](qa/003-huggingface-search-and-hardware-bar.md) | Search Hugging Face — results table + hardware bar | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [004](qa/004-hardware-fit-scoring.md) | Hardware-fit scoring (VRAM/SPEED/SCORE/FIT/MODE) | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [005](qa/005-ollama-download-with-progress.md) | One-click download into Ollama with progress | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |

- `flutter build windows --debug`: succeeds (`Built build\windows\x64\runner\Debug\crm.exe`).
- `flutter test`: 182/182 passing.
- `flutter analyze`: clean — 2 pre-existing `activeColor` deprecation infos in unrelated files, no new issues.

**Test quality**: all new tests use fakes only at system boundaries — fake `Dio` HTTP adapters for the Hugging Face and Ollama datasources, a fake `ProcessRunner` for hardware detection, and fake datasource/hardware-repository pairs for the discovery controller. Assertions check observable state (parsed results, hardware values, download status transitions, sort order) rather than call counts or internals. `FitScorer` and the type-metadata lookup tables are covered with table-driven cases. No private methods are tested directly.

**Code review**: the eight new provider types (001/002) consistently extend the existing `customApi`-style collapsed cases — repository construction (`_repositoryForCard`/`_repositoryFor`), the `/v1/models` health check, and the form dialog's visibility getters — via the shared `service_type_metadata.dart` lookup tables, with no duplicated logic. The model-discovery feature (003-005) follows the existing `StreamState` + datasource/repository/controller pattern; `FitScorer` is pure with no I/O; download status updates use `update()` for surgical per-row changes, preserving the rest of the dialog's state. No dead code, no leftover scope-creep, no stale "out of scope" comments.

---

## Issues with automated failures

None. All five issues pass build, tests, lint, and code review.

---

## Flagged for follow-up (not a blocker for 001-005, but raised during this QA pass)

**Download state is lost if the "Search Hugging Face" dialog is closed mid-download.**

The model-discovery controller (and its per-result download status) is created fresh each time the dialog opens and is disposed when it closes. If a user starts a download and closes the dialog before it finishes:

- The pull itself keeps running in the background (Ollama's pull request isn't cancelled), but nothing in the UI reflects that — the controller holding the in-progress/added/failed state is gone.
- Re-opening "Search Hugging Face" creates a brand-new controller with all results back at idle, with no way to tell whether the earlier pull is still running, finished, or failed.
- The Local LLM section of Services has no indication that a download is/was in progress for a model.

This is a real product gap but is **out of scope for issues 001-005 as written** — their acceptance criteria don't require cross-dialog/cross-session visibility. Recommend writing it up as a new issue (e.g. "Persist and surface Hugging Face download status outside the search dialog") rather than folding it into 005's sign-off. Suggested shape:
- Lift download tracking out of the dialog-scoped controller into something that survives the dialog closing (e.g. a small persisted/long-lived download tracker keyed by repo+quant, or surfaced via the existing service-cards controller).
- Add a card/row in the Local LLM category (Services) for in-progress and recently-completed Hugging Face downloads, showing the same progress info currently shown inline in the dialog.

**OpenCode Zen's default base URL is unverified against a live API.**

The pre-filled base URL `https://opencode.ai/zen/v1` is best-effort from a web search and was not exercised against a live `/v1/models` call. The field is editable, so this is non-blocking — flag during visual QA if it doesn't work.

---

## Visual QA Checklist

## Visual QA — 001 Groq as the first new API LLM provider

| # | What to check | Where | Expected |
|---|---|---|---|
| 1 | Open the "Add" type picker for API LLM | Settings > Services > API LLM > Add | "Groq" appears in the list of provider types |
| 2 | Select "Groq" from the type picker | Same dialog | Form opens titled "Add Groq", Base URL field pre-filled with `https://api.groq.com/openai/v1` (editable), plus an API Key field |
| 3 | Save a Groq card with a valid Groq API key | Settings > Services > API LLM | Card shows status badge "Online" after the health check completes |
| 4 | Save a Groq card with an invalid/garbage API key | Settings > Services > API LLM | Card shows status badge "Error" |
| 5 | Enable a Groq card, then open Home chat | Home | Groq's models appear in the model picker/cookbook |
| 6 | Edit the Groq card | Settings > Services > API LLM > Edit | Per-model checklist lists the Groq models; toggling a checkbox enables/disables it in the Home cookbook |
| 7 | Send a chat message using a Groq model with a valid key | Home chat | Response streams in normally |
| 8 | Send a chat message using a Groq model with an invalid key | Home chat | Error message shown is Groq's own error text (e.g. invalid API key), not a generic failure |

**Edge cases to manually test:**
- [ ] Editing the pre-filled Groq base URL to a different value and saving — confirm the custom URL is used for the health check and chat requests.

---

## Visual QA — 002 Remaining 7 API LLM providers

| # | What to check | Where | Expected |
|---|---|---|---|
| 1 | Open the "Add" type picker for API LLM | Settings > Services > API LLM > Add | 10 total providers listed: Claude (Anthropic), Custom API, Groq, Gemini, OpenRouter, OpenAI, DeepSeek, Mistral, NVIDIA, OpenCode Zen |
| 2 | For each of the 7 new providers, select it from the picker | Same dialog | Form opens with that provider's base URL pre-filled (editable) per the table in the issue, plus an API Key field |
| 3 | Save a card for each provider with a valid API key | Settings > Services > API LLM | Card shows "Online" after health check |
| 4 | Enable a card for each provider, open Home chat | Home | That provider's models appear in the model cookbook and can be enabled/disabled via the per-model checklist |
| 5 | Gemini specifically: save a card with a valid Google API key | Settings > Services > API LLM, then Home chat | Health check shows "Online" against `generativelanguage.googleapis.com/v1beta/openai`, models list loads, and chat works via the OpenAI-compatibility layer |
| 6 | Trigger a provider error (invalid key, rate limit) for at least one of the 7 | Home chat | The provider's own error message is shown, not a generic failure |
| 7 | OpenCode Zen specifically: save a card and check health/model list | Settings > Services > API LLM | Confirm whether the pre-filled base URL `https://opencode.ai/zen/v1` actually works; if "Error"/"Offline", manually correct the Base URL field to the working endpoint (field is editable) |

**Edge cases to manually test:**
- [ ] "OpenAI" label reads "OpenAI" (not "ChatGPT") in the type picker and card list.
- [ ] All 10 provider types are visually distinguishable in the card list (name + type label).

---

## Visual QA — 003 Search Hugging Face — results table + hardware detection bar

| # | What to check | Where | Expected |
|---|---|---|---|
| 1 | Click "Search Hugging Face" | Settings > Services > Local LLM | Dialog opens next to the "Add" button |
| 2 | Look at the hardware bar at the top of the dialog | "Search Hugging Face" dialog | Shows GPU name, VRAM (used/total), RAM (available/total), CPU core count, CUDA availability — values look plausible for this machine |
| 3 | Close and reopen the dialog | Same | Hardware bar re-detects each time (values can change if e.g. VRAM usage changed) |
| 4 | On a machine without an NVIDIA GPU / `nvidia-smi` | Same dialog | GPU shows "No dedicated GPU detected", VRAM shows "—", RAM/CPU/CUDA still populate, no error dialog or crash |
| 5 | Open the dialog without typing a search | Same dialog | Results table is pre-populated with a default list of popular/trending GGUF models |
| 6 | Type a model name (e.g. "llama") and press Enter | Same dialog | Results table replaces with matches for that query |
| 7 | Inspect a results row | Same dialog | MODEL (display name + repo id + size), PARAM, QUANT, CTX columns are populated and look correct for a known model |
| 8 | Inspect multiple quant variants of the same model | Same dialog | Each (model, quantization) combination appears as its own row |

**Edge cases to manually test:**
- [ ] Search for a query with no GGUF matches — results table shows an empty state ("No models found.") without crashing.
- [ ] Search for a very common term (e.g. "model") — confirm the result limit (30) is respected and the UI doesn't hang.

---

## Visual QA — 004 Hardware-fit scoring (VRAM/SPEED/SCORE/FIT/MODE columns)

| # | What to check | Where | Expected |
|---|---|---|---|
| 1 | Open "Search Hugging Face" with the default result list | Settings > Services > Local LLM | Each row shows VRAM, SPEED, SCORE, a FIT badge, and MODE in addition to MODEL/PARAM/QUANT/CTX |
| 2 | Find a small model/quant relative to your GPU's VRAM | Results table | FIT badge shows "PERFECT" (green) and MODE shows "GPU" |
| 3 | Find a model/quant too big for VRAM but small enough for system RAM | Results table | FIT shows a CPU-only badge and MODE shows "CPU" |
| 4 | Find a very large model/quant (e.g. a 70B+ model at high precision) | Results table | FIT shows "TOO BIG" (red/error color) and MODE indicates it won't run ("NONE") |
| 5 | Scroll through the full results list | Results table | Rows are sorted with the highest SCORE first, descending |
| 6 | Read the caption below the column headers | Results table | Text states SPEED/SCORE are estimates, not measured benchmarks |
| 7 | On hardware with no dedicated GPU (from issue 003's fallback) | Results table | FIT/MODE values are computed from CPU/RAM only — no row shows MODE = GPU, and the UI doesn't crash |

**Edge cases to manually test:**
- [ ] SPEED values are prefixed with "~" to visually reinforce "estimate".
- [ ] FIT badge colors are distinguishable: PERFECT (success/green), GOOD (info/blue), CPU ONLY (warning), TOO BIG (error/red).

---

## Visual QA — 005 One-click download into Ollama with progress

| # | What to check | Where | Expected |
|---|---|---|---|
| 1 | With no Ollama service card configured, open "Search Hugging Face" | Settings > Services > Local LLM | Each row's DOWNLOAD column shows a disabled "Download" button with a tooltip explaining an Ollama card is needed |
| 2 | Add exactly one Ollama service card (or mark one as Default among several), then click Download on a row | Same dialog | Pull starts immediately — no card-picker prompt |
| 3 | Add a second Ollama service card, with neither marked Default, then click Download | Same dialog | A picker dialog appears asking which Ollama card to download into |
| 4 | While a download is in progress | Same dialog | The row's DOWNLOAD cell shows a progress bar + status text (e.g. "pulling manifest", byte counts) instead of the button; other rows and the search field remain interactive |
| 5 | Let a download complete successfully | Same dialog | Row shows an "Added" badge (checkmark) |
| 6 | After a successful download, navigate to Home (or revisit it) | Home chat | The newly pulled model appears in the model cookbook for that Ollama card without restarting the app |
| 7 | Trigger a failed pull (e.g. stop Ollama before clicking Download, or use an invalid repo/quant) | Same dialog | Row shows an error message and a "Download" button to retry |
| 8 | Click Download again after a failure | Same dialog | Pull restarts; progress UI reappears |

**Edge cases to manually test:**
- [ ] Start a download, then **close the dialog before it finishes**, then reopen "Search Hugging Face" — note what the row shows (currently resets to idle with no indication the earlier pull may still be running in the background; see "Flagged for follow-up" above). Confirm whether the model eventually appears in the Local LLM Services list / Home cookbook once Ollama finishes the pull, even though the dialog showed no progress.
- [ ] Start two downloads in quick succession (different rows) — confirm both progress independently.

---

## How to sign off

For each issue you visually verify:
- Approved → run `/qa-approve [issue number]`
- Something is wrong → run `/qa-reject [issue number] [what you saw]`
