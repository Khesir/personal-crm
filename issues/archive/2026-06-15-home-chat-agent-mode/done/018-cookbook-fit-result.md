---
id: issue-018
title: "Cookbook fit-result computation for local models"
feature: cookbook-fit
status: done
created_at: 2026-06-14
tags: [afk, p2]
---

# [018] Cookbook fit-result computation for local models

**Type:** AFK
**Priority:** P2
**Blocked by:** None
**User stories covered:** 4 (`prd-agent-capabilities-expansion.md`)

---

## What to build

Attach a `ModelFitResult` to each local `CookbookEntry`, computed from the model's parameter
count + quantization (parsed from its name/tag) against the cached `HardwareInfo`, reusing the
`FitScorer`/`ModelFitResult`/`HardwareInfo` machinery already shipped for Hugging Face model
discovery (Settings → Local LLM → "Search Hugging Face").

This issue is data/computation only — surfacing it in the UI is issue 019, and using it for
default selection is issue 020.

---

## Acceptance criteria

- [x] `CookbookEntry` gains `fitResult: ModelFitResult?` (nullable).
- [x] During `ChatController.refresh()`, for local `CookbookEntry`s, parameter count +
  quantization are parsed from the model name/tag using the existing Hugging Face discovery
  parser (no second parser written).
- [x] `fitResult` is computed via `FitScorer.score` against the cached `HardwareInfo`.
- [x] API LLM `CookbookEntry`s always have `fitResult == null`.
- [x] If a model's name doesn't parse cleanly, or `HardwareInfo` isn't available, `fitResult`
  stays `null` — no error, no badge.
- [x] Hardware detection is not re-run on every `refresh()` — the existing cached `HardwareInfo`
  snapshot is reused.

---

## Tests required

Yes — unit tests for the parse → `FitScorer.score` → `ModelFitResult` pipeline applied to
`CookbookEntry`, covering: a clean local model name (fit computed), an unparseable name
(`fitResult == null`), an API entry (`fitResult == null`), and missing `HardwareInfo`
(`fitResult == null`). Reuse existing `FitScorer`/parsing test fixtures where possible.

---

## Notes

- Reuse parsing from `model_discovery_controller.dart`/`model_discovery_result.dart` and
  `FitScorer`/`ModelFitResult`/`HardwareInfo` from Settings → Hugging Face search — do not
  duplicate.

---

## Log

Extracted the Hugging Face discovery parser's parameter-count/quant regexes into a shared
`ModelNameParser` (`settings/domain/model/model_name_parser.dart`), refactored
`HuggingFaceDatasource` to use it, and gave `ModelFitResult` value equality. Added
`CookbookEntry.fitResult`, and `ChatController._fitResultFor`/`_ensureHardwareInfo` (instance-level
cached `HardwareInfo`, only computed for `ServiceCategory.localLlm` entries) wired into
`refresh()`, with `HardwareInfoRepositoryImpl` injected via `home/di.dart`.

Tests added: `model_name_parser_test.dart` (6 cases), `cookbook_entry_test.dart` fitResult cases
(3), and 4 new `ChatController` tests covering a parseable local model (fitResult computed via
`FitScorer.score`), an unparseable local model (`fitResult == null`), an API LLM entry
(`fitResult == null`), and no `hardwareInfoRepository` configured (`fitResult == null`).

`flutter test` → 345 passed, 0 failed. `flutter analyze` → clean except the 2 pre-existing
`deprecated_member_use` infos.

QA approved by user on 2026-06-14.
