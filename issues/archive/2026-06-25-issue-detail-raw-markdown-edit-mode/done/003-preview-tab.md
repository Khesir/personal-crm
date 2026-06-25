---
id: issue-003
title: "Preview tab"
feature: issue-edit-mode
status: done
created_at: 2026-06-24
tags: [afk, p2]
---

# [003] Preview tab

**Type:** AFK
**Priority:** P2
**Blocked by:** 001
**User stories covered:** 3, 4

---

## What to build

Add a Write/Preview tab control above the raw textarea built in issue 001. Write shows the raw textarea (existing behavior). Preview strips the frontmatter block from the *current* raw-text content (reusing the same split logic `IssueFrontmatterParser` uses internally to separate frontmatter from body) and renders only the remaining body through the existing `MarkdownIssueBody` widget — the same rendering used in read mode.

Acceptance-criteria checklists in the preview render as plain markdown (`- [ ]` / `- [x]` as static text), not the interactive toggle widget used in read mode — the source isn't committed yet, so nothing should be toggleable from the preview.

Switching tabs does not lose or alter the textarea's content — Preview is purely a read-only render of whatever's currently typed in Write.

---

## Acceptance criteria

- [ ] A Write/Preview tab control is shown above the editor area while in edit mode.
- [ ] Write tab shows the raw textarea exactly as in issue 001.
- [ ] Preview tab renders the body (frontmatter stripped) via `MarkdownIssueBody`.
- [ ] Preview tab's acceptance-criteria checklist items render as plain non-interactive markdown.
- [ ] Switching between Write and Preview does not modify the textarea's content.
- [ ] If the current raw text fails to parse/split cleanly, Preview falls back to rendering the raw body-guess gracefully rather than crashing (does not need to show a validation error here — that's issue 002's concern on Commit, not Preview).

---

## Tests required

Yes — widget tests extending `issue_detail_section_test.dart`'s harness:
- Typing content in Write and switching to Preview renders the body without the frontmatter block visible.
- Acceptance-criteria items in Preview are not tappable/toggleable.
- Switching back to Write preserves whatever was typed.

---

## Notes

- Reuse `MarkdownIssueBody` as-is — no changes to that widget should be needed, only to what content is fed into it during edit mode's Preview tab.
- This is purely a rendering concern; it does not touch commit/validation logic from issue 002.

---

## Log

_Updated as work progresses._

- Added a Write/Preview tab control (`lib/features/kanban/presentation/widget/issue_edit_tabs.dart`) shown above the editor while in edit mode; `IssueDetailSection` now delegates the editor area to it instead of rendering the textarea inline. Added `IssueFrontmatterParser.splitBody()` to reuse the existing frontmatter-split logic for stripping frontmatter from the live textarea content, falling back to the raw text unchanged if no well-formed frontmatter block is found.
- Preview renders the stripped body through the existing `MarkdownIssueBody` (unmodified) — acceptance-criteria checklists render as plain `- [ ]`/`- [x]` markdown text with no `Checkbox`/toggle, since `AcceptanceCriteriaList` is only used in read mode. Switching tabs never touches the `TextEditingController`'s text, so Write content is preserved across tab switches.
- Tests: 7 new widget tests in `issue_detail_section_test.dart` (tabs visible in edit mode, Write shows raw textarea, Preview strips frontmatter, checklist items are non-interactive plain text, typed content reflected in Preview, round-trip back to Write preserves text, malformed raw text falls back gracefully without throwing). `flutter analyze` clean; `flutter test test/features/kanban` green except the 2 pre-existing known failures (unrelated to this change, confirmed via git stash comparison).
- QA rejected on 2026-06-25. Bug appended — there is no border for the edit and preview mode tab buttons/control.
- Bug fixed on 2026-06-25. Root cause: the unselected `_TabButton` in `issue_edit_tabs.dart` rendered its border with `AppColors.border` (white at ~7% alpha) on a fully transparent background, making it invisible against the app's near-black surfaces. Changed the unselected border to `AppColors.borderStrong` (white at ~13% alpha), matching the stronger-border convention already used elsewhere (`board_dock_section.dart`) when a border needs to read clearly without a filled background; the selected tab's `AppColors.accentLine` border was already sufficiently visible and is unchanged. Added a regression test in `issue_detail_section_test.dart` that inspects the rendered tab buttons' `BoxDecoration.border` and asserts it is not `AppColors.border` for both Write and Preview states.
- Bug fixed again on 2026-06-25 (still not visible per follow-up screenshot). `AppColors.borderStrong` (~13% alpha) was still too faint against the app's near-black surfaces. Switched both tab states to full-opacity colors: unselected now uses `AppColors.textFaint` (solid dark gray), selected uses `AppColors.accent` (solid purple) instead of the semi-transparent `accentLine`. The existing regression test still passes since it only asserts the border is not the near-invisible `AppColors.border`.
- Bug fixed a third time on 2026-06-25 — user clarified the request was for a border around the *whole* editor (GitHub-style), not the individual tab pills. Reworked `IssueEditTabs` to wrap the entire tab bar + toolbar + Write/Preview content in one outer `Container` with a visible `AppColors.borderStrong` border and rounded corners, and added a bottom divider under the tab/toolbar row to separate it from the content area, matching GitHub's comment-box layout. The toolbar now sits inline with the tabs in that header row instead of on its own line. Individual tab pills now only show a border when selected (`AppColors.accent`); the unselected pill relies on the surrounding panel border instead of its own. Replaced the old per-pill-border regression test with one asserting the outer panel's `BoxDecoration.border` is `AppColors.borderStrong` and the tab-bar's bottom divider is also `AppColors.borderStrong`. `flutter analyze` clean; `flutter test test/features/kanban` → 121 tests, same 2 pre-existing unrelated failures.

## Bug

**Reported:** 2026-06-25
**Found during:** Visual QA
**Description:** There is no border for the edit and preview mode tab buttons/control.

### What to fix
_To be investigated during implementation._

### Acceptance Criteria
- [x] Bug no longer reproduces
- [x] Original acceptance criteria still met
- [x] A test exists that would have caught this

- QA approved by user on 2026-06-25.
