# QA Report

_Date: 2026-06-25_

---

## Automated QA Results

| Issue | Title | Build | Tests Pass | Test Quality | Lint | Code Review | Result |
|-------|-------|-------|------------|--------------|------|-------------|--------|
| [001](qa/001-issue-edit-mode-raw-editor.md) | Issue edit mode — raw editor with happy-path commit/cancel | ✅ | ✅ | ✅ | ✅ | ⚠️ | Pass |
| [002](qa/002-commit-validation-guardrails.md) | Commit validation guardrails (parse failures + locked fields) | ✅ | ✅ | ✅ | ✅ | ⚠️ | Pass |
| [003](qa/003-preview-tab.md) | Preview tab | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [004](qa/004-markdown-formatting-toolbar.md) | Markdown formatting toolbar | ✅ | ✅ | ✅ | ✅ | ⚠️ | Pass |
| [005](qa/005-unsaved-changes-guard.md) | Unsaved-changes guard on Back to board | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |

**Build**: `flutter analyze` is clean for the whole project. A full platform build was not run (time cost); the widget/unit test suite compiles and executes the full editor stack (state, dialogs, controller, repository), which is taken as a sufficient compile-correctness signal.

**Tests Pass**: `flutter test test/features/kanban` → 118 passed, 2 failed. Both failures (a kanban-column drag test and a delete-confirmation test) were independently reproduced via `git stash` against `main` *before* any of this session's changes — confirmed pre-existing and unrelated to issues 001–005.

**Test Quality**: All new tests across all five issues use the widget's public interface (`tester.pumpWidget`, tap/enter-text/find-text) or a pure function's public signature. Test names describe user-observable behavior ("tapping Commit with id changed shows an inline error and blocks commit", "switching back to Write preserves the typed content") rather than implementation. No internal mocking, no private-method testing, no call-count assertions found.

---

## Issues with automated failures

None. All five issues pass build, tests, lint, and acceptance criteria. The findings below are non-blocking style notes surfaced during code review.

**Minor/non-blocking note — affects issues 001, 002, 004 (one shared pattern, not independent problems):**
Several of the newly added pure-helper files carry dartdoc-style explanatory comment blocks above their public functions/types. The project's own coding standard (`CLAUDE.md`) states comments/dartdoc should not be added unless explicitly requested. This doesn't affect correctness or test coverage, and the rest of the codebase has mixed precedent (the repository interface already carries similar doc comments), but it's worth a deliberate decision rather than letting it ride by convention drift — either strip the new comments for consistency with the "no comments" rule, or treat doc comments on public domain helpers as an accepted exception going forward.

These are style observations only and do not block sign-off.

---

## Visual QA Checklist

## Visual QA — [001] Issue edit mode — raw editor with happy-path commit/cancel

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Entering edit mode | Open any issue, click "Edit" | Page title disappears, header buttons swap from status-picker/Edit/Delete to Cancel/Commit changes, the metadata panel on the right stays visible and unchanged |
| 2 | Committing a valid edit | While editing, click "Commit changes" | Button shows a brief loading spinner and is not clickable again during the save; on success the view returns to read mode showing the updated content |
| 3 | Cancelling an edit | While editing (with or without changes), click "Cancel" | Returns to read mode immediately, no dialog, edit is discarded |
| 4 | Read-only mode | Open an issue from a read-only/archived board | No "Edit" button is present anywhere in the header |

**Edge cases to manually test:**
- [ ] Start an edit, then commit with no actual changes made — should succeed and return to read view normally
- [ ] Trigger a slow save (e.g. large file) and confirm the Commit button can't be double-clicked while loading

---

## Visual QA — [002] Commit validation guardrails (parse failures + locked fields)

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Malformed edit | While editing, break the frontmatter block (e.g. delete a `---` line), click Commit | An inline error appears near the editor (not a popup dialog); edit mode stays open with your text untouched |
| 2 | Locked-field edit | While editing, change the `id`, `created_at`, or `status` value in the frontmatter, click Commit | Inline error names the specific locked field that was changed; no file is written; text stays as typed |
| 3 | Valid edit alongside a locked field | Change `title`/`feature`/`tags`/body text only, click Commit | Commit succeeds normally, same as issue 001's happy path |

**Edge cases to manually test:**
- [ ] Trigger a parse error, fix it without leaving edit mode, then commit successfully — error message should clear
- [ ] Confirm the error text is readable against the background and doesn't overlap other UI

---

## Visual QA — [003] Preview tab

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Tab control appearance | Enter edit mode | A "Write" / "Preview" tab control appears above the editor; the active tab is visually distinguished (highlighted/bordered) from the inactive one |
| 2 | Preview rendering | Type some markdown in Write (headings, bold, a checklist item like `- [ ] foo`), switch to Preview | Frontmatter block is not shown; markdown renders formatted (not raw text); checklist items show as plain `- [ ] foo` / `- [x] foo` text, not as clickable checkboxes |
| 3 | Round-trip | Type text, switch to Preview, switch back to Write | The exact text you typed is still there, cursor/content unchanged |
| 4 | Malformed content in Preview | Break the frontmatter while in Write, switch to Preview anyway | Preview shows some reasonable fallback rendering of the text — it must not crash or show a blank/broken screen |

**Edge cases to manually test:**
- [ ] Switch to Preview with an empty body — should render without error
- [ ] Switch to Preview, then directly to Commit without going back to Write — Commit should still operate on the real Write content, not the Preview rendering

---

## Visual QA — [004] Markdown formatting toolbar

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Toolbar appearance | Enter edit mode, Write tab active | A row of 8 icons (Bold, Italic, Quote, Code, Link, Bulleted list, Numbered list, Task list) appears above the textarea; hovering shows a tooltip naming each action |
| 2 | Toolbar visibility per tab | Switch to Preview tab | Toolbar is hidden while in Preview, reappears when switching back to Write |
| 3 | Wrap actions with a selection | Select some text, click Bold (then separately Italic, then Code) | Selected text becomes wrapped in `**`/`*`/`` ` `` and stays selected/highlighted afterward |
| 4 | Wrap actions with no selection | Click in the textarea with no text selected, click Bold | Inserts `**bold text**` with "bold text" pre-selected, ready to type over immediately |
| 5 | Line-prefix actions, multi-line | Select several lines of text, click Bulleted list (then Numbered list, then Task list, then Quote) | Every selected line gets prefixed (`- `, `1. `/`2. `/etc incrementing, `- [ ] `, `> ` respectively) |
| 6 | Link action | Select some text, click Link | Inserts `[selected text](url)` with "url" pre-selected so you can type the destination immediately |
| 7 | Cursor sanity after each action | Repeat any action above | Cursor/selection lands in a sensible spot — never jumps to the start/end of the whole document or disappears |

**Edge cases to manually test:**
- [ ] Run a wrap action (Bold) immediately followed by a line-prefix action (Bulleted list) on the same line — confirm no garbled text
- [ ] Use Numbered list on a 1-line selection vs. a 5-line selection — confirm numbering starts at 1 each time and increments correctly

---

## Visual QA — [005] Unsaved-changes guard on Back to board

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Dialog appearance | Enter edit mode, type any change, click "Back to board" | A confirm dialog appears, visually matching the existing delete-confirmation dialog's style (same modal card, button layout), with copy explaining unsaved changes will be lost |
| 2 | Confirm discard | In that dialog, click the confirm/discard button | Navigates back to the board; the edit is discarded |
| 3 | Cancel the dialog | In that dialog, click Cancel | Dialog closes, you're still in edit mode, and your typed text is exactly as you left it |
| 4 | No unsaved changes | Enter edit mode, change nothing, click "Back to board" | Navigates back immediately — no dialog at all |
| 5 | Cancel button unaffected | Enter edit mode, type a change, click the editor's own "Cancel" button (not "Back to board") | Discards immediately with no dialog, regardless of unsaved changes — this guard only applies to "Back to board" |

**Edge cases to manually test:**
- [ ] Make a change, undo it back to the exact original text (e.g. type then delete), then click "Back to board" — should be treated as "no unsaved changes" (no dialog) since content matches the seed value
- [ ] Trigger the guard dialog, cancel it, then immediately click "Back to board" again — dialog should reappear correctly each time

---

## How to sign off

For each issue you visually verify:
- Approved → run `/qa-approve [issue number]`
- Something is wrong → run `/qa-reject [issue number] [what you saw]`
