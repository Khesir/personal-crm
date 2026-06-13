---
id: issue-004
title: "Hardware-fit scoring (VRAM/SPEED/SCORE/FIT/MODE columns)"
feature: model-discovery
status: done
created_at: 2026-06-13
tags: [afk, p2]
---

# [004] Hardware-fit scoring (VRAM/SPEED/SCORE/FIT/MODE columns)

**Type:** AFK
**Priority:** P2
**Blocked by:** 003
**User stories covered:** 20, 21, 22, 23, 24, 38

---

## What to build

A pure `FitScorer` that compares each Hugging Face search result against the detected hardware from issue
003, adding VRAM/SPEED/SCORE/FIT/MODE columns to the results table and sorting by fit.

- `estimateVramMb(paramsBillions, quant)` ≈ `paramsBillions × bytesPerParam(quant) × 1024 + ctxOverheadMb`,
  where `bytesPerParam` is a small constant table for common GGUF quant names (Q2_K, Q3_K_*, Q4_0/Q4_K_*,
  Q5_K_*, Q6_K, Q8_0, F16, F32).
- `ModelFitResult { vramEstimateMb, fit, mode, speedTokensPerSec, score }`:
  - `fit` ∈ {`perfect`, `good`, `cpuOnly`, `tooBig`}; `mode` ∈ {`gpu`, `partial`, `cpu`, `none`}.
  - `perfect` if `vramEstimate <= vramAvailable × 0.9` (fits with headroom) → `mode: gpu`.
  - `good` if `vramEstimate <= vramAvailable × 1.1` (fits tightly) → `mode: gpu` or `partial` near the
    boundary.
  - else `cpuOnly` if `vramEstimate <= ramAvailable` → `mode: cpu`.
  - else `tooBig` → `mode: none`.
  - `speedTokensPerSec` and `score` (0-100) are heuristic estimates derived from `fit`/`mode`/
    `paramsBillions`/`cpuCores` — clearly documented (code comments + UI copy) as estimates, not
    measurements.
- `ModelDiscoveryController` (from issue 003) computes a `ModelFitResult` per result via `FitScorer` using
  the hardware detected on load, and sorts results by `score` descending. Re-search recomputes fit against
  the same hardware snapshot.
- Results table gains VRAM (estimated), SPEED, SCORE, FIT badge, and MODE columns alongside the existing
  MODEL/PARAM/QUANT/CTX from issue 003.

---

## Acceptance criteria

- [ ] Each result row shows VRAM (estimated), SPEED, SCORE, a FIT badge, and MODE.
- [ ] A model+quant whose estimated VRAM comfortably fits the detected VRAM shows FIT = "PERFECT" and
  MODE = GPU.
- [ ] A model+quant that doesn't fit VRAM but fits available RAM shows a CPU-only FIT and MODE = CPU.
- [ ] A model+quant that doesn't fit even available RAM shows a "too big" FIT and MODE indicating it won't
  run.
- [ ] Results are sorted with the highest SCORE first.
- [ ] The UI indicates SPEED/SCORE are estimates, not measured benchmarks.
- [ ] On hardware with no dedicated GPU detected (from issue 003's fallback), FIT/MODE are computed from
  CPU/RAM only and still produce sensible results (no crash, no GPU-mode results).

---

## Tests required

Yes:
- New table-driven `FitScorer` test: for representative (hardware, model) pairs, assert `vramEstimateMb`,
  `fit`, and `mode`. Cover: GPU with ample VRAM (`perfect`), GPU with tight VRAM (`good`), no GPU but enough
  RAM (`cpuOnly`), too big for RAM (`tooBig`), and "no dGPU detected" hardware.
  `speedTokensPerSec`/`score` assertions are limited to "non-negative and ordered consistently with `fit`"
  rather than exact values.
- Extend the `ModelDiscoveryController` test from issue 003: results include `ModelFitResult` and are
  sorted by `score` descending.

---

## Notes

- `FitScorer` is pure (no I/O) — keep it that way for testability.
- Builds directly on issue 003's `HardwareInfo` and `HuggingFaceModelResult`; no changes to either's shape
  beyond consuming them.

---

## Log

_Updated as work progresses._

- Implemented `estimateVramMb`, `FitScorer` (pure, `domain/model/fit_scorer.dart`), `Fit`/`FitMode`/`ModelFitResult`
  (`domain/model/model_fit_result.dart`), and the `ModelDiscoveryResult` wrapper
  (`domain/model/model_discovery_result.dart`). `ModelDiscoveryState.results` is now
  `List<ModelDiscoveryResult>`; `ModelDiscoveryController` scores each search result against the
  detected hardware and sorts by `score` descending on both `load()` and `search()`.
- Extended `HuggingFaceSearchDialog`'s `_ResultsHeader`/`_ResultRow` with VRAM/SPEED/SCORE/FIT
  badge/MODE columns, a `_FitBadge` widget, and an "estimates, not measured benchmarks" caption;
  removed the stale "out of scope for 004/005" doc comments.
- Tests: new `test/features/settings/domain/model/fit_scorer_test.dart` (16 table-driven cases
  covering `estimateVramMb` and all fit/mode classifications incl. no-dGPU hardware, plus
  score/speed ordering); extended `model_discovery_controller_test.dart` with 2 new sort-order
  tests. Full suite: 171/171 passing; `flutter analyze` clean (same 2 pre-existing infos).

QA approved by user on 2026-06-13.
