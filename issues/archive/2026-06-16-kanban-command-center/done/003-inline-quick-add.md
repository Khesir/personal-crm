---
id: issue-003
title: "Inline quick-add: create issues directly from a column"
feature: kanban
status: done
created_at: 2026-06-15
tags: [afk, p1]
---

# [003] Inline quick-add: create issues directly from a column

**Type:** AFK
**Priority:** P1
**Blocked by:** None
**User stories covered:** 7, 8, 9, 10, 11

---

## What to build

Add an inline "+" affordance to each kanban column header. Clicking it opens an inline title input at the top of that column's card list. Pressing Enter with a non-empty title creates a new issue file directly in that column's status folder (e.g. clicking "+" on "Ready" creates the issue in `issues/ready/`), with a generated id and `created_at`. Esc or clicking away cancels without creating anything.

This requires fixing `IssuesRepositoryImpl.createIssue`, which currently always writes into `issues/backlog/` regardless of `issue.status`. Change it to write into the folder matching `issue.status` (via the existing `_statusFolders` map), so quick-add doesn't need a separate create+move.

---

## Acceptance criteria

- [x] Each column header has a "+" control that opens an inline text input at the top of that column's card list.
- [x] Pressing Enter with non-empty text creates a new issue with `status` set to that column's status, written into the matching `issues/<status>/` folder with a generated `id` and `created_at`.
- [x] The new card appears immediately in the correct column without requiring a rescan.
- [x] Esc or losing focus while the input is empty/unchanged cancels the quick-add and closes the input without writing any file.
- [x] `IssuesRepositoryImpl.createIssue` writes into the folder matching the passed-in `issue.status`, not always `backlog/`.

---

## Tests required

Yes:
- Extend `test/features/kanban/data/repository/issues_repository_impl_test.dart` to assert a created issue with `status: ready` (and other statuses) is written into the corresponding folder, not always `backlog/`.
- New widget test asserting Enter with non-empty text calls `IssuesController.createIssue` with the column's status, and Esc/blur does not call it.

---

## Notes

- Visual reference: `kanban-redesign.html` — `.quick-add`, `.col-add`.
- `IssuesController.createIssue` already exists and emits the created issue into local state; no controller interface change expected beyond passing the correct `status`.

---

## Log

_Updated as work progresses._

- Fixed `IssuesRepositoryImpl.createIssue` to write into `_statusFolders[issue.status]` instead of always `backlog/`; extended `issues_repository_impl_test.dart` with a per-status loop covering all five folders.
- Converted `KanbanColumn` to a `StatefulWidget` with a header "+" button (`_AddButton`) and an inline `_QuickAddInput` (TextField + "Enter to create · Esc to cancel" hint) shown at the top of the card list. Enter with non-empty text calls `onCreateIssue(status, title)`; Esc or blur-while-empty closes without calling it. Wired `KanbanSection` (now requires `localPath`) to generate `id`/`created_at` and call `IssuesController.createIssue`. Added `kanban_column_quick_add_test.dart` covering Enter, Esc, and blur-while-empty.
- Pixel-perfect spacing/icon styling of the "+" control and quick-add card vs. `kanban-redesign.html` (`.col-add`, `.quick-add`) is Visual — requires human QA; not covered by automated tests.
- QA approved by user on 2026-06-16.