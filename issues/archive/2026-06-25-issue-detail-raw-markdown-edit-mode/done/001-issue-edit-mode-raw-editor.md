---
id: issue-001
title: "Issue edit mode — raw editor with happy-path commit/cancel"
feature: issue-edit-mode
status: done
created_at: 2026-06-24
tags: [afk, p1]
---

# [001] Issue edit mode — raw editor with happy-path commit/cancel

**Type:** AFK
**Priority:** P1
**Blocked by:** None
**User stories covered:** 1, 2, 7, 8, 9, 10, 12, 17, 18, 19, 20, 23

---
asdasd
## What to build

Replace the `IssueEditDialog` modal entirely with an inline raw-markdown editor inside `IssueDetailSection`.

`IssueDetailSection` becomes stateful, owning an `_editing` flag and a raw-text `TextEditingController`. Clicking "Edit":
- Reads the issue's full file contents (frontmatter + body) and seeds the raw-text controller with it.
- Hides the page-title row.
- Swaps the header's status picker/Edit/Delete buttons for Cancel and Commit changes.
- The `IssueMetadataPanel` stays mounted and continues to display the issue as it currently is — it's bound to the stable `issue` prop, which doesn't change until a commit actually succeeds and the parent re-renders with the refreshed issue, so no special "freeze" logic is needed here, just don't introduce anything that would update it early.

"Cancel" exits edit mode immediately, discarding the textarea's contents — no confirmation needed (that's a different issue).

"Commit changes" (happy path only — assume valid input for this slice; full validation guardrails are a separate issue):
1. Calls a new `IssuesRepository.updateIssueRaw(Issue issue, String rawContent)` — overwrites the file at `issue.filePath` with the raw text exactly as typed, then re-reads and re-parses it from disk to return the canonical `Issue` (status comes from the file's folder location, same as every other read path).
2. Calls a new `IssuesController.updateIssueRaw(Issue issue, String rawContent)` that calls the repository method and replaces the issue in state, mirroring the existing `updateIssue`/`moveIssue` pattern (`_replaceIssue`).
3. While the write is in flight, the Commit button shows a loading state and is disabled (no double-submit).
4. On success, exits edit mode back to read view, now showing the refreshed issue.

The existing `readOnly` archive-mode gating (`if (!readOnly)` in the header) must continue to hide the Edit entry point entirely — no new logic needed here beyond making sure the new edit-mode toggle respects the same flag.

Once this lands, delete `IssueEditDialog`, its dialog plumbing, its call site in `IssueDetailSection`, and its test file.

---

## Acceptance criteria

- [x] Clicking "Edit" enters edit mode: title row hidden, Write-tab raw textarea shown seeded with the issue's full file contents, header shows Cancel + Commit changes (no status picker, no Delete).
- [x] `IssueMetadataPanel` remains visible during edit mode, showing the pre-edit issue's data.
- [ ] Clicking "Cancel" exits edit mode immediately with no write to disk and no confirmation dialog.
- [ ] Clicking "Commit changes" with valid raw text overwrites the file on disk with exactly the typed content, re-parses it, updates the controller's in-memory list, and returns to read view showing the updated issue.
- [ ] Commit button shows a loading state and is disabled while the write is in progress.
- [ ] Edit mode is not reachable at all when `readOnly` is true.
- [ ] `IssueEditDialog` and its test file are deleted; nothing in the codebase references it anymore.

---

## Tests required

Yes — widget tests extending `issue_detail_section_test.dart`'s existing harness (`tester.pumpWidget` with a real `IssuesController` + `FakeIssuesRepository`):
- Tapping Edit enters edit mode and hides the title row.
- Tapping Commit with valid text calls through to the controller with the right arguments and returns to read view with the updated issue rendered.
- Tapping Cancel discards and returns to read view without calling the controller.
- Edit is not rendered at all when `readOnly` is true.

Also: `IssuesRepositoryImpl.updateIssueRaw` integration tests against real temp directories (`issues_repository_impl_test.dart`'s existing `Directory.systemTemp.createTempSync` pattern) — write a fixture file, call `updateIssueRaw`, assert the file's new contents on disk and the returned `Issue`'s fields.

Also: `IssuesController.updateIssueRaw` unit tests against `FakeIssuesRepository` (`issues_controller_test.dart`'s existing pattern) — assert the repository receives the right arguments and the controller's in-memory list reflects the replaced issue.

---

## Notes

- `IssueFrontmatterWriter`'s surgical per-field rewrite is NOT reused here — this is a direct overwrite + re-parse, not a field-by-field rewrite. Leave `IssueFrontmatterWriter` in place for its other existing callers.
- This slice intentionally skips validation (parse failures, locked-field checks) — that's issue 002. Assume happy-path input for this slice's acceptance criteria.
- This slice intentionally skips the Preview tab, the formatting toolbar, and the unsaved-changes guard on "Back to board" — those are issues 003, 004, and 005.

---

## Log

_Updated as work progresses._

- Added `IssuesRepository.updateIssueRaw` / `IssuesRepositoryImpl.updateIssueRaw` (overwrite + re-parse) and `IssuesController.updateIssueRaw` (delegates, replaces in state via `_replaceIssue`).
- Converted `IssueDetailSection` to `StatefulWidget` with `_editing`/`_committing` state; "Edit" reads the file synchronously (`readAsStringSync`) to seed a raw-text `TextEditingController`, header swaps to Cancel/Commit changes, body swaps to a mono `TextField`; "Commit changes" shows a loading spinner and calls `controller.updateIssueRaw`. Deleted `IssueEditDialog` (no test file existed for it) and its call site.
- Tested: repository integration test (overwrite + re-parse against temp dir), controller unit test (delegates + state replace), and four widget tests (enter edit mode hides title, commit calls controller and returns to read view, cancel discards without calling controller, Edit hidden when readOnly). `flutter analyze` clean; `flutter test` full suite has only 2 pre-existing failures unrelated to this change (verified via `git stash` on main before this work).
- QA approved by user on 2026-06-25.
