---
id: issue-011
title: "Delete issue (hard delete with confirmation)"
feature: kanban
status: done
created_at: 2026-06-15
tags: [afk, p2]
---

# 011 Delete issue (hard delete with confirmation)

**Type:** AFK
**Priority:** P2
**Blocked by:** None
**User stories covered:** 1, 2, 3, 28

---

## What to build

Add a delete action to the issue detail view that permanently removes the issue's file and its card from the board, after confirmation.

- `IssuesRepository` gains `Future<void> deleteIssue(Issue issue)`, implemented by deleting the issue's underlying file — following the same pattern as `updateIssue`/`moveIssue`.
- `IssuesController` gains `Future<void> deleteIssue(Issue issue)`: calls the repository, then removes the issue from the current in-memory list and re-emits `AsyncData`.
- The issue detail view's header gains a delete action alongside the existing Edit/Move actions.
- Tapping delete opens a confirmation dialog ("Delete issue? This can't be undone." / Cancel / Delete). Confirming calls `IssuesController.deleteIssue` and triggers the existing "back to board" navigation.
- This is a hard delete — no soft-delete, trash, or recovery flow.

---

## Acceptance criteria

- [ ] The issue detail view shows a delete action alongside Edit/Move
- [ ] Tapping delete opens a confirmation dialog before anything is removed
- [ ] Cancelling the dialog leaves the issue and its file untouched
- [ ] Confirming the dialog deletes the issue's underlying file from disk
- [ ] Confirming the dialog removes the issue's card from the board and returns to the board view
- [ ] No trash/recovery UI is added — deletion is permanent

---

## Tests required

Yes — repository-level test (prior art: `issues_repository_impl_test.dart`, temp-directory based): `deleteIssue` removes the issue's file from disk. Controller-level test (prior art: `issues_controller_test.dart`'s `FakeIssuesRepository`): `deleteIssue` calls the repository and removes the issue from the emitted list. Widget test on the issue detail view: delete action shows a confirmation dialog; confirming triggers delete and returns to the board; cancelling leaves the issue untouched.

---

## Notes

Independent of the dock work (issues 008-010) — can be picked up in any order relative to them. See `issues/prd-dock-redesign.md` (Implementation Decision 1).

---

## Log

_Updated as work progresses._

- Added `IssuesRepository.deleteIssue`/`IssuesRepositoryImpl.deleteIssue` (deletes the file at `issue.filePath`) and `IssuesController.deleteIssue` (calls repository, removes the issue from the in-memory list, re-emits `AsyncData`).
- Added `IssueDeleteDialog` ("Delete issue? This can't be undone." / Cancel / Delete) and wired a new "Delete" action into `IssueDetailSection`'s `_DetailHeader` (hidden when `readOnly`); confirming calls `controller.deleteIssue(issue)` then `onBack()`.
- Tests added: repository test (temp-dir, file removed from disk), controller test (`FakeIssuesRepository`, issue removed from emitted list), and 4 widget tests on `IssueDetailSection` (dialog shown, cancel leaves issue untouched, confirm deletes + calls onBack, action hidden when readOnly). `flutter test test/features/kanban` (80 tests) and `flutter analyze lib/features/kanban` both pass.
- QA approved by user on 2026-06-16.
