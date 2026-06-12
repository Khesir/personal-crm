---
id: issue-003
title: "Search Hugging Face — results table + hardware detection bar"
feature: model-discovery
status: qa
created_at: 2026-06-13
tags: [afk, p1]
---

# [003] Search Hugging Face — results table + hardware detection bar

**Type:** AFK
**Priority:** P1
**Blocked by:** None
**User stories covered:** 16, 17, 18, 19, 33, 34, 35, 36, 37

---

## What to build

A new "Search Hugging Face" entry point in Settings > Services > Local LLM, opening a dialog that shows the
user's detected hardware and a searchable table of GGUF models from Hugging Face. FIT/SPEED/SCORE/MODE and
the Download action are explicitly NOT part of this issue (see 004 and 005) — this issue establishes the
search + hardware-detection foundation they build on.

- New "Search Hugging Face" button next to "Add" in the Local LLM category section.
- New dialog showing, at the top, a hardware bar: GPU name, VRAM (total/used), RAM (available/total), CPU
  core count, and CUDA availability.
- Hardware detection (`HardwareInfo { gpuName, vramTotalMb, vramAvailableMb, cudaAvailable, ramTotalMb,
  ramAvailableMb, cpuCores }`):
  - GPU/VRAM/CUDA via `nvidia-smi --query-gpu=name,memory.total,memory.used,driver_version
    --format=csv,noheader`. If the process fails to start or exits non-zero, treat as "no dedicated GPU
    detected" (`gpuName: null`, VRAM 0, `cudaAvailable: false`) — no error shown to the user.
  - RAM via a PowerShell query against `Win32_OperatingSystem` (`TotalVisibleMemorySize` /
    `FreePhysicalMemory`, KB → MB).
  - CPU cores via `Platform.numberOfProcessors` (no process call).
  - Built on an injectable `ProcessRunner` interface (`Future<ProcessResult> run(String executable,
    List<String> args)`) with a real `dart:io`-`Process.run`-backed implementation, so tests can supply
    canned output.
  - Detection re-runs every time the dialog opens; not cached.
- New `HuggingFaceDatasource.searchModels({String? query})`:
  - Calls the Hugging Face Hub API (`GET https://huggingface.co/api/models`) filtered to GGUF models,
    sorted by downloads, with a result limit. An empty/absent query returns the same
    trending/popular-GGUF list used as the default view.
  - For each repo, inspects its file listing (`siblings`) for `.gguf` files, inferring a quantization label
    (e.g. `Q4_K_M`, `Q5_K_M`, `Q8_0`) and file size per file.
  - Parses parameter count (billions) from the model id/name (e.g. "7B", "3B") or HF metadata where
    available; repos where it can't be determined are skipped.
  - Returns `List<HuggingFaceModelResult { repoId, displayName, paramsBillions, quant, fileSizeBytes,
    contextLength }>` — one entry per (repo, quant) combination.
- New `ModelDiscoveryController` (initial version): on load, detects hardware and runs an empty-query
  search; `search(query)` re-queries and replaces results. No fit scoring or download yet — results table
  shows MODEL / PARAM / QUANT / CTX columns only.

---

## Acceptance criteria

- [ ] "Search Hugging Face" button appears in the Local LLM category, opens a dialog.
- [ ] The dialog shows a hardware bar with GPU name, VRAM, RAM, CPU core count, and CUDA status, detected
  fresh each time the dialog opens.
- [ ] On a machine without an NVIDIA GPU (or without `nvidia-smi`), the hardware bar shows "no dedicated GPU
  detected" without erroring, and still shows RAM/CPU info.
- [ ] On first open (empty search), a default list of popular/trending GGUF models is shown.
- [ ] Typing a search query replaces the results with matching GGUF models.
- [ ] Each result row shows MODEL, PARAM, QUANT, and CTX, with one row per (model, quantization)
  combination.

---

## Tests required

Yes:
- New `HuggingFaceDatasource` test (fake Dio adapter, same pattern as `anthropic_datasource_test.dart`):
  feed canned HF API JSON (including a repo with multiple GGUF siblings at different quants) and assert the
  parsed `HuggingFaceModelResult` list (`repoId`, `paramsBillions`, `quant`, `fileSizeBytes`).
- New `HardwareInfoRepository` test using a fake `ProcessRunner` returning canned `nvidia-smi`/PowerShell
  stdout: assert parsed `HardwareInfo` for (a) NVIDIA GPU present, (b) `nvidia-smi` not found (no dGPU), and
  (c) malformed output (graceful fallback, no crash).
- New `ModelDiscoveryController` test (fake datasource + fake `HardwareInfoRepository`, pattern from
  `service_cards_controller_test.dart`): initial load populates hardware + default results; `search(query)`
  replaces results.

---

## Notes

- This issue does not add FIT/MODE/SPEED/SCORE columns (issue 004) or the Download action (issue 005) —
  results are informational only at this stage.
- Hugging Face search uses the public, unauthenticated API only — no token field.
- `nvidia-smi`/PowerShell-based detection targets Windows (the app's current desktop platform).

---

## Log

_Updated as work progresses._

- Implemented `HardwareInfo`/`HuggingFaceModelResult`/`ModelDiscoveryState` models, `ProcessRunner`/`IoProcessRunner`,
  `HardwareInfoRepositoryImpl` (nvidia-smi + PowerShell `Win32_OperatingSystem` + `Platform.numberOfProcessors`,
  with graceful no-GPU/zeroed-RAM fallbacks), `HuggingFaceDatasource.searchModels()`, and `ModelDiscoveryController`
  (`load()`/`search()`), wired via `createModelDiscoveryController()` in `di.dart` and exported from `api.dart`.
  Added a "Search Hugging Face" button to the Local LLM category in `services_section.dart` and a new
  `HuggingFaceSearchDialog` (hardware bar + search field + MODEL/PARAM/QUANT/CTX results table).
- Tested: `huggingface_datasource_test.dart` (parsing of repoId/paramsBillions/quant/fileSizeBytes/contextLength,
  skipping unparseable repos, search-param presence/absence), `hardware_info_repository_impl_test.dart` (GPU
  present, nvidia-smi missing/non-zero, malformed PowerShell JSON, cpuCores), and
  `model_discovery_controller_test.dart` (load populates hardware+results, search replaces results while keeping
  hardware). `flutter analyze` clean (2 pre-existing unrelated infos only) and `flutter test` 139/139 passing.
- Flagged for human QA: the HF Hub API response-shape assumptions documented in `huggingface_datasource.dart`
  (siblings/size/config.max_position_embeddings) are based on a single live fetch and should be sanity-checked
  against real searches; the new dialog UI (hardware bar layout, search behavior, results table) has not been
  visually/widget-tested and needs manual QA on a Windows machine (with and without an NVIDIA GPU).
