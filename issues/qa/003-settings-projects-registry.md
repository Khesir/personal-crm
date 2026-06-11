# [003] Settings: Projects registry (CRUD)

**Type:** AFK
**Priority:** P1
**Blocked by:** 001

---

## What to build

A "Projects" section in Settings where the user registers the local repos the app operates on.

`Project` entity:

```
Project { id, name, localPath, projectKey, hasBugReports, hasAnnouncements }
```

`id` and `projectKey` are the same value: a slug derived from `name` at creation time (lowercase,
non-alphanumeric runs collapsed to `-`, trimmed; on collision with an existing project's slug, append a
numeric suffix, e.g. `-2`). The slug is fixed at creation and never re-derived from later name edits.

Modules:

- `ProjectsRepository` (abstract) + `ProjectsRepositoryImpl` persisting the project list as JSON in
  `shared_preferences`.
- `ProjectsController extends StreamState<AsyncState<List<Project>>>` with `load()`, `addProject(name,
  localPath, {hasBugReports, hasAnnouncements})`, `updateProject(...)`, `removeProject(id)`.

UI: Settings → "Projects" card listing registered projects with Add/Edit/Delete. The Add/Edit dialog has:
Name, Local path (text field + directory picker via `file_picker`), "Has Bug Reports" toggle, "Has
Announcements" toggle. The derived `projectKey`/`id` is shown read-only.

Seed data: register `personal-crm` itself as a project on first run, pointing at this repo's local
checkout path.

---

## Acceptance criteria

- [ ] Adding a project derives and displays its slugified `projectKey`/`id`; creating a second project whose
      name slugifies to the same value gets a `-2` suffix.
- [ ] Editing a project's name does not change its existing `projectKey`/`id`.
- [ ] Adds, edits, and deletions persist across an app restart.
- [ ] `personal-crm` appears in the project list out of the box, pointing at this repo's checkout path.

---

## Tests required

Yes — `ProjectsController` unit tests with `FakeProjectsRepository`: add/edit/remove flows, slug derivation
and collision suffixing, persistence round-trip via the fake.

---

## Notes

- No new local database — JSON in `shared_preferences`, consistent with the existing config/override usage.

---

## Log

- Added `Project` model + slug helper (collision suffixing), `ProjectsRepository`/`ProjectsRepositoryImpl`
  (JSON in `shared_preferences`, seeds `personal-crm` on first run), `ProjectsController`
  (`load`/`addProject`/`updateProject`/`removeProject`), and the Settings → Projects UI (list + Add/Edit
  dialog with directory picker and toggles), wired into `_SettingsContent`.
- Tested via `flutter test` (8 new `ProjectsController` tests with `FakeProjectsRepository` covering slug
  derivation/collision, edit-preserves-id, persistence round-trip — 13/13 total pass) and `flutter analyze`
  (0 new errors).

---

## Flagged

- Seeded `personal-crm` defaults to `hasBugReports: true, hasAnnouncements: true` — not specified by the
  issue; confirm this is the intended default.
- `ProjectsRepositoryImpl` re-seeds `personal-crm` whenever the stored project list is empty, including
  after a user explicitly deletes it. A "seeded-once" flag may be preferable if that's unwanted.
