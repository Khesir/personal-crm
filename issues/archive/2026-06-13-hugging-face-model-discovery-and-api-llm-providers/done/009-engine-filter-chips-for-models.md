---
id: issue-009
title: "Engine filter chips for Models"
feature: local-llm-engines
status: done
created_at: 2026-06-13
tags: [afk, p2]
---

# [009] Engine filter chips for Models

**Type:** AFK
**Priority:** P2
**Blocked by:** 007, 008
**User stories covered:** 10, 11, 12, 13, 14, 15, 16, 18

---

## What to build

A horizontal row of engine filter chips above "Models": an "All" chip plus one chip per engine card (label = `card.name`, with a colored dot reusing the existing health-status color mapping for online/offline/error/checking). "All" is selected by default and shows every tracked model, matching today's unfiltered behavior.

Tapping an engine chip filters "Models" to only that engine's downloads (via `HuggingFaceDownload.serviceCardId`, added in issue 007). Tapping "All", or tapping the currently-selected chip again, clears the filter back to "All". If zero engine cards exist, the chip row is hidden entirely and "Models" stays unfiltered. If the currently-selected engine card is deleted, the filter resets to "All" automatically.

The chip/filter pattern is generic over any engine-type `ServiceCard` (currently `ollama` and `customLocal`), not hardcoded to Ollama.

A new stateful composing widget owns the `selectedEngineCardId` state and renders `EngineFilterChips` + `LocalLlmModelsSection(filterServiceCardId: ...)`, wired into the Local LLM category alongside the "Engines" card list from issue 008.

---

## Acceptance criteria

- [ ] With ≥1 engine configured, a chip row renders "All" plus one chip per engine, each labeled with the engine's name and a colored status dot matching its current health status.
- [ ] "All" is selected by default and "Models" shows every tracked download, unchanged from before.
- [ ] Tapping an engine chip filters "Models" to only downloads whose `serviceCardId` matches that engine's `id`.
- [ ] Tapping "All", or tapping the already-selected engine chip again, clears the filter and shows every tracked model.
- [ ] With zero engines configured, the chip row is hidden entirely and "Models" renders unfiltered.
- [ ] If the engine card currently selected as a filter is deleted, the filter resets to "All" (full list shown, no chip highlighted) on the next render.
- [ ] The chip/filter widget works for any engine-type `ServiceCard` (`ollama` and `customLocal`), not just Ollama.

---

## Tests required

Yes — new widget test files, following the `pumpWidget`/`MaterialApp`/`testWidgets` pattern from `test/core/state/stream_builder_widget_test.dart`:

- **`EngineFilterChips`**: renders "All" + one chip per engine card with correct labels; each chip's indicator color matches its `HealthStatus` (online/offline/error/checking); tapping an unselected engine chip calls `onSelect(card.id)`; tapping the selected chip calls `onSelect(null)`; tapping "All" calls `onSelect(null)`.
- **`LocalLlmModelsSection` filtering**: with entries for multiple `serviceCardId`s, `filterServiceCardId: null` renders all non-idle entries (regression check); a non-null `filterServiceCardId` renders only matching entries; renders nothing when the filtered list is empty.
- **Composing widget**: with ≥1 engine, chip row renders and filtering works end-to-end; with zero engines, no chip row and unfiltered "Models"; if the selected engine's card is removed from `engines` on rebuild, filter resets to "All".

---

## Notes

- Depends on `HuggingFaceDownload.serviceCardId` from issue 007 and the "Models"-headed `LocalLlmModelsSection` from issue 008.
- Filter is single-select only ("All" or exactly one engine) — no multi-select.
- Chips are filter-only — engine management (edit/delete/set default etc.) stays on the existing Engine cards from issue 008.
- `customLocal` engines appear in the chip row for consistency, even though downloads can only currently target Ollama (`resolveOllamaCard()` is unchanged).

---

## Log

_Updated as work progresses._

Implemented `EngineFilterChips` (`lib/features/settings/presentation/widget/engine_filter_chips.dart`), added `filterServiceCardId` to `LocalLlmModelsSection`, and added the new `LocalLlmModelsArea` stateful composing widget (`lib/features/settings/presentation/section/local_llm_models_area.dart`), wired into `services_section.dart` for the Local LLM category's `ollama`/`customLocal` engine cards.

Added widget tests: `engine_filter_chips_test.dart` (labels, status-dot colors, tap/toggle behavior), `local_llm_models_section_test.dart` (filter regression + filtering + empty-filter cases), and `local_llm_models_area_test.dart` (end-to-end chip filtering, zero-engine case, filter reset when selected engine card is removed). `flutter test test/features/settings` — 119 tests pass. `flutter analyze` clean on all touched/new files.

QA approved by user on 2026-06-13.
