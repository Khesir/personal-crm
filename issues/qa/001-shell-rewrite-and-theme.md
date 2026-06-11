# [001] Shell rewrite: icon rail, contextual sidebar, dark "Codex" theme

**Type:** AFK
**Priority:** P1
**Blocked by:** None

---

## What to build

Replace the current 5-tab top bar shell with the new "Codex" shell: a dark theme built on a single accent
color plus status/severity scales, a left-hand icon rail (Home / Projects / Settings, with Settings pinned
to the bottom), and a contextual sidebar whose contents depend on the active top-level tab.

Theme tokens (from the `Dev Command Center.html` mockup's `:root`), to be expressed as `AppColors`/`AppStyling`:

- Backgrounds: `bg0` (#0c0c0e, outer/deepest), `titlebar` (#1a1a1d), `body` (#0e0e10, content/sidebar),
  `card` (#161619), `card2` (#1c1c20, raised/inputs), `col` (kanban column bg, ~2% white)
- Borders: `border` (~7% white), `border2` (~13% white)
- Text scale: `hi` (#ededee), `mid` (#9a9aa2), `lo` (#65656d), `faint` (#46464d)
- Accent: `accent` (#8b7ff5), `accentLight`/`accent-2` (#a99dff), `accentBg` (~16% accent), `accentLine`
- Status (kanban columns): `statusBacklog`, `statusReady`, `statusInProgress`, `statusQa`, `statusDone`
- Severity (bug reports): `severityInfo`, `severityWarning`, `severityError`, `severityCritical`
- Fonts: IBM Plex Sans (UI), JetBrains Mono (code/mono fields)
- Existing semantic `success`/`warning`/`error`/`info` colors are retained as-is.

Navigation structure:

- `AppTab` enum: `home`, `projects`, `settings`.
- `ProjectSection` enum: `kanban`, `bugReports`, `announcements`.
- `ShellStateData { selectedTab, selectedProjectId, selectedProjectSection }` and `ShellController` with
  `selectTab(tab)`, `selectProject(projectId)` (resets section to `kanban`), `selectProjectSection(section)`.

Layout:

- New vertical icon rail replacing the old horizontal tab bar: Home and Projects icons stacked at top,
  Settings icon pinned to the bottom, accent highlight + left accent bar on the active item.
- Rewritten sidebar, contextual on `selectedTab`:
  - `home` → conversation list placeholder + "New chat" button (real content in 009)
  - `projects` → project list placeholder (real content in 004)
  - `settings` → static section list: Projects / Services / About
- Content area renders a placeholder per tab. The Projects placeholder includes the page-header pill
  switcher skeleton (for `ProjectSection`), inert until 004 wires it up.

This is a hard pivot, not additive — the old top tab bar, old `AppSection`/`kTabSections`/`kTabSectionGroups`,
and old per-tab routing are removed.

---

## Acceptance criteria

- [ ] App launches into the new dark "Codex" palette (single accent, IBM Plex Sans / JetBrains Mono) across
      the rail, sidebar, title bar, and content background.
- [ ] Left icon rail shows Home, Projects, and Settings, with Settings pinned to the bottom; clicking each
      switches `selectedTab` and updates the sidebar/content accordingly.
- [ ] Sidebar content changes per tab (placeholder lists for Home/Projects, static section list for Settings).
- [ ] No remnants of the old 5-tab top bar, old `AppSection`, `kTabSections`, or `kTabSectionGroups` remain.
- [ ] App builds and runs cleanly with the `portfolio`, `time_tracker`, `ari_connect`, and `minecraft`
      feature folders removed entirely.

---

## Tests required

Yes — `ShellController` unit tests: `selectTab` switches the active tab; `selectProject` sets
`selectedProjectId` and resets `selectedProjectSection` to `kanban`; `selectProjectSection` updates the
section.

---

## Notes

- `portfolio`, `time_tracker`, `ari_connect`, and `minecraft` feature folders can be deleted entirely now —
  nothing from them is reused by the new design.
- `keep_track`'s announcement-related code (model, controller, datasource methods, UI) should be left in
  place but unreferenced for now — slice 007 moves it into the new `projects` feature. Its remaining
  `accentKeepTrack` color reference and any other now-orphaned `keep_track` code (releases/analytics/support)
  are removed in slice 012, once 007 has moved what's needed out.
- Visual reference: `Dev Command Center.html` mockup bundle, especially `frame.jsx` primitives
  (`.cc-rail`, `.cc-sidebar`, `.cc-side-item`, `.cc-seg`, `.cc-page-head`) and the `:root` theme tokens.

---

## Log

- Implemented Codex theme tokens in `AppColors`/`AppStyling` (dark palette, IBM Plex Sans, JetBrains Mono,
  status/severity scales), new `AppTab`/`ProjectSection` enums, `ShellStateData`/`ShellController`, and
  rewrote the shell screen with a vertical `AppRail` and contextual `AppSidebar`. Removed `portfolio`,
  `time_tracker`, `ari_connect`, `minecraft`, the old `AppTabBar`, and the `AppSection`-coupled
  `keep_track_screen.dart`.
- Tested via `flutter test` (new `ShellController` unit tests for `selectTab`, `selectProject`,
  `selectProjectSection` all pass) and `flutter analyze` (0 errors; only pre-existing unrelated lints in
  orphaned `keep_track` files remain). Build verified via `flutter run -d windows`.
