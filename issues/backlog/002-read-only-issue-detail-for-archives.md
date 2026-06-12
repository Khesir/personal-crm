---
id: issue-002
title: "Read-only issue detail for archived boards"
feature: kanban-archive
status: backlog
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
