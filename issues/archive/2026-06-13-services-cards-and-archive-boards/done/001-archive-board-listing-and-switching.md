---
id: issue-001
title: "Archive board listing & switching (board view)"
feature: kanban-archive
status: done
created_at: 2026-06-12
tags: [afk, p1]
---

# [001] Archive board listing & switching (board view)

**Type:** AFK
**Priority:** P1
**Blocked by:** None
**User stories covered:** 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11

---

## What to build

A dropdown in a project's kanban board header that lets the developer switch between the live "Current" board and any of the project's archived feature boards (`issues/archive/<name>/`), showing the same 5-column kanban layout populated from the selected archive's frozen issue files.

- `IssuesRepository`/`IssuesRepositoryImpl` gain two new, independently-implemented methods (no shared scan helper):
  - `getArchivedIssues(localPath, archiveName)` — parses and groups issues from `{localPath}/issues/archive/{archiveName}/{backlog,ready,in-progress,qa,done}/*.md` using the existing frontmatter parser. Same skip/empty-folder behavior as `getIssues`.
  - `listArchives(localPath)` — returns the subdirectory names directly under `{localPath}/issues/archive/`, sorted descending (newest-first). Empty list if `issues/archive/` doesn't exist.
- `IssuesController` gains `loadArchive(localPath, archiveName)`, calling `getArchivedIssues` and emitting `AsyncData` — same shape as `load`, sourced from the archive.
- `_ProjectsContentState`:
  - `String? _selectedArchive` (`null` = "Current"), reset to `null` whenever the selected project changes.
  - `List<String> _archives`, populated via `listArchives(localPath)` each time the dropdown is opened (manual refresh, not cached across opens).
  - When `_selectedArchive` is non-null, an on-demand second `IssuesController` is created and loaded via `loadArchive`, disposed when switching back to "Current" or when the project changes (mirrors the existing `_announcementsController`/`_bugReportsController` lifecycle pattern). The live `_issuesController` is untouched, so switching back to "Current" is instant with no reload.
- Header UI (second row of the kanban section header, alongside `Rescan`/`Run skill`):
  - A `PopupMenuButton<String?>` styled like `_RescanButton`/`_RunSkillButton` (same `surfaceRaised` container, border, radius). `null` = "Current", always first. Remaining items are `_archives` names, newest-first. While `listArchives` is in flight after opening the menu, show a single disabled "Loading…" item.
  - "Current" selected: `[Archive dropdown] ... [Rescan] [Run skill]` (`mainAxisAlignment.spaceBetween`).
  - Archive selected: `[Archive dropdown] [Read-only badge]` — `Rescan`/`Run skill` not rendered.
- "Read-only" badge: small pill styled like the existing `_Pill`/status-dot pills (muted background, `AppColors.textSecondary`), rendered immediately right of the dropdown, only when an archive is selected.
- Page subtitle: when an archive is selected, changes from "Manage this project's work." to `"Viewing archived board: <archive-name> — read-only"`.
- `KanbanSection` receives a `readOnly: bool` flag (plumbing only in this slice — no behavioral change to the board itself; consumed by issue 002 for the detail view).

---

## Acceptance criteria

- [ ] The kanban header shows an "Archive" dropdown defaulting to "Current".
- [ ] Opening the dropdown lists archived boards for the current project, newest-first by folder name, re-scanning `issues/archive/` each time it's opened.
- [ ] If `issues/archive/` doesn't exist or is empty, the dropdown still renders with only "Current".
- [ ] Selecting an archive shows that archive's issues in the same 5-column kanban layout, sourced from `issues/archive/<name>/{backlog,ready,in-progress,qa,done}/`.
- [ ] When an archive is selected: the "Read-only" badge appears next to the dropdown, the subtitle reads "Viewing archived board: `<name>` — read-only", and `Rescan`/`Run skill` buttons are not shown.
- [ ] Switching back to "Current" restores the live board instantly (no rescan/reload) with `Rescan`/`Run skill` visible again.
- [ ] Switching projects resets the selection to "Current".

---

## Tests required

Yes — `IssuesRepositoryImpl` unit tests (temp-dir fixtures, same pattern as existing `getIssues` tests) for `getArchivedIssues` (parsing/grouping rooted at `issues/archive/<name>/...`, empty list if missing) and `listArchives` (sorted-descending folder names, empty list if `issues/archive/` missing). `IssuesController` unit tests with an extended `FakeIssuesRepository` for `loadArchive` (state transitions to `AsyncData` with the fake's archived issues).

---

## Notes

- Archive folders are created exclusively by `/new-feature` as `issues/archive/YYYY-MM-DD-feature-name/`, with the same 5-status-folder shape as live `issues/`, so the existing `Issue`/`IssueStatus` model and frontmatter parser are reused unchanged.
- `issues/archive/2026-06-12-dev-command-center/` (this repo's own prior feature cycle, with 12 done issues) can serve as real manual-testing data.

---

## Log

_Updated as work progresses._

- Implemented `IssuesRepository.getArchivedIssues`/`listArchives` (independent scans, no shared helper) and `IssuesController.loadArchive`, with TDD coverage in `issues_repository_impl_test.dart` (5 new tests) and `issues_controller_test.dart` (1 new test, extended `FakeIssuesRepository`).
- Wired the UI: `_ProjectsContentState` gains `_selectedArchive`/on-demand `_archiveController` (mirrors announcements/bug-reports lifecycle, reset on project change), a `PopupMenuButton`-style `_ArchiveDropdown` (manual `showMenu` with a "Loading…" interim item) plus `_ReadOnlyBadge`, subtitle text swap, and conditional Rescan/Run-skill vs. Read-only header row. `KanbanSection`/`_KanbanOrDetail` now accept `readOnly: bool` (plumbing only, no behavioral change).
- `flutter test` (78/78) and `flutter analyze` (no new issues) both pass.
- QA rejected on 2026-06-13. Bug appended — after selecting an archive, the kanban board does not repopulate with that archive's issues.
- Bug fixed on 2026-06-13. Root cause was in the shared `StreamStateBuilder` (`lib/core/state/stream_builder_widget.dart`, used by `AsyncStreamBuilder`): its `_StreamStateBuilderState` captured the controller's initial state and subscribed to its stream only in `initState`, so when `_KanbanOrDetail` swapped `kanbanController` from `_issuesController` to `_archiveController`, the same state object kept its stale snapshot and stale subscription instead of picking up the archive controller's data. Added a `didUpdateWidget` override that re-subscribes (and refreshes `_currentState`) whenever the `StreamState` instance passed in changes, fixing `KanbanSection` (and every other `AsyncStreamBuilder`/`StreamStateBuilder` consumer) for this case.
- QA approved by user on 2026-06-13.

---

## Bug

**Reported:** 2026-06-13
**Found during:** Visual QA
**Description:** After switching the Archive dropdown from "Current" to an archived board, the kanban board does not repopulate — acceptance criterion #4 ("Selecting an archive shows that archive's issues in the same 5-column kanban layout") does not work.

### What to fix
_To be investigated during implementation._

### Acceptance Criteria
- [ ] Bug no longer reproduces
- [ ] Original acceptance criteria still met
- [ ] A test exists that would have caught this
