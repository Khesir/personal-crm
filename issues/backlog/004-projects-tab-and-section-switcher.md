# [004] Projects tab: project list + section pill switcher

**Type:** AFK
**Priority:** P1
**Blocked by:** 001, 002

---

## What to build

Wire the registered projects (from 003) into the Projects tab, and build the page-header section switcher
that the per-project screens (005-008) plug into.

- Projects tab sidebar lists all registered projects from `ProjectsController`.
- Selecting a project calls `ShellController.selectProject(projectId)`, which resets
  `selectedProjectSection` to `kanban`.
- The content area's page header shows the selected project's name and a pill/segmented switcher
  (`.cc-seg` style) over `ProjectSection` values:
  - `kanban` is always shown
  - `bugReports` is shown only if the project's `hasBugReports` is true
  - `announcements` is shown only if the project's `hasAnnouncements` is true
- Each pill renders a placeholder screen ("Kanban coming soon", etc.) for now — real content lands in
  005/006 (kanban + issue detail), 007 (announcements), and 008 (bug reports).

---

## Acceptance criteria

- [ ] Projects tab sidebar lists all registered projects from `ProjectsController`.
- [ ] Selecting a project updates the page header title and pill switcher to match that project.
- [ ] Pills only appear for sections enabled on that project (`hasBugReports`/`hasAnnouncements`); `kanban`
      is always present.
- [ ] Switching projects resets the selected section to `kanban`.
- [ ] Switching pills updates `selectedProjectSection` and the displayed placeholder.

---

## Tests required

Yes — `ShellController` unit tests covering `selectProject`/`selectProjectSection`, including the case
where selecting a section not enabled for the current project is a no-op.

---

## Notes

- Visual reference: `screen-projects.jsx`'s `ProjectsSidebar` (repo list) and the design's `.cc-seg` pill
  switcher in the page header.
