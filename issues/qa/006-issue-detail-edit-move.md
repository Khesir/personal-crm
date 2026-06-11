# [006] Issue detail: view, edit, move, acceptance criteria

**Type:** AFK
**Priority:** P1
**Blocked by:** 005

---

## What to build

The issue detail screen (per `screen-projects.jsx`'s `IssueDetailScreen`), reached by clicking a kanban
card: rendered markdown body, an interactive acceptance-criteria checklist, a frontmatter/metadata panel,
and the file path — plus the ability to edit and move issues.

`IssuesRepository`/`IssuesController` gain:

- `updateIssue(issue, {title?, body?, feature?, tags?})` — persists field changes back to the file.
- `moveIssue(issue, newStatus)` — moves the file between `issues/<status>/` folders and updates the
  `status:` frontmatter field.

UI:

- Body rendered via `flutter_markdown_plus`.
- "Acceptance criteria" section: checklist items parsed from `- [ ]`/`- [x]` lines under an "Acceptance
  criteria" heading. Toggling a checkbox flips it in place and persists immediately via `updateIssue`.
- Right-hand metadata panel: feature tag, status pill, tags, created date, file path, and a raw frontmatter
  preview block.
- "Move" action: a status-picker (dropdown), not drag-and-drop, that calls `moveIssue`.
- "Edit" action: dialog/editor for title, body (markdown), feature, and tags, calling `updateIssue`.

---

## Acceptance criteria

- [ ] Clicking an issue card opens its detail view with rendered description, acceptance criteria,
      frontmatter panel, and file path.
- [ ] Toggling an acceptance-criteria checkbox updates the on-disk markdown immediately and is reflected on
      reload.
- [ ] "Move" moves the file to the chosen status folder, updates its frontmatter, and the issue appears in
      the new column on the board.
- [ ] "Edit" changes to title/body/feature/tags persist to the file and are reflected in the detail view and
      board.

---

## Tests required

Yes — `IssuesController` unit tests with `FakeIssuesRepository`: `moveIssue` updates status and relocates
(fake records the call), `updateIssue` persists field changes, checkbox-toggle correctly identifies and
flips the right line by index.

---

## Notes

- The "Run skill" button shown in this screen's design is wired up in slice 010, not here.

---

## Log

- Added `updateIssue`/`moveIssue` to `IssuesRepository`/`IssuesController` (filesystem rewrite via new
  `IssueFrontmatterWriter`, preserving `id`/`created_at`), an acceptance-criteria parser + pure
  `toggleChecklistItem` helper, and `IssueDetailSection` (markdown body, interactive checklist, metadata
  panel, status-picker move dropdown, edit dialog). Wired card taps in `_ProjectsContent` to swap between
  the kanban board and the detail view (local state, no new route).
- Tested via `flutter test` (22 new tests: checklist toggle, acceptance-criteria parsing, frontmatter
  writer, repository `updateIssue`/`moveIssue`, controller integration — 51/51 total pass) and
  `flutter analyze` (0 new issues).
