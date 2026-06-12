# PRD: Kanban Board — Archived Feature Boards (Read-Only)

**Status:** Draft
**Date:** 2026-06-12

---

## Problem Statement

When the developer runs `/new-feature`, the entire `issues/` working set for a completed feature cycle (its PRD, kanban board, and all issue files) is moved into `issues/archive/YYYY-MM-DD-feature-name/`, and `issues/` is reset to empty folders for the next cycle. Once that happens, the completed feature's board disappears from the kanban UI entirely — the developer has no way to browse what was built for a past feature without leaving the app and digging through the filesystem.

---

## Solution

Add a dropdown selector to a project's kanban board header that lets the developer switch between the live "Current" board and any of the project's archived feature boards. Selecting an archived board shows the same 5-column kanban layout, populated from that archive's frozen issue files, in a read-only view — no editing, moving, or running skills against historical issues.

---

## User Stories

1. As a developer, I want a dropdown in the kanban board header listing my archived feature boards, so I can find historical work without leaving the app.
2. As a developer, I want the dropdown to default to "Current", so my normal day-to-day workflow is unaffected.
3. As a developer, I want archived boards listed newest-first, so I can quickly find recent archives.
4. As a developer, I want each archived board labeled with its raw archive folder name (e.g., `2026-06-12-dev-command-center`), so I can identify which feature cycle it came from.
5. As a developer, I want the archive list to refresh every time I open the dropdown, so an archive created earlier in my session shows up without restarting the app.
6. As a developer, when a project has no `issues/archive/` folder yet, I still want to see the dropdown showing just "Current", so the UI is consistent across all projects.
7. As a developer, I want selecting an archived board to show its issues in the same 5-column kanban layout as the current board, so the viewing experience is consistent.
8. As a developer, I want an archived board's issues read from `issues/archive/<name>/{backlog,ready,in-progress,qa,done}`, so it reflects exactly what was archived at the time.
9. As a developer, I want a "Read-only" badge next to the dropdown when I've selected an archived board, so I know at a glance that I can't make changes.
10. As a developer, I want the page subtitle to read "Viewing archived board: `<name>` — read-only" when an archive is selected, so it's unambiguous even if I've scrolled past the dropdown.
11. As a developer, I want the "Rescan" and "Run skill" header buttons hidden when viewing an archived board, so I'm not offered actions that don't apply to frozen history.
12. As a developer, I want to click an issue card in an archived board to open its detail view, so I can read its full description, acceptance criteria, and metadata.
13. As a developer, I want acceptance-criteria checkboxes in an archived issue's detail view to render as static, non-interactive indicators, so I can see what was completed without risk of changing it.
14. As a developer, I want the "Edit", "Move", and "Run skill" actions hidden in an archived issue's detail view, so I can't accidentally mutate frozen history or kick off a new agent run against it.
15. As a developer, I want switching back to "Current" to restore the live board instantly without a reload, so I don't lose my place or wait on a rescan.
16. As a developer, I want my archive selection to reset to "Current" when I switch projects, so I never see one project's archived board mislabeled under another project.

---

## Implementation Decisions

- **`IssuesRepository` / `IssuesRepositoryImpl`**: add two new methods, implemented independently (no shared scanning helper, to avoid growing a god-object):
  - `getArchivedIssues(localPath, archiveName)` — returns `List<Issue>`, parsing and grouping issues from `{localPath}/issues/archive/{archiveName}/{backlog,ready,in-progress,qa,done}/*.md` using the existing frontmatter parser. Same behavior as `getIssues` (skips files without frontmatter, returns empty list if the archive directory doesn't exist).
  - `listArchives(localPath)` — returns `List<String>`, the subdirectory names directly under `{localPath}/issues/archive/`, sorted descending (newest-first, since folder names start with `YYYY-MM-DD-`). Returns an empty list if `issues/archive/` doesn't exist.

- **`IssuesController`**: existing `load(localPath)` is unchanged (live board only). Add a new method (e.g. `loadArchive(localPath, archiveName)`) that calls `getArchivedIssues` and emits `AsyncData` with the result — same shape as `load`, but sourced from the archive.

- **`_ProjectsContentState`** (kanban section host):
  - Add `String? _selectedArchive` (`null` = "Current"). Reset to `null` whenever the selected project changes (i.e., whenever `_loadedLocalPath` changes).
  - Add `List<String> _archives` — populated by calling `listArchives(localPath)` each time the dropdown is opened (manual refresh, not cached across opens).
  - When `_selectedArchive` is non-null, create a second, on-demand `IssuesController` and call `loadArchive(localPath, _selectedArchive)`. Dispose this controller when switching back to "Current" or when the project changes — mirrors the existing `_announcementsController`/`_bugReportsController` on-demand lifecycle pattern.
  - The live `_issuesController` is left untouched while an archive is being viewed, so switching back to "Current" requires no reload.

- **Read-only threading**: add a `readOnly: bool` flag, threaded from `_ProjectsContentState` → `_KanbanOrDetail` → `KanbanSection` and `IssueDetailSection`.
  - `KanbanSection`: card tap still opens the detail view as normal (no behavior change beyond passing the flag through).
  - `IssueDetailSection`, when `readOnly` is true:
    - Acceptance-criteria checkboxes render as static, non-tappable indicators (no `updateIssue` call wired).
    - The "Edit" dialog, "Move" status-picker dropdown, and "Run skill" button are not rendered.

- **Header UI** (second row of the kanban section header, alongside the existing `Rescan`/`Run skill` buttons):
  - Add a `PopupMenuButton<String?>`, styled like `_RescanButton`/`_RunSkillButton` (same `surfaceRaised` container, border, radius). `null` represents "Current" and is always the first item.
  - Remaining items are the archive names from `_archives`, in the order returned by `listArchives` (newest-first).
  - While `listArchives` is in flight after opening the menu, show a single disabled "Loading…" menu item.
  - Row layout:
    - "Current" selected: `[Archive dropdown] ... [Rescan] [Run skill]` (`mainAxisAlignment.spaceBetween`).
    - Archive selected: `[Archive dropdown] [Read-only badge]` — `Rescan`/`Run skill` are not rendered.

- **"Read-only" badge**: a small pill styled like the existing `_Pill`/status-dot pills (muted background, `AppColors.textSecondary`), rendered immediately to the right of the dropdown, only when an archive is selected.

- **Page subtitle** (title row): when an archive is selected, the subtitle text changes from "Manage this project's work." to `"Viewing archived board: <archive-name> — read-only"`.

---

## Testing Decisions

Good tests exercise public interfaces and observable behavior, not implementation details — consistent with the existing repository and controller test suites.

- **`IssuesRepositoryImpl`** (`test/features/kanban/data/repository/issues_repository_impl_test.dart`): new tests for `getArchivedIssues` (parses issues rooted at `issues/archive/<name>/...` with the same frontmatter/grouping behavior as `getIssues`; returns an empty list when the archive directory doesn't exist) and `listArchives` (returns archive folder names sorted descending; returns an empty list when `issues/archive/` doesn't exist), using the same temp-dir fixture pattern (`writeIssue`-style helpers) already in that file.
- **`IssuesController`** (`test/features/kanban/domain/controller/issues_controller_test.dart`): extend `FakeIssuesRepository` with `getArchivedIssues`/`listArchives`, and add tests for the new archive-loading controller method (state transitions to `AsyncData` containing the fake's archived issues).
- **UI** (dropdown, "Read-only" badge, subtitle text, and `readOnly` threading through `KanbanSection`/`IssueDetailSection`): no widget tests — per the precedent set in issue 010, UI wiring is human-QA territory and is covered by the visual QA checklist instead.

---

## Out of Scope

- Editing, moving, or running skills against issues in an archived board — archived boards are frozen snapshots by design.
- Browsing archives for a project whose `localPath` doesn't exist or isn't accessible.
- Deleting or "re-activating" an archived board from the UI.
- Displaying an archived board's `prd.md` or `qa-report.md` — only the kanban board (issue columns) is shown.
- Caching `listArchives` results across dropdown opens or project switches — always re-scanned on open.

---

## Further Notes

- Archive folders are created exclusively by the `/new-feature` skill as `issues/archive/YYYY-MM-DD-feature-name/`, with the same 5-status-folder shape (`backlog/ready/in-progress/qa/done`) as the live `issues/` tree, so the existing frontmatter parser and `Issue`/`IssueStatus` model can be reused unchanged.
- This PRD's own feature cycle archived the prior "Dev Command Center" PRD and its 12 completed issues into `issues/archive/2026-06-12-dev-command-center/`, which can serve as real manual-testing data for this feature once built.
