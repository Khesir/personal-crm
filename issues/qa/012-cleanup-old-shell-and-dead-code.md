# [012] Cleanup: remove old tabs, screens, and dead color tokens

**Type:** AFK
**Priority:** P3
**Blocked by:** 005, 006, 007, 008, 009, 010, 011

---

## What to build

A final sweep to remove everything left over from the pre-pivot shell and features once 005-011 have moved
or replaced what depended on it.

- Remove any remaining `keep_track` code not moved in 007 (releases, analytics, support — controllers,
  datasources, sections, state — and their `VERCEL_*`/`LEMON_SQUEEZY_*` env reads).
- Remove the now-unused per-tab `AppColors` accents: `accentPortfolio`, `accentKeepTrack`,
  `accentTimeTracker`, `accentAriConnect`, `accentMinecraft`.
- Sweep for any other dead references to the old shell types (`AppSection`, `kTabSections`,
  `kTabSectionGroups`, old `AppTabBar`) and any unused imports/dependencies left from before 001.

---

## Acceptance criteria

- [x] No references to `accentPortfolio`, `accentKeepTrack`, `accentTimeTracker`, `accentAriConnect`, or
      `accentMinecraft` remain.
- [x] The `keep_track` feature folder contains only what 007 moved out of it, or is removed entirely if
      everything was moved.
- [x] Build and analyzer run clean with no unused-import/dead-code warnings introduced by the pivot.
- [ ] A full app walkthrough (Home / Projects / Settings, and all per-project sections) matches the
      `Dev Command Center.html` design with no leftover old-shell visuals.

---

## Tests required

No — this is removal/verification of already-tested code; the existing test suite passing is the bar.

---

## Notes

- This is intentionally last — it's only safe once 005-011 have moved or replaced everything that was still
  depending on the pre-pivot code.

## Log

- Deleted `lib/features/keep_track/` entirely (18 files: api, di, datasources, repository, controllers,
  presentation sections/state for keep_track/analytics/support) — confirmed zero references from outside
  the folder before removal.
- Removed `AppColors.accentKeepTrack` and its "Legacy:" comment from `lib/core/theme/app_colors.dart`
  (its only consumers were inside the deleted folder).
- Removed `VERCEL_TOKEN`, `VERCEL_PROJECT_ID`, `VERCEL_TEAM_ID`, `LEMON_SQUEEZY_API_KEY`, and the now-orphaned
  `KEEP_TRACK_BASE_URL` from `.env` and `.env.example`.
- `pubspec.yaml` unchanged: `dio`, `flutter_dotenv`, `shared_preferences` are all still used by other
  features (projects, home, agent_run, settings), so none were removed.
- Verified via grep: zero remaining references to `accentPortfolio`/`accentKeepTrack`/`accentTimeTracker`/
  `accentAriConnect`/`accentMinecraft`, `keep_track`/`KeepTrack`/`KEEP_TRACK`, and `AppSection`/
  `kTabSections`/`kTabSectionGroups`/`AppTabBar` anywhere in `lib/` or `test/`.
- `flutter analyze`: 2 issues found, both pre-existing `deprecated_member_use` (`activeColor`) infos in
  `lib/features/projects/presentation/section/announcements_section.dart` and
  `lib/features/settings/presentation/dialogs/project_form_dialog.dart`, unrelated to this change.
- `flutter test`: 72/72 passed.
