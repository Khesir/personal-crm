---
id: issue-005
title: "Kanban board (read-only, per project, rescan)"
feature: kanban
status: done
created_at: 2026-06-11
tags: [afk, p1, test]
---

# [005] Kanban board (read-only, per project, rescan)

**Type:** AFK
**Priority:** P1
**Blocked by:** 004

---

## What to build

The `kanban` pill content: a 5-column board reading issue files from the selected project's local
`issues/` folder, per `docs/dev-workflow-app-spec.md`.

`Issue` entity and `IssueStatus` enum: `backlog`, `ready`, `inprogress`, `qa`, `done`.

Frontmatter schema (YAML, delimited by `---`, followed by the markdown body):

```
id: issue-044
title: Add OAuth login
feature: user-auth
status: ready
created_at: 2026-06-10
tags: [auth, backend]
```

Modules:

- `IssuesRepository` (abstract) + filesystem implementation reading
  `{project.localPath}/issues/{backlog,ready,inprogress,qa,done}/*.md`, parsing frontmatter (new
  `package:yaml` dependency) and body.
- `IssuesController extends StreamState<AsyncState<List<Issue>>>` with `load(localPath)`.

UI: 5 kanban columns (per `screen-projects.jsx`'s `KanbanColumn`/`IssueCard`) showing title, feature tag
(with an icon + accent-2 color), tags, id, and date for each issue card, grouped by status. Includes a
"Rescan" action in the page header that reloads from disk.

---

## Acceptance criteria

- [ ] Selecting `kanban` for a project with an `issues/` folder shows its issues grouped into the 5 status
      columns, matching folder contents.
- [ ] Issue cards show title, feature, tags, id, and date as in the design.
- [ ] A project with no `issues/` folder (or empty status folders) shows the design's empty-column state
      ("No issues"), not an error.
- [ ] "Rescan" re-reads the folder and reflects any external changes (e.g. files added by `git pull`).

---

## Tests required

Yes — `IssuesController` and filesystem `IssuesRepository` unit tests with `FakeIssuesRepository`/in-memory
frontmatter fixtures: parsing, grouping by status, rescan reload.

---

## Notes

- `personal-crm`'s own `issues/` folder (this PRD's own issue files, including this one) can serve as real
  manual-testing data once this slice is built.

---

## Log

- Added `lib/features/kanban/` with `Issue`/`IssueStatus`, a YAML-frontmatter `IssueFrontmatterParser`
  (returns `null`/skips files with no `---` block), filesystem `IssuesRepositoryImpl` reading
  `{localPath}/issues/{backlog,ready,in-progress,qa,done}` (note: `IssueStatus.inprogress` maps to the
  `in-progress` folder), and `IssuesController`. Built `KanbanSection`/`KanbanColumn`/`IssueCard` and wired
  it into `_ProjectsContent`'s `kanban` pill with a "Rescan" header action. Added direct `yaml`/`path`
  dependencies (previously transitive).
- Tested via `flutter test` (7 new tests: frontmatter parsing, missing-frontmatter skip, folder-name
  mapping, grouping, empty-folder handling, controller load/rescan — 29/29 total pass) and
  `flutter analyze` (0 new issues).
- QA approved by user on 2026-06-12.

---

## Flagged

- `docs/dev-workflow-app-spec.md` documents an `inprogress/` (no hyphen) folder, but this repo's actual
  `issues/in-progress/` uses a hyphen. The repository maps `IssueStatus.inprogress` → `in-progress` to
  match real project structures; worth confirming this is the intended convention for all registered
  projects.