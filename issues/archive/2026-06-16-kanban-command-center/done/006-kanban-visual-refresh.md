---
id: issue-006
title: "Kanban visual refresh: AppColors/AppStyling tokens from the mockup"
feature: kanban
status: done
created_at: 2026-06-15
tags: [afk, p2]
---

# [006] Kanban visual refresh: AppColors/AppStyling tokens from the mockup

**Type:** AFK
**Priority:** P2
**Blocked by:** None
**User stories covered:** 34

---

## What to build

Update `KanbanColumn` and `IssueCard` (and the column header) to match the spacing, radii, status-dot colors, and typography shown in `kanban-redesign.html`, using existing `AppColors`/`AppStyling` tokens only. This is a styling-only pass — no new interaction behavior.

If the mockup uses a value that has no equivalent token yet, flag it rather than hardcoding a new color/spacing value.

---

## Acceptance criteria

- [x] Column header shows a status-colored dot, column name, and issue count matching the mockup's spacing/typography.
- [x] Cards use the surface/border/radius tokens shown in the mockup (`.card`, `.card-title`, `.card-feature`, `.tag`, `.card-foot`).
- [x] Status-dot colors per column (Backlog/Ready/In Progress/QA/Done) match `AppColors` status tokens used in the mockup.
- [x] No new hardcoded colors, spacing, or font sizes are introduced — all values reference `AppColors`/`AppStyling`.
- [x] No change to existing drag/quick-add/tap behavior (this issue is visual-only; can land before or after 002/003).

---

## Tests required

No — visual/styling change only, covered by existing widget tests and manual review.

---

## Notes

- Visual reference: `kanban-redesign.html` — `.column`, `.column-head`, `.col-dot`, `.card`, `.card-title`, `.card-feature`, `.tag`, `.card-foot`.
- Independent of the dock/drag-and-drop/quick-add work; can be picked up any time.

---

## Log

- Column radius bumped to `radiusLg`; issue count now rendered as a pill badge (`surfaceRaised` bg, `radiusSm`, `textTertiary`).
- Card background switched to `surfaceElevated` (mockup `.card`); `.card-feature` icon/text and `.card-foot` (id/date) recolored to `textTertiary`/`textFaint`; `.tag` background moved to `surfaceRaised` with `textSecondary` text.
- `flutter analyze` clean on both files; `flutter test test/features/kanban/presentation/widget/` — all 7 tests pass.
- QA approved by user on 2026-06-16.
