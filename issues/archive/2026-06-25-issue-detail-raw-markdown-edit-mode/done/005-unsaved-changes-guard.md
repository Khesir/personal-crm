---
id: issue-005
title: "Unsaved-changes guard on Back to board"
feature: issue-edit-mode
status: done
created_at: 2026-06-24
tags: [afk, p2]
---

# [005] Unsaved-changes guard on Back to board

**Type:** AFK
**Priority:** P2
**Blocked by:** 001
**User stories covered:** 11

---

## What to build

When `_editing` is true (built in issue 001) and the raw textarea's current content differs from the value it was seeded with on entering edit mode, clicking the existing "Back to board" breadcrumb (`onBack`) should show a confirm-discard dialog before actually navigating away, instead of discarding silently.

Build this as a new dialog following the same visual/structural pattern as `IssueDeleteDialog` — confirm/cancel modal, explaining that unsaved changes will be lost. Confirming proceeds with `onBack` (discarding the edit); cancelling closes the dialog and keeps the user in edit mode with their text intact.

If the textarea's content is unchanged from what it was seeded with (no edits made), "Back to board" should navigate immediately with no dialog — there's nothing to lose.

Note this is distinct from the "Cancel" button (built in issue 001), which always discards immediately with no confirmation regardless of whether there are unsaved changes — Cancel is already an explicit "discard" action, so it doesn't need this guard.

---

## Acceptance criteria

- [x] Clicking "Back to board" while in edit mode with unsaved changes shows a confirm-discard dialog.
- [x] Confirming the dialog navigates back, discarding the edit.
- [x] Cancelling the dialog keeps the user in edit mode with their typed text intact.
- [x] Clicking "Back to board" while in edit mode with no unsaved changes (textarea unchanged from seed value) navigates immediately, no dialog shown.
- [x] Clicking "Cancel" (not "Back to board") never shows this dialog, regardless of unsaved changes — unaffected by this issue.

---

## Tests required

Yes — widget tests extending `issue_detail_section_test.dart`'s harness:
- Entering edit mode, typing a change, then tapping "Back to board" shows the confirm-discard dialog.
- Confirming the dialog calls `onBack`.
- Cancelling the dialog does not call `onBack` and keeps edit mode active with the typed text still present.
- Entering edit mode without typing any change, then tapping "Back to board" calls `onBack` immediately with no dialog shown.

---

## Notes

- Reuse `IssueDeleteDialog`'s visual pattern for consistency, but this needs its own dialog component since the copy and confirm action are different.
- "Unsaved changes" detection is a simple string-inequality check between the textarea's current text and the value it was seeded with — no diffing or deep comparison needed.

---

## Log

_Updated as work progresses._

- Added `IssueDiscardChangesDialog` (`lib/features/kanban/presentation/dialogs/issue_discard_changes_dialog.dart`), following `IssueDeleteDialog`'s confirm/cancel modal pattern with copy warning that unsaved edits will be lost; confirming pops the dialog then invokes the passed `onConfirm` callback.
- In `_IssueDetailSectionState` (`lib/features/kanban/presentation/section/issue_detail_section.dart`), added `_rawContentSeed` to record the raw text the textarea was seeded with in `_enterEditMode`, a `_hasUnsavedChanges` getter comparing it against `_rawContentController.text`, and `_handleBack` which shows `IssueDiscardChangesDialog` when editing with unsaved changes (confirm calls `widget.onBack`, cancel just closes the dialog) or calls `widget.onBack` directly otherwise. Wired `_DetailHeader`'s `onBack` to `_handleBack` instead of `widget.onBack` directly; the existing `Cancel` button still calls `_cancelEdit` unchanged.
- Tests: 5 new widget tests in `issue_detail_section_test.dart` covering the dialog appearing on unsaved changes, confirm triggering `onBack`, cancel preserving edit mode and typed text, immediate navigation with no unsaved changes, and `Cancel` never showing the dialog. `flutter analyze` clean; `flutter test test/features/kanban` green (118/120) except the 2 pre-existing known failures unrelated to this change (confirmed via git stash comparison against main before this work).

- QA approved by user on 2026-06-25.
