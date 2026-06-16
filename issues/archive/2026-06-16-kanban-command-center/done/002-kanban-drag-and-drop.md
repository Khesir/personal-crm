---
id: issue-002
title: "Drag-and-drop kanban cards between columns"
feature: kanban
status: done
created_at: 2026-06-15
tags: [afk, p1]
---

# [002] Drag-and-drop kanban cards between columns

**Type:** AFK
**Priority:** P1
**Blocked by:** None
**User stories covered:** 1, 2, 3, 4, 5, 6

---

## What to build

Make kanban cards draggable between columns. Dropping a card on another column updates the issue's status end-to-end: UI drag gesture → drop target accepts → `IssuesController.moveIssue` → `IssuesRepository.moveIssue` moves the `.md` file to the new status folder and rewrites its `status:` frontmatter → board reflects the new column.

Visual feedback during drag:
- The dragged card lifts (shadow, slight scale/rotation) per the mockup's `.card.lifted` styling.
- A dashed placeholder shows where the card will land in the target column.
- Column counts update immediately on drop.

Error handling: if `repository.moveIssue` throws, the controller reverts local state to the pre-drag list and the card returns to its original column (with a transient inline error indicator).

---

## Acceptance criteria

- [x] Cards can be dragged from any column and dropped into any other column using mouse-based pointer input.
- [x] During drag, the card shows lift styling (shadow/scale) consistent with the mockup.
- [x] A drop placeholder appears in the target column indicating landing position.
- [x] On drop, `IssuesController.moveIssue(issue, newStatus)` is called and the card moves to the target column in the UI.
- [x] Column counts update immediately after a successful move.
- [x] If the underlying file move fails, the card returns to its original column and an error is surfaced to the user.
- [x] Reordering within the same column is not required (only cross-column status changes).

---

## Tests required

Yes:
- Extend `test/features/kanban/domain/controller/issues_controller_test.dart` with a case asserting `moveIssue` reverts local state when `repository.moveIssue` throws.
- New widget test for `KanbanColumn`/`IssueCard` simulating a drag into another column's drop target, asserting `IssuesController.moveIssue` is called with the correct target status.

---

## Notes

- Visual reference: `kanban-redesign.html` — `.card.dragging`, `.card.lifted`, `.drop-placeholder`.
- `IssuesController.moveIssue` and `IssuesRepository.moveIssue` already exist and require no interface changes — this issue is primarily UI wiring + the optimistic-update/revert behavior in the controller.

---

## Log

_Updated as work progresses._

- Implemented cross-column drag-and-drop using `Draggable<Issue>`/`DragTarget<Issue>` in `IssueCard`/`KanbanColumn`. `KanbanColumn` calls `onMoveIssue(issue, status)`, wired in `KanbanSection` to `IssuesController.moveIssue`.
- `IssuesController.moveIssue` now optimistically updates state, reverts to the pre-drag list on `repository.moveIssue` failure, and emits to a new `moveError` stream consumed by `KanbanSection` to show a `SnackBar`.
- Tests: extended `issues_controller_test.dart` with a revert-on-error case (49/49 kanban tests pass); added `test/features/kanban/presentation/widget/kanban_column_drag_test.dart` simulating a pointer drag from one column to another, asserting `onMoveIssue` is called with the target status. `flutter analyze lib/features/kanban/` is clean.
- Lift styling (shadow/scale/rotation feedback widget) and the dashed drop placeholder are implemented per the mockup's `.card.lifted`/`.drop-placeholder` but are visual-only and require human visual QA — not covered by automated tests.
- QA approved by user on 2026-06-16.