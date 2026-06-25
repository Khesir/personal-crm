---
id: issue-002
title: "Commit validation guardrails (parse failures + locked fields)"
feature: issue-edit-mode
status: done
created_at: 2026-06-24
tags: [afk, p1, something]
---

# [002] Commit validation guardrails (parse failures + locked fields)

**Type:** AFK
**Priority:** P1
**Blocked by:** 001
**User stories covered:** 13, 14, 15, 16, 21

---

## What to build

Add a pure helper, e.g. `validateIssueRawEdit(Issue original, String rawContent)`, that returns either the successfully parsed `Issue` or a typed failure reason. Wire it into the Commit flow built in issue 001, ahead of the actual file write.

Validation steps, in order:
1. Run `rawContent` through the same parsing logic `IssueFrontmatterParser` uses. If it fails to parse (missing `id`/`title`, broken frontmatter delimiters, invalid YAML), fail with a parse-error reason.
2. If it parses, compare the candidate's `id`, `createdAt`, and `status` against `original`'s. If any of the three differ, fail with a specific locked-field reason naming which field changed.
3. Otherwise, succeed with the parsed `Issue`.

The widget maps a failure to an inline error message shown in the editor (not a dialog — inline, near the textarea) and aborts the commit: no file write, no controller call, edit mode stays open with the user's text intact so they can fix it.

Rationale for locking `status`: it isn't actually read from YAML today — `IssueFrontmatterParser.parse(contents, status, filePath)` takes status as a parameter derived from which folder the file lives in. If we let a `status:` text edit through silently, the user would see no actual effect (the pill would still show the old status), which is more confusing than just blocking it outright.

---

## Acceptance criteria

- [ ] Raw text that fails to parse blocks commit with an inline error; no file is written.
- [ ] Raw text where `id` differs from the original blocks commit with an inline error naming `id`; no file is written.
- [ ] Raw text where `created_at` differs from the original blocks commit with an inline error naming `created_at`; no file is written.
- [ ] Raw text where `status` differs from the original blocks commit with an inline error naming `status`; no file is written.
- [ ] Raw text that changes `title`, `feature`, `tags`, and/or `body` (with `id`/`created_at`/`status` unchanged) passes validation and proceeds to commit as in issue 001.
- [ ] After a blocked commit, edit mode remains open with the user's typed text untouched, so they can correct it and retry.

---

## Tests required

Yes — plain unit tests (no Flutter bindings) for `validateIssueRawEdit`, following the style of `checklist_toggle_test.dart`/`acceptance_criteria_parser_test.dart`:
- Valid edit (title/feature/tags/body changed, locked fields unchanged) passes through with the parsed `Issue`.
- Malformed frontmatter/body fails with a parse-error reason.
- `id` changed fails with the locked-field reason for `id`.
- `createdAt` changed fails with the locked-field reason for `created_at`.
- `status` changed fails with the locked-field reason for `status`.

Also: widget tests extending `issue_detail_section_test.dart` — tapping Commit with invalid text (malformed and each locked-field case) shows the right inline error and does not call the controller.

---

## Notes

- This helper sits in `domain/helper/`, independent of the controller and repository — the controller/repository should only ever receive already-validated content from the widget.
- Out of scope (per PRD): allowing `status` edits to actually move the file between folders. Locked means locked, full stop, for this feature.

---

## Log

_Updated as work progresses._

- Added pure helper `validateIssueRawEdit` (`lib/features/kanban/domain/helper/issue_raw_edit_validator.dart`) returning a sealed `IssueRawEditResult` (`IssueRawEditSuccess`/`IssueRawEditFailure` with `IssueRawEditFailureReason` enum: parseError, idChanged, createdAtChanged, statusChanged). Status comparison reads the raw `status:` YAML text directly since the parser takes status as a folder-derived parameter and can never disagree with itself.
- Wired validation into `IssueDetailSection._commitEdit()`: failures set `_commitError` and abort before calling the controller; edit mode stays open with text intact. Inline error rendered above the textarea using `AppStyling.bodySm.copyWith(color: AppColors.error)`. Error clears on entering/cancelling edit mode and on a successful commit.
- Tests: 5 new unit tests in `test/features/kanban/domain/helper/issue_raw_edit_validator_test.dart` (valid edit, parse error, id/created_at/status changed). 4 new widget tests in `issue_detail_section_test.dart` for the same failure cases, plus updated the existing happy-path test to use valid frontmatter content. `flutter analyze` clean; `flutter test test/features/kanban` green except the 2 pre-existing known failures (unrelated to this change).

- QA approved by user on 2026-06-25.
