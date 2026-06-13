---
id: issue-008
title: "Split Local LLM into Engines and Models"
feature: local-llm-engines
status: done
created_at: 2026-06-13
tags: [afk, p2]
---

# [008] Split Local LLM into Engines and Models

**Type:** AFK
**Priority:** P2
**Blocked by:** None
**User stories covered:** 7, 8, 9, 17

---

## What to build

Restructure Settings > Services > Local LLM into two labeled subsections:

- **Engines** — the existing Ollama/Custom Local service cards, shown exactly as today (name, health badge, base URL, edit/delete/refresh/set-default/enable toggle), now under an "Engines" heading.
- **Models** — the existing Hugging Face download tracker list, renamed from "Hugging Face downloads" to "Models". Behavior is otherwise unchanged: live progress for in-progress downloads, "Added" badge for completed ones, error message + dismiss for failed ones, renders nothing when empty.

This is a pure relabeling/regrouping of existing UI — no filtering logic yet (that's issue 009). `HuggingFaceDownloadsSection` is renamed to `LocalLlmModelsSection` (heading text "Hugging Face downloads" → "Models"), and an "Engines" heading is added above the existing card list in the Local LLM category section. "Search Hugging Face" and "Add" buttons remain in the category header, unchanged.

---

## Acceptance criteria

- [ ] Settings > Services > Local LLM shows an "Engines" heading above the Ollama/Custom Local service cards.
- [ ] All existing engine card actions (edit, delete, refresh, set default, enable/disable) continue to work unchanged under "Engines".
- [ ] The Hugging Face downloads list is now headed "Models" instead of "Hugging Face downloads".
- [ ] The "Models" list's behavior (progress, added badge, error + dismiss, empty-state rendering nothing) is unchanged from before the rename.
- [ ] "Search Hugging Face" and "Add" buttons remain in the category header and work as before.

---

## Tests required

No new automated tests beyond a sanity check that the renamed `LocalLlmModelsSection` widget still passes its existing (renamed) test suite under the "Models" heading. Overall composition/placement is flagged for visual QA, consistent with how the rest of this screen has been treated.

---

## Notes

- This is a relabel/regroup only — no new `ServiceType`/`ServiceCategory` values, no data model changes.
- Issue 009 (Engine filter chips) is blocked by this issue because it composes `EngineFilterChips` with `LocalLlmModelsSection`.

---

## Log

_Updated as work progresses._

- Renamed `HuggingFaceDownloadsSection` to `LocalLlmModelsSection` (file moved to `local_llm_models_section.dart`), heading text changed from "Hugging Face downloads" to "Models"; all other behavior unchanged.
- In `services_section.dart`'s `_CategorySection`, added an "Engines" label (styled with `AppStyling.label`, matching the "Models" heading) above the Ollama/Custom Local card `ListView` for the Local LLM category; `LocalLlmModelsSection()` kept in its original position above the engine cards.
- `flutter analyze` clean on both touched files; settings test suite passes except a pre-existing failure in `model_discovery_controller_test.dart` (issue 007 work-in-progress, unrelated to this change — verified by running `service_cards_controller_test.dart` in isolation, which passes).
- QA approved by user on 2026-06-13.
