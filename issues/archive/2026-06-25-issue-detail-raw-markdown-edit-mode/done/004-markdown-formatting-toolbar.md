---
id: issue-004
title: "Markdown formatting toolbar"
feature: issue-edit-mode
status: done
created_at: 2026-06-24
tags: [afk, p2]
---

# [004] Markdown formatting toolbar

**Type:** AFK
**Priority:** P2
**Blocked by:** 001
**User stories covered:** 5, 6, 22

---

## What to build

Add a GitHub-style formatting toolbar above the raw textarea built in issue 001: Bold, Italic, Quote, Code, Link, Bulleted list, Numbered list, Task list.

Implement the text-transform logic as a pure helper (e.g. `applyMarkdownAction(text, selection, action) -> (text, selection)`), independent of any widget:
- Bold/Italic/Code: wrap the current selection in the relevant markdown delimiters. If nothing is selected, insert the delimiter pair with a placeholder in between and select the placeholder so the user can start typing immediately.
- Quote/Bulleted list/Numbered list/Task list: prefix each line within the current selection with the relevant marker. If the selection spans multiple lines, every line gets prefixed.
- Link: insert a `[text](url)` template — `text` comes from the current selection (or a placeholder if none), and the `url` portion is selected afterward so the user can immediately type the destination.

Wire each toolbar icon to call the helper with the textarea's current text + selection, then apply the returned text + selection back onto the `TextEditingController`.

---

## Acceptance criteria

- [x] Toolbar with Bold, Italic, Quote, Code, Link, Bulleted list, Numbered list, Task list icons is shown above the raw textarea during edit mode.
- [x] Bold/Italic/Code wrap an existing selection in the correct markdown syntax.
- [x] Bold/Italic/Code with no selection insert delimiters with a placeholder selected, ready to type over.
- [x] Quote/Bulleted list/Numbered list/Task list prefix every line in a multi-line selection.
- [x] Link inserts a `[text](url)` template with the URL portion selected for immediate typing.
- [x] All actions update both the textarea's text and its selection/cursor position correctly (no jumbled cursor placement after an action).

---

## Tests required

Yes — plain unit tests (no Flutter bindings) for the `applyMarkdownAction` helper, following the style of `checklist_toggle_test.dart`:
- Each action tested against: a selection present, no selection (cursor only), and a multi-line selection (for the line-prefixing actions).

Also: lightweight widget tests confirming each toolbar icon is tappable and produces the expected text change in the textarea for at least one representative case per action.

---

## Notes

- This is decorative on top of the core editing capability from issue 001 — the textarea is fully usable without this toolbar; this issue only adds the convenience layer.
- Toolbar actions never touch frontmatter-lock validation (issue 002) — they're pure text edits within whatever the user has selected, same as if they'd typed the markdown by hand.

---

## Log

_Updated as work progresses._

- Added a pure helper `applyMarkdownAction` (`lib/features/kanban/domain/helper/markdown_toolbar_action.dart`) with a `MarkdownToolbarAction` enum (bold, italic, quote, code, link, bulletedList, numberedList, taskList) and `MarkdownActionResult(text, selection)`. Bold/italic/code wrap the selection in delimiters or insert a delimiter pair with a placeholder selected when nothing is selected. Quote/bulleted/numbered/task-list prefix every line spanned by the selection (or just the current line when collapsed), with numbered list incrementing sequentially. Link builds a `[text](url)` template using the selection as link text (or a placeholder) and selects the `url` portion.
- Added `MarkdownFormattingToolbar` (`lib/features/kanban/presentation/widget/markdown_formatting_toolbar.dart`), a row of 8 tappable icon buttons that call `applyMarkdownAction` against the passed-in `TextEditingController`'s current text/selection and apply the result back via `controller.value`. Wired into `IssueEditTabs` directly above the Write tab's `TextField`, shown only while the Write tab is active (hidden in Preview).
- Tests: 20 new pure unit tests in `test/features/kanban/domain/helper/markdown_toolbar_action_test.dart` covering each action with a selection present, no selection (cursor only), and (for line-prefix actions) a multi-line selection. 4 new widget tests in `issue_detail_section_test.dart` (all 8 icons rendered in edit mode, Bold wraps a selection, Bulleted list prefixes the current line, toolbar hidden in Preview tab). `flutter analyze` clean; `flutter test test/features/kanban` green except the 2 pre-existing known failures (unrelated to this change, confirmed via git stash comparison).

- QA approved by user on 2026-06-25.
