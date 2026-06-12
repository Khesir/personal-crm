# PRD: Hugging Face Model Discovery, Hardware-Fit Scan & Expanded API LLM Providers

**Status:** Draft
**Date:** 2026-06-13

---

## Problem Statement

Settings > Services > API LLM only offers "Claude (Anthropic)" and a generic "Custom API" — to use any
other provider (Groq, Gemini, OpenRouter, OpenAI, DeepSeek, Mistral, NVIDIA, OpenCode Zen) the user has to
already know that provider's base URL and paste it into "Custom API" by hand, with no recognizable name in
the Add flow.

Settings > Services > Local LLM only manages servers the user already has running (Ollama, Custom Local) —
there's no way to discover new models worth running, and no way to tell whether a given model (and
quantization) will actually fit the user's GPU/VRAM/RAM before downloading multiple gigabytes, short of
trial and error.

---

## Solution

Settings > Services > API LLM gains 8 new named provider entries in the "Add" type picker — Groq, Gemini,
OpenRouter, OpenAI, DeepSeek, Mistral, NVIDIA, and OpenCode Zen — each pre-filling a sensible default base
URL (editable) so the user typically only pastes an API key. All 8 behave exactly like today's "Custom
API": same fields, health check, model cookbook integration, and curation.

Settings > Services > Local LLM gains a "Search Hugging Face" entry point that detects the user's hardware
(GPU/VRAM/RAM/CPU cores/CUDA), searches Hugging Face's GGUF model catalog, and shows each model+quantization
candidate with an estimated VRAM requirement, context length, speed/score estimates, and a FIT badge
(PERFECT / GOOD / CPU-ONLY / TOO BIG) based on the detected hardware. A one-click "Download" pulls the
chosen model+quant into the user's default Ollama install via `ollama pull hf.co/<repo>:<quant>`, after
which it's immediately available in the Home chat cookbook.

---

## User Stories

### New API LLM provider types

1. As a user, I want to add a "Groq" card from the API LLM type picker, so I can use Groq's hosted models
   without manually finding its API base URL.
2. As a user, I want to add a "Gemini" card from the API LLM type picker, so I can use Google's Gemini
   models via its OpenAI-compatible endpoint.
3. As a user, I want to add an "OpenRouter" card from the API LLM type picker, so I can access OpenRouter's
   multi-provider model catalog.
4. As a user, I want to add an "OpenAI" card from the API LLM type picker, so I can use OpenAI's models
   directly.
5. As a user, I want to add a "DeepSeek" card from the API LLM type picker, so I can use DeepSeek's models.
6. As a user, I want to add a "Mistral" card from the API LLM type picker, so I can use Mistral's models.
7. As a user, I want to add an "NVIDIA" card from the API LLM type picker, so I can use NVIDIA's hosted
   model endpoints (NIM).
8. As a user, I want to add an "OpenCode Zen" card from the API LLM type picker, so I can use that
   provider's models.
9. As a user, for each of these new provider types, I want the base URL field pre-filled with a sensible
   default when I select that type in the Add flow, so I usually only need to paste an API key.
10. As a user, I want to be able to edit the pre-filled base URL, so I can point a card at a self-hosted or
    regional variant of a provider's API (e.g. a self-hosted NVIDIA NIM endpoint, or a corrected URL if a
    default turns out to be wrong).
11. As a user, I want each new provider card's health check to verify my API key the same way "Custom API"
    does today (`GET /v1/models` with my key as a Bearer token), so I know at a glance whether the
    connection works.
12. As a user, I want models from any enabled new-provider card to appear in the Home chat cookbook (like
    Claude Anthropic and Custom API today), so I can chat with Groq/Gemini/OpenRouter/etc. models directly.
13. As a user, I want per-model enable/disable curation for each new provider card (same checklist as
    existing API LLM cards), so I can hide models I don't want cluttering the cookbook.
14. As a user, I want errors returned by these providers (invalid key, rate limit, quota exceeded, etc.)
    surfaced in the chat the same way Anthropic/OpenAI-compatible errors are today, so I know what went
    wrong instead of seeing a generic failure.
15. As a user, I want the API LLM type picker to clearly list all 10 available types (Claude Anthropic,
    Custom API, and the 8 new providers) by name, so I can find the one I want even as the list grows.

### Hugging Face search & download

16. As a user, I want a "Search Hugging Face" button next to "Add" in the Local LLM category of Settings >
    Services, so I can discover new local models to run.
17. As a user, when I open the Hugging Face search, I want to see my detected hardware (GPU name, VRAM,
    RAM used/total, CPU core count, CUDA availability) displayed at the top, so I understand what the FIT
    ratings are based on.
18. As a user, I want to type a search query and see matching GGUF models from Hugging Face, with one row
    per model+quantization combination, so I can compare different quantizations of the same model.
19. As a user, when I haven't typed a search query yet, I want to see a default list of popular/trending
    GGUF models, so the screen isn't empty on first open.
20. As a user, I want each result row to show MODEL, PARAM (parameter count), QUANT (quantization), VRAM
    (estimated requirement), CTX (context length), SPEED (estimated tokens/sec), SCORE (overall fit
    ranking), and a FIT badge, so I can quickly judge how well each option suits my hardware.
21. As a user, I want a FIT badge of "PERFECT" when a model+quant fits comfortably in my detected VRAM, so
    I know it'll run fast on my GPU.
22. As a user, I want a FIT badge indicating CPU-only (fits RAM but not VRAM), so I know it'll run but
    slower.
23. As a user, I want a FIT badge indicating the model is too big even for my RAM, so I know not to bother
    downloading it.
24. As a user, I want results sorted with the best-fitting options first (by SCORE), so the most relevant
    models for my hardware are easy to find.
25. As a user, I want a "Download" button on each result row, so I can pull that exact model+quant without
    leaving the app.
26. As a user, clicking Download should pull the model into my Ollama install (via `ollama pull
    hf.co/<repo>:<quant>`) using my Default-marked Ollama card, so I don't have to use a terminal.
27. As a user, if I have more than one Ollama card and none is marked Default, I want to be asked which one
    to pull into, so the download goes to the install I intend.
28. As a user, while a model is downloading I want to see an inline progress indicator on that row, so I
    know it's working and roughly how far along it is.
29. As a user, I want to keep searching/browsing while a download is in progress, so the download doesn't
    block me.
30. As a user, once a download completes, I want the row to show it succeeded, and the model to be
    available in the Home chat cookbook for that Ollama card without any extra steps, so it's immediately
    usable.
31. As a user, if I have no Ollama card configured at all, I want the Download button disabled (with an
    explanation), so I understand why I can't download yet, while still being able to browse/search and see
    FIT ratings.
32. As a user, if a download fails (network error, Ollama not running, invalid repo/quant), I want to see
    an error on that row, so I know it didn't succeed and can retry.

### Hardware-fit detection

33. As a user, I want my GPU name, VRAM, and CUDA availability detected automatically via `nvidia-smi`, so
    I don't have to enter hardware specs manually.
34. As a user, if I don't have an NVIDIA GPU (or `nvidia-smi` isn't available), I want the app to treat
    this as "no dedicated GPU detected" and still show FIT ratings based on CPU/RAM only, so the feature
    still works on non-NVIDIA hardware.
35. As a user, I want my total and currently-available system RAM detected automatically, so RAM-based FIT
    ratings reflect my actual current load.
36. As a user, I want my CPU core count detected automatically, so it can factor into CPU-mode speed
    estimates.
37. As a user, I want hardware detection to re-run each time I open the Hugging Face search screen, so the
    readout reflects my current state (e.g. after closing other GPU-heavy apps).
38. As a user, I want to understand that SPEED and SCORE are estimates (not measured benchmarks), so I
    calibrate my expectations accordingly.

---

## Implementation Decisions

### New API LLM provider types

- `ServiceType` (`service_card.dart`) gains 8 new values: `groq`, `gemini`, `openRouter`, `openai`,
  `deepSeek`, `mistral`, `nvidia`, `openCodeZen`, each added to `ServiceCategory.apiLlm`. Each gets a
  `value`/`fromValue` string mapping for JSON persistence, following the existing enum pattern.
- `services_section.dart`'s `apiLlm` `availableTypes` grows from `[claudeAnthropic, customApi]` to include
  all 8 new types (10 total).
- Two small per-type lookup tables are added (pure data, no I/O):
  - **Label map** — display name shown in the type picker and card list:
    - `groq` → "Groq", `gemini` → "Gemini", `openRouter` → "OpenRouter", `openai` → "OpenAI",
      `deepSeek` → "DeepSeek", `mistral` → "Mistral", `nvidia` → "NVIDIA", `openCodeZen` → "OpenCode Zen".
    - "OpenAI" (not "ChatGPT") is used as the label, matching the actual API/product name.
  - **Default base URL map** — used only to pre-fill the `baseUrl` field when the form opens for a *new*
    card of that type (not re-applied when editing an existing card):
    - `groq` → `https://api.groq.com/openai/v1`
    - `gemini` → `https://generativelanguage.googleapis.com/v1beta/openai`
    - `openRouter` → `https://openrouter.ai/api/v1`
    - `openai` → `https://api.openai.com/v1`
    - `deepSeek` → `https://api.deepseek.com/v1`
    - `mistral` → `https://api.mistral.ai/v1`
    - `nvidia` → `https://integrate.api.nvidia.com/v1`
    - `openCodeZen` → best-effort placeholder, to be confirmed during implementation (see Further Notes)
- `service_card_form_dialog.dart`:
  - `_showBaseUrlField`, `_showApiKeyField`, `_isApiLlmType`, `_showModelChecklist` getters: the 8 new
    types are added alongside `customApi` (identical visibility rules).
  - `_typeLabel`: extended via the label map.
  - `_repositoryForCard`: the existing `customApi` case is extended to also match the 8 new types (one
    shared case, not 8 new ones), constructing the same
    `OpenAiCompatibleRepositoryImpl(OpenAiCompatibleDatasource(...))` with
    `Authorization: Bearer ${card.fields['apiKey']}` and `baseUrl: card.fields['baseUrl']`.
  - When the form opens for a brand-new card of one of these 8 types, the base URL text field's initial
    value comes from the default base URL map; the user can edit it before saving.
- `lib/features/home/di.dart::_repositoryFor`: same case-collapse as `_repositoryForCard` — the `customApi`
  case pattern is extended to also match the 8 new types.
- `lib/features/settings/data/repository/health_check_repository_impl.dart::check()`: the `customApi` case
  pattern is extended to also match the 8 new types — identical
  `_checkStatusAware(card, '/v1/models', headers: {'Authorization': 'Bearer $apiKey'})` check.
- No changes to `OpenAiCompatibleDatasource`, `OpenAiCompatibleRepositoryImpl`, or `chat_error_mapper.dart`
  — fully reused as-is by all 9 OpenAI-compatible API LLM types (`customApi` + the 8 new ones).

### Hugging Face search & download

- New datasource `HuggingFaceDatasource`:
  - `searchModels({String? query})` calls the Hugging Face Hub API (`GET
    https://huggingface.co/api/models`) filtered to GGUF models, sorted by downloads, with a result limit.
    An empty/absent query returns the same trending/popular GGUF list used as the default view.
  - For each returned repo, inspects its file listing (`siblings`) for `.gguf` files, inferring a
    quantization label (e.g. `Q4_K_M`, `Q5_K_M`, `Q8_0`) and file size from each filename/entry.
  - Parameter count (in billions) is parsed from the model id/name (e.g. "7B", "3B") or HF metadata where
    available; repos where it can't be determined are skipped.
  - Returns a flat list of `HuggingFaceModelResult { repoId, displayName, paramsBillions, quant,
    fileSizeBytes, contextLength }` — one entry per (repo, quant) combination.
- New domain models:
  - `HardwareInfo { gpuName, vramTotalMb, vramAvailableMb, cudaAvailable, ramTotalMb, ramAvailableMb,
    cpuCores }` — `gpuName` is `null` and `cudaAvailable` is `false` when no dedicated GPU is detected.
  - `ModelFitResult { vramEstimateMb, fit, mode, speedTokensPerSec, score }`, where:
    - `fit` is one of `perfect`, `good`, `cpuOnly`, `tooBig`.
    - `mode` is one of `gpu`, `partial`, `cpu`, `none`.
- New pure `FitScorer`:
  - `estimateVramMb(paramsBillions, quant)` ≈ `paramsBillions × bytesPerParam(quant) × 1024 +
    ctxOverheadMb`, where `bytesPerParam` is a small constant table for common GGUF quant names (Q2_K,
    Q3_K_*, Q4_0/Q4_K_*, Q5_K_*, Q6_K, Q8_0, F16, F32).
  - `score(hardware, model) -> ModelFitResult`:
    - `perfect` if `vramEstimate <= vramAvailable × 0.9` (fits with headroom) → `mode: gpu`
    - `good` if `vramEstimate <= vramAvailable × 1.1` (fits tightly) → `mode: gpu` (or `partial` near the
      boundary)
    - else `cpuOnly` if `vramEstimate <= ramAvailable` → `mode: cpu`
    - else `tooBig` → `mode: none`
    - `speedTokensPerSec` and `score` (0-100) are heuristic estimates derived from `fit`/`mode`/
      `paramsBillions`/`cpuCores`, clearly documented (in code and UI copy) as estimates, not measurements.
- New `HardwareInfoRepository`:
  - `Future<HardwareInfo> detect()`, built on an injectable `ProcessRunner` interface (`Future<ProcessResult>
    run(String executable, List<String> args)`) with a real implementation backed by `dart:io`'s
    `Process.run`.
  - GPU/VRAM/CUDA: `nvidia-smi --query-gpu=name,memory.total,memory.used,driver_version
    --format=csv,noheader`. If the process fails to start or exits non-zero, treat as "no dedicated GPU
    detected" (`gpuName: null`, VRAM 0, `cudaAvailable: false`) — no error surfaced to the user.
  - RAM: a PowerShell query against `Win32_OperatingSystem` (`TotalVisibleMemorySize` /
    `FreePhysicalMemory`, KB → MB).
  - CPU cores: `Platform.numberOfProcessors` (no process call).
  - Detection re-runs every time the Hugging Face search screen opens; results are not cached.
- `OllamaDatasource` gains `pullModel({required String name})`:
  - `POST /api/pull` with `{"name": name, "stream": true}`, `responseType: stream`.
  - Parses newline-delimited JSON progress objects (`{"status": ..., "total": ..., "completed": ...}`) into
    a `Stream<OllamaPullProgress { status, totalBytes, completedBytes }>`, completing on `{"status":
    "success"}`.
  - Errors (e.g. Ollama unreachable, invalid repo/quant) are mapped via the same
    `describeChatError`-style approach as `chat_error_mapper.dart`, so failures surface a meaningful
    message.
- New controller `ModelDiscoveryController`:
  - Depends on `HuggingFaceDatasource`/repository, `HardwareInfoRepository`, `OllamaDatasource`/repository,
    and `ServiceCardsRepository` (to find the Default-marked Ollama card).
  - On load: detects hardware, runs an initial empty-query search, computes `ModelFitResult` per result via
    `FitScorer`, sorts by `score` descending.
  - `search(query)`: re-queries Hugging Face, recomputes fit, re-sorts.
  - `download(HuggingFaceModelResult result)`: resolves the target Ollama card (Default-marked card, or the
    only Ollama card if there's exactly one; a picker is shown if multiple exist and none is Default; the
    action is unavailable if there's no Ollama card at all), then calls
    `pullModel(name: 'hf.co/${result.repoId}:${result.quant}')`, exposing per-result state (`idle`,
    `downloading(progress)`, `added`, `failed(error)`) via its state stream.
  - On successful pull, the existing cookbook-refresh path (`ChatController.refresh()`, already triggered
    whenever Home becomes visible via `home/di.dart`) picks up the newly pulled model automatically — no
    additional wiring needed.
- New UI `HuggingFaceSearchDialog`, launched from a new "Search Hugging Face" action in
  `services_section.dart`'s Local LLM `_CategorySection`, showing the hardware bar, a search box, and the
  results table (MODEL/PARAM/QUANT/VRAM/CTX/SPEED/SCORE/FIT/MODE + Download) per the resolved design.

---

## Testing Decisions

- General principle: test through public interfaces/repositories, not private switch internals. Mock only
  external boundaries — HTTP via fake Dio adapters, process execution via a fake `ProcessRunner`.
- **`ServiceType`/`ServiceCard` JSON round-trip**: extend `test/features/settings/domain/model/service_card_test.dart`
  with round-trip cases for the 8 new `ServiceType` values, following the existing round-trip test pattern
  in that file.
- **Label/default-base-URL lookup maps**: new lightweight unit tests asserting each of the 8 new
  `ServiceType`s has a non-empty label and a non-empty default base URL — pure `Map` lookups, no I/O.
- **`HuggingFaceDatasource`**: new test file `test/features/settings/data/datasource/huggingface_datasource_test.dart`,
  using the `_FakeAdapter`/`_dioWith` pattern from `anthropic_datasource_test.dart` — feed canned HF API
  JSON responses (including repos with multiple GGUF siblings at different quants) and assert the parsed
  `HuggingFaceModelResult` list (`repoId`, `paramsBillions`, `quant`, `fileSizeBytes`).
- **`OllamaDatasource.pullModel()`**: new test alongside the existing `ollama_datasource_test.dart` (or a
  new file in the same directory), using the same fake-adapter streaming pattern as the existing
  `streamChat` tests — feed canned NDJSON progress lines and assert the resulting `OllamaPullProgress`
  stream, plus an error case (non-2xx response) asserting the mapped error.
- **`FitScorer`**: new test file, table-driven — for representative (hardware, model) pairs, assert
  `vramEstimateMb`, `fit`, and `mode`. Cover: GPU with ample VRAM (`perfect`), GPU with tight VRAM (`good`),
  no GPU but enough RAM (`cpuOnly`), too big for RAM (`tooBig`), and "no dGPU detected" hardware.
  `speedTokensPerSec`/`score` assertions are limited to "non-negative and ordered consistently with `fit`"
  rather than exact values, since they're heuristic.
- **`HardwareInfoRepository`**: new test file using a fake `ProcessRunner` returning canned
  `nvidia-smi`/PowerShell stdout — assert parsed `HardwareInfo` for: NVIDIA GPU present, `nvidia-smi` not
  found (no dGPU), and malformed output (graceful fallback, no crash).
- **`ModelDiscoveryController`**: new controller test following the pattern in
  `service_cards_controller_test.dart`/`chat_controller_test.dart` — fake `HuggingFaceDatasource`/repository,
  fake `HardwareInfoRepository`, fake Ollama pull stream, fake `ServiceCardsRepository`. Covers: initial
  load populates sorted results with fit; `download()` transitions a result through
  `idle → downloading → added`; download is unavailable when no Ollama card exists; a failed pull surfaces
  an error state.
- Existing `OpenAiCompatibleDatasource`/`OpenAiCompatibleRepositoryImpl` tests are unchanged and continue to
  cover the shared code path used by all 9 OpenAI-compatible API LLM types.
- Visual/UI checks — the new "Search Hugging Face" entry point, hardware bar, results table, per-row
  progress indicators, the 10-entry API LLM type picker, and the pre-filled-but-editable base URL field —
  are flagged for human visual QA, not automated.

---

## Out of Scope

- Embedded/local model inference — no bundled llama.cpp; the app continues to talk only to external servers
  (Ollama, OpenAI-compatible servers, cloud APIs).
- Hugging Face download/pull support for Custom Local (e.g. LM Studio) servers — download is Ollama-only,
  since Ollama is the only target with a documented pull-from-HF API.
- FIT ratings for already-installed/configured local models (existing per-card model checklists) — FIT is
  scoped to the new Hugging Face search screen only for v1.
- GPU vendors other than NVIDIA (AMD/Intel) — treated as "no dedicated GPU detected," falling back to
  CPU/RAM-only fit. No ROCm/DirectML detection.
- Managing or uninstalling already-downloaded models — only new downloads via the search screen; no delete
  UI.
- Hugging Face authentication/API tokens — search uses HF's public, unauthenticated API only; private/gated
  models are out of scope.
- Real benchmark-based SPEED/SCORE — both remain heuristic estimates; no on-device benchmarking.
- Non-Windows hardware detection — `nvidia-smi`/PowerShell-based detection targets the app's current Windows
  desktop platform.

---

## Further Notes

- OpenCode Zen's default base URL is a best-effort placeholder pending verification at implementation time;
  since the field is pre-filled-but-editable, an incorrect default doesn't block the user.
- Gemini is included via Google's OpenAI-compatible endpoint
  (`generativelanguage.googleapis.com/v1beta/openai`), avoiding a bespoke datasource — same Bearer-auth,
  `/v1/chat/completions` + `/v1/models` shape as the other 7 new providers.
- This PRD builds directly on the service-cards/cookbook architecture completed in the previous cycle,
  archived at `issues/archive/2026-06-13-services-cards-and-archive-boards/`.
