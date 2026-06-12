---
id: issue-002
title: "Read-only issue detail for archived boards"
feature: kanban-archive
status: done
created_at: 2026-06-12
tags: [afk, p2]
---

# [002] Read-only issue detail for archived boards

**Type:** AFK
**Priority:** P2
**Blocked by:** 001
**User stories covered:** 12, 13, 14

---

## What to build

When viewing an archived board (from issue 001), clicking an issue card opens the same `IssueDetailSection` used by the live board, but in a read-only mode that prevents any mutation of the frozen archive.

- Card taps in the archived board view open `IssueDetailSection` with `readOnly: true` (the flag plumbed through in issue 001).
- Inside `IssueDetailSection`, when `readOnly` is true:
  - Acceptance-criteria checkboxes render as static, non-tappable indicators (no `updateIssue` call wired).
  - The "Edit" dialog, "Move" status-picker dropdown, and "Run skill" button are not rendered.
- Back navigation from the detail view returns to the archived board (same as the live board's back behavior).

---

## Acceptance criteria

- [ ] Clicking an issue card in an archived board opens its detail view (rendered description, acceptance criteria, frontmatter panel, file path).
- [ ] Acceptance-criteria checkboxes in this view are visually present but not interactive — clicking them does nothing and nothing is persisted.
- [ ] "Edit", "Move", and "Run skill" controls are not shown in this view.
- [ ] Navigating back from the detail view returns to the archived board, not the live board.
- [ ] The live board's `IssueDetailSection` (non-archived) is unaffected — Edit/Move/Run-skill and interactive checkboxes still work as before.

---

## Tests required

No — this is UI wiring (read-only flag controlling which controls render), covered by visual QA per the existing precedent (issue 010) that UI wiring is human-QA territory.

---

## Notes

- Depends on the `readOnly` flag and on-demand archive `IssuesController` introduced in issue 001.

---

## Log

_Updated as work progresses._

- Added `readOnly` (default `false`) to `IssueDetailSection` and `_DetailHeader`; when true, `_DetailHeader` omits `IssueStatusPicker`, the "Run skill" button, and the "Edit" button, and `AcceptanceCriteriaList` is built with `onToggle: null`.
- Made `AcceptanceCriteriaList`/`_CriteriaItem`'s `onToggle` nullable: `onToggle == null` renders a static, disabled `Checkbox` (`onChanged: null`) with no `InkWell` wrapper, so checkboxes are non-interactive (no ripple/hover) and no toggle is ever persisted.
- Wired `_KanbanOrDetail` in `app_shell_screen.dart` to pass `readOnly: readOnly` to `IssueDetailSection` in the detail branch. Verified `KanbanSection`'s `readOnly` remains an inert accepted-but-unused param (no change needed). `flutter analyze` shows only 2 pre-existing unrelated deprecation warnings; full `flutter test` suite passes (94/94).
- Returned to backlog on 2026-06-13 — blocker 001 (archive switching) was rejected in QA and is back in `ready/`, so this read-only detail view can't be visually verified against an archived board yet. Re-test once 001 returns to qa/done.
- Re-verified on 2026-06-13 now that 001 (archive switching) is back in qa/ — confirmed `_KanbanOrDetail` still passes `readOnly: kanbanReadOnly` (true only when `_selectedArchive != null`) through to `IssueDetailSection`, and the archive-controller's `AsyncStreamBuilder` issue lookup (which now relies on 001's fixed `didUpdateWidget` re-subscription) correctly feeds the detail view; no fix needed. `flutter analyze` clean (only the 2 pre-existing `activeColor`/`deprecated_member_use` infos) and `flutter test` passes 112/112.
- QA approved by user on 2026-06-13.
