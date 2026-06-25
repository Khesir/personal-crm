# PRD: Issue Detail — Raw Markdown Edit Mode

**Status:** Draft
**Date:** 2026-06-24

---

## Problem Statement

Today, editing an issue means opening a modal (`IssueEditDialog`) with separate Title/Feature/Tags/Body fields. The body field only holds the body text — frontmatter (id, status, created_at) is invisible and untouchable from the UI. This works for small tweaks, but anyone who wants to restructure an issue's markdown (rework the Description/Acceptance Criteria layout, fix formatting, copy-paste a chunk from another issue) is stuck retyping inside a cramped multi-line text field with no preview, no formatting help, and no view of the file as it actually exists on disk.

## Solution

Replace the modal with an inline raw-markdown editor inside `IssueDetailSection` itself. Clicking "Edit" swaps the detail view into a Write/Preview editor over the issue's *entire* file contents (frontmatter included), with a GitHub-style formatting toolbar. Write shows the raw source; Preview strips the frontmatter and renders the body the same way the read view does. Committing overwrites the file with exactly what's in the textarea, validates it, and re-parses it back into the issue list. The right-hand metadata panel stays visible but frozen on last-saved values until a successful commit, so the user always has a stable reference of "what's currently saved" while editing.

`id`, `created_at`, and `status` are locked — editing those lines in the textarea blocks the commit with an inline error, since they're either the file's stable identity, immutable provenance, or (in the case of `status`) derived from which folder the file lives in rather than from the YAML itself today.

---

## User Stories

1. As a user, I want to click "Edit" on an issue and get a raw markdown editor over the whole file, so that I can restructure the issue's content freely instead of being limited to separate form fields.
2. As a user, I want a "Write" tab showing the raw markdown source, so that I can see and edit exactly what will be saved to disk.
3. As a user, I want a "Preview" tab that renders the body as it will actually display, so that I can check my formatting before committing.
4. As a user, I want the Preview tab to ignore the frontmatter block, so that I don't see a garbled rendering of YAML as markdown.
5. As a user, I want a formatting toolbar (Bold, Italic, Quote, Code, Link, Bulleted list, Numbered list, Task list), so that I don't have to hand-type markdown syntax for common formatting.
6. As a user, I want toolbar actions to wrap my current selection (or insert a sensible template if nothing is selected), so that the toolbar behaves the way every other markdown editor I've used behaves.
7. As a user, I want the right-hand metadata panel (status, feature, tags, created date, frontmatter, file path) to stay visible while I edit, so that I have a reference point for what's currently saved.
8. As a user, I want that panel to stay frozen on the last-saved values while I'm mid-edit, so that I'm not confused by a panel that flickers or shows invalid data while I'm still typing.
9. As a user, I want the page title row to disappear while editing, so that I'm not looking at a redundant, possibly-stale copy of the title I'm actively editing inside the textarea.
10. As a user, I want a "Cancel" button that discards my edits immediately, so that backing out of an edit is fast when I know I don't want to keep it.
11. As a user, I want a confirmation dialog if I click "Back to board" while I have unsaved edits, so that I don't lose work by an incidental click.
12. As a user, I want a "Commit changes" button that saves my edits, so that I have an explicit, deliberate save action.
13. As a user, I want commit to fail with a clear inline error (not a silent no-op or a corrupted file) if my edited text doesn't parse as valid frontmatter + body, so that I never end up with an issue that silently disappears from the board.
14. As a user, I want commit to fail with a clear inline error if I've changed the `id` field, so that I can't accidentally rename an issue's identity through a text edit.
15. As a user, I want commit to fail with a clear inline error if I've changed the `created_at` field, so that I can't accidentally corrupt the issue's history.
16. As a user, I want commit to fail with a clear inline error if I've changed the `status` field, so that I don't get a confusing experience where I type a new status and nothing visibly changes (since status is actually controlled by the issue's folder, not its frontmatter text).
17. As a user, I want to freely edit `title`, `feature`, `tags`, and `body` in the raw text, so that I have full control over everything that's actually meaningful to edit.
18. As a user, I want a successful commit to exit edit mode and show the updated issue in read view, so that I get immediate confirmation my changes were saved.
19. As a user, I want the Commit button to show a loading state and be disabled while saving, so that I can't double-submit or lose track of whether my save went through.
20. As a developer, I want the modal `IssueEditDialog` removed entirely once this ships, so that there's only one way to edit an issue and no duplicated/divergent editing logic.
21. As a developer, I want the raw-edit validation logic (parse + locked-field check) as a pure, testable helper, so that I can unit test every failure mode without spinning up widgets.
22. As a developer, I want the markdown toolbar's text-transform logic as a pure, testable helper, so that I can unit test wrapping/insertion behavior independent of the UI.
23. As a user, I want this editor to respect the existing read-only archive mode, so that I can't enter edit mode while viewing an archived/read-only board.

---

## Implementation Decisions

- **`IssueDetailSection` becomes stateful.** It now owns: an `_editing` flag, a raw-text `TextEditingController` seeded from the issue's current full file contents on entering edit mode, a Write/Preview tab selection, and an inline validation-error message (nullable).
- **Entering edit mode**: clicking "Edit" reads the issue's full file contents (frontmatter + body) and seeds the raw-text controller, defaulting to the Write tab. The header swaps from (status picker, Edit, Delete) to (Cancel, Commit changes) and the title row is hidden. The `IssueMetadataPanel` stays mounted, displaying the *pre-edit* `Issue` object until a commit succeeds.
- **Preview tab**: strips the frontmatter block from the current raw-text content (reusing the same split logic `IssueFrontmatterParser` uses internally) and renders only the remaining body through the existing `MarkdownIssueBody` widget. Acceptance-criteria checklists render as plain markdown here — not the interactive toggle widget — since the source isn't committed yet.
- **Formatting toolbar**: GitHub's standard action set — Bold, Italic, Quote, Code, Link, Bulleted list, Numbered list, Task list. Each action is implemented via a new pure helper (see Testing Decisions) that takes the current text + selection + an action identifier, and returns new text + new selection. Bold/Italic/Code wrap the current selection (or insert placeholder + select it, if nothing is selected); Quote/Bulleted list/Numbered list/Task list prefix each selected line; Link inserts a `[text](url)` template with `text` taken from the selection (or a placeholder) and the `url` portion selected for immediate typing.
- **Commit flow**:
  1. Run the raw text through `IssueFrontmatterParser.parse()` (or equivalent) to get a candidate `Issue`. If parsing fails (returns null), show an inline error and abort — no write to disk.
  2. Compare the candidate's `id`, `createdAt`, and `status` against the original issue. If any differ, show an inline error naming the locked field and abort — no write to disk.
  3. If valid, overwrite the issue's file on disk with the raw text exactly as typed (direct overwrite, not a surgical field-by-field rewrite via `IssueFrontmatterWriter`).
  4. Re-read and re-parse the file from disk to get the canonical updated `Issue` (status is supplied from the file's folder location, same as every other read path), and replace it in the controller's in-memory list.
  5. Exit edit mode back to read view, now showing the refreshed issue.
- **New repository method**: `IssuesRepository.updateIssueRaw(Issue issue, String rawContent)` — overwrites the file at `issue.filePath` with `rawContent`, then re-reads and re-parses it to return the canonical `Issue`. Implemented in `IssuesRepositoryImpl` alongside the existing `updateIssue`/`moveIssue`/`deleteIssue` methods.
- **New controller method**: `IssuesController.updateIssueRaw(Issue issue, String rawContent)` — calls the repository method and replaces the issue in state, mirroring the existing `updateIssue`/`moveIssue` pattern (`_replaceIssue`).
- **Locked-field validation lives in a pure helper**, not inline in the widget or controller — something like a `validateIssueRawEdit(Issue original, String rawContent)` that returns either the successfully parsed `Issue` or a typed failure (parse error vs. specific locked-field-changed error), so the widget can map the failure to the right inline message and the controller/repository only ever receive already-validated content.
- **Discard behavior**: "Cancel" exits edit mode immediately, discarding the raw-text controller's contents, no confirmation. "Back to board" (the existing `onBack` breadcrumb action) while `_editing` is true and the raw text differs from the seeded value shows a confirm-discard dialog (new dialog, following the same visual/structural pattern as `IssueDeleteDialog`) before actually navigating back; declining the dialog keeps the user in edit mode with their text intact.
- **Read-only mode**: when `readOnly` is true (archived board), the Edit action is not shown at all — this already matches the current header's `if (!readOnly)` gating and needs no new logic, just confirming the new edit-mode entry point respects it the same way.
- **`IssueEditDialog` and its dialog plumbing are deleted** once the inline editor ships — including its test file and its call site in `IssueDetailSection`.

---

## Testing Decisions

Tests should assert on observable behavior (what gets written to disk, what the controller's state becomes, what the user sees), not on internal implementation details like which private method was called.

- **`validateIssueRawEdit` (new pure helper, `domain/helper/`)**: plain unit tests (no Flutter bindings), following the style of `checklist_toggle_test.dart`/`acceptance_criteria_parser_test.dart`. Cover: valid edit passes through; malformed frontmatter/body fails with a parse error; `id` changed fails with the locked-field error; `createdAt` changed fails; `status` changed fails; `title`/`feature`/`tags`/`body` changes all pass through untouched by validation.
- **Markdown toolbar helper (new pure helper, `domain/helper/`)**: plain unit tests, same style. Cover each action (Bold, Italic, Quote, Code, Link, Bulleted list, Numbered list, Task list) against: a selection present, no selection (cursor only), and a multi-line selection (for the line-prefixing actions).
- **`IssuesRepositoryImpl.updateIssueRaw`**: integration-style tests against real temp directories, following `issues_repository_impl_test.dart`'s existing pattern (`Directory.systemTemp.createTempSync`) — write a fixture file, call `updateIssueRaw`, assert the file's new contents on disk and the returned `Issue`'s fields.
- **`IssuesController.updateIssueRaw`**: unit tests against `FakeIssuesRepository`, following `issues_controller_test.dart`'s existing pattern — assert the repository receives the right arguments and the controller's in-memory list reflects the replaced issue.
- **`IssueDetailSection` edit mode**: widget tests extending `issue_detail_section_test.dart`'s existing harness (`tester.pumpWidget` with a real `IssuesController` + `FakeIssuesRepository`). Cover: tapping Edit enters edit mode and hides the title row; typing in the Write tab and switching to Preview renders the body without frontmatter; tapping Commit with valid text calls through to the controller and returns to read view; tapping Commit with invalid text (or a locked-field change) shows an inline error and does not call the controller; tapping Cancel discards and returns to read view without calling the controller; tapping "Back to board" with unsaved changes shows the confirm-discard dialog, and declining it keeps edit mode active; Edit is not rendered at all when `readOnly` is true.

---

## Out of Scope

- Live-updating the metadata panel as the user types (it stays frozen until commit, per the earlier decision).
- Allowing `status` changes in the raw editor to actually move the file between status folders — status remains folder-derived and locked from this editor.
- Allowing `id`/`created_at` to be intentionally changed through any UI (renaming an issue's identity or correcting its creation date is out of scope entirely, not just for this editor).
- Autosave or draft recovery across app restarts/navigation away and back.
- Keyboard shortcuts (e.g. Ctrl+S to commit) — not requested, can be a later enhancement.
- Changes to the issue *creation* flow — this PRD only covers editing existing issues.
- Any change to how `moveIssue` (drag-and-drop / status picker) works — that path is untouched.

---

## Further Notes

- The metadata panel (`IssueMetadataPanel`) needs no changes — it already renders status pill, feature, tags, created date, raw frontmatter, and file path, which matches the design reference image's right-side panel almost exactly.
- The design reference image (`Issue detail.png`) is modeled closely on GitHub's issue/PR comment editor (Write/Preview tabs, similar toolbar icon set, dark theme) — when in doubt about an interaction detail not explicitly decided here, GitHub's own editor behavior is the right tiebreaker to default to.
- `IssueFrontmatterWriter`'s surgical per-field rewrite is *not* reused by this feature — it remains in place for any other caller, but raw-edit commits go through a direct overwrite + re-parse instead.
