# [007] Announcements (project-scoped, generalized from Keep Track)

**Type:** AFK
**Priority:** P2
**Blocked by:** 002, 004

---

## What to build

Move the existing announcements feature out of `keep_track` and generalize it to be per-project, behind the
`announcements` pill (shown only when a project's `hasAnnouncements` is true).

- Move the `Announcement`/`AnnouncementType` model, `AnnouncementsController`, and the announcements section
  UI (header, create/edit dialogs with markdown write/preview tabs, card list with type/draft badges) out of
  `keep_track` into the new `projects` feature.
- New `AnnouncementsRepository`/`AnnouncementsRepositoryImpl` with the same CRUD shape as today's, but
  project-scoped: `/api/v1/projects/{projectKey}/announcements...` against `DEVCENTER_BACKEND_URL` +
  `CRM_SECRET` (configured in 002).
- The repository/controller are constructed per-project (scoped DI, `projectKey` baked in) when the
  `announcements` pill is opened.
- Replace `AppColors.accentKeepTrack` references in this UI with `AppColors.accent`.

---

## Acceptance criteria

- [ ] For a project with `hasAnnouncements: true`, the `announcements` pill shows the existing
      create/edit/list UI, scoped to that project's announcements.
- [ ] Create/edit/publish-toggle/delete all hit the project-scoped endpoints with the correct `projectKey`.
- [ ] For a project with `hasAnnouncements: false`, no `announcements` pill is shown (covered by 004,
      verified here end-to-end).
- [ ] UI uses `AppColors.accent`, not the old `accentKeepTrack`.

---

## Tests required

Yes — `AnnouncementsController` unit tests with `FakeAnnouncementsRepository`: load/create/edit/delete
flows, correct `projectKey` passed through.

---

## Notes

- Full end-to-end verification (real HTTP calls) requires the reworked backend to be deployed with the
  project-scoped endpoints — this slice's automated tests don't depend on that, but manual verification
  does.

---

## Log

- Added `lib/features/projects/` with `Announcement`/`AnnouncementType`, project-scoped
  `AnnouncementsRepository`/`AnnouncementsController` (`/api/v1/projects/{projectKey}/announcements...`
  via `DEVCENTER_BACKEND_URL`/`CRM_SECRET`), and the moved `AnnouncementsSection` UI (`accentKeepTrack` →
  `accent`), constructed per-project via `createAnnouncementsController(projectKey)` and wired into the
  `announcements` pill in `_ProjectsContent`. Removed the now-unreferenced
  `keep_track/presentation/section/announcements_section.dart`.
- Tested via `flutter test` (5 new `AnnouncementsController` tests covering load/create/edit/delete and
  `projectKey` scoping with `FakeAnnouncementsRepository` — 56/56 total pass) and `flutter analyze`
  (0 new issues).

---

## Flagged

- `Announcement`/`AnnouncementType`/`AnnouncementsController` and the announcements repository methods
  remain in `keep_track` because `keep_track/presentation/section/overview_section.dart` still uses them.
  The new `projects` feature does not reference any of this — issue 012's cleanup should remove these
  leftovers once `overview_section.dart` and other orphaned keep_track sections are addressed.
