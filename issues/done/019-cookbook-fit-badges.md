---
id: issue-019
title: "Fit badges in the Home chat model switcher"
feature: cookbook-fit
status: done
created_at: 2026-06-14
tags: [afk, p2]
---

# [019] Fit badges in the Home chat model switcher

**Type:** AFK
**Priority:** P2
**Blocked by:** 018
**User stories covered:** 1, 2 (`prd-agent-capabilities-expansion.md`)

---

## What to build

Show a Fit badge (Perfect/Good/CPU-only/Too big) next to each local model in the Home chat
model switcher, using the `fitResult` computed in issue 018. Extract the existing fit-badge
rendering from the Hugging Face search dialog into a shared `presentation/widget/` component so
both surfaces use identical colors/labels.

---

## Acceptance criteria

- [x] A shared fit-badge widget is extracted from the HF search dialog into a
  `presentation/widget/` component, preserving the existing colors/labels for
  Perfect/Good/CPU-only/Too big.
- [x] The Home chat model switcher renders this badge next to each local `CookbookEntry` using
  its `fitResult`. (Visual — requires human QA)
- [x] `CookbookEntry`s with `fitResult == null` (API entries, unparseable local entries) show no
  badge.
- [x] The HF search dialog is updated to use the shared widget instead of its own copy — no
  duplicated fit-styling remains.

---

## Tests required

Yes — widget test for the shared fit-badge component rendering each `Fit` value. Placement in the
model switcher is covered via `/qa`'s visual checklist.

---

## Notes

- Do not duplicate the switch-on-`Fit` styling between the HF dialog and the switcher — one
  shared widget, two call sites.

---

## Log

_Updated as work progresses._

Extracted the HF search dialog's `_FitBadge` into a public `FitBadge` widget at
`lib/features/settings/presentation/widget/fit_badge.dart` (exported via `settings/api.dart`),
preserving the existing Perfect/Good/CPU-only/Too-big colors and labels. The HF dialog's
`_ResultRow` now uses `FitBadge` directly; the old private copy was removed. `ModelSwitcher`'s
dropdown items now show a `FitBadge` next to the model/card label when `entry.fitResult != null`
(API entries and unparseable local entries show no badge).

Tests: new `fit_badge_test.dart` covers all four `Fit` values (label + color).
`flutter test` → 364 passed, `flutter analyze` clean except 2 pre-existing
`deprecated_member_use` infos.

QA approved by user on 2026-06-14.
