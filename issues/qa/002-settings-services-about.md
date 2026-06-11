# [002] Settings: Services configuration + About

**Type:** AFK
**Priority:** P1
**Blocked by:** 001

---

## What to build

A "Services" section in Settings for configuring the URLs/secrets the app talks to, and a minimal "About"
section.

Services fields:

- `N8N_BASE_URL`
- `OLLAMA_BASE_URL`
- `DEVCENTER_BACKEND_URL` (renamed from `KEEP_TRACK_BASE_URL`)
- `CRM_SECRET`
- `CLAUDE_API_KEY` (optional)

These are persisted using the existing `env_override_<KEY>` SharedPreferences mechanism that `main.dart`
already uses to override `dotenv.env` values at startup, so saved values take effect without further
plumbing.

About section: static info — app name ("Codex") and version.

---

## Acceptance criteria

- [ ] Editing any Services field persists it as `env_override_<KEY>` in SharedPreferences and survives an
      app restart.
- [ ] Saved values are picked up by `dotenv.env` at startup via the existing override-merge logic.
- [ ] About section shows app name and version, matching the design's Settings sidebar item.
- [ ] No "Appearance"/theme section exists anywhere in Settings.

---

## Tests required

No — this is a thin form bound directly to the existing SharedPreferences override mechanism; there is no
new business logic to unit test.

---

## Notes

- The local `.env` needs a one-line manual rename from `KEEP_TRACK_BASE_URL` to `DEVCENTER_BACKEND_URL`
  (not committed, low risk).
- `VERCEL_*` / `LEMON_SQUEEZY_*` env vars (used only by Keep Track's deleted analytics) are not part of this
  form.

---

## Log

- Added `lib/features/settings/` (datasource/repository/controller wrapping the existing
  `env_override_<KEY>` SharedPreferences mechanism), `ServicesSection` form for the five service
  fields, and `AboutSection` (static "Codex" name + version from `pubspec.yaml`). Added
  `SettingsSection` enum (`projects`/`services`/`about`) to `ShellStateData`/`ShellController` and
  wired `_SettingsSidebar` + the Settings content area to it; "Projects" section is a placeholder
  for issue 003.
- Tested via `flutter analyze` (0 new issues) and `flutter test` (all 5 tests pass).
