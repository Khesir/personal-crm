# CRM — Build Plan

## What It Is

A desktop Flutter app (`keep-track/crm/`) that acts as a control panel for all personal projects. Each managed app gets its own tab with sub-sections for announcements, releases, and analytics. The CRM calls each app's own existing API directly — no dedicated CRM backend for now.

---

## Apps to Manage

| App | Status | Notes |
|-----|--------|-------|
| Keep Track | Live | Budget app — full feature set |
| Keep Track Time Tracker | In Dev | Skeleton tab, dev status shown |
| Ari Connect | Live | Discord bot |
| Minecraft Server | In Dev | Skeleton tab, dev status shown |

---

## Navigation Structure

```
AppShell
├── DesktopTitleBar        ← draggable, custom minimize/maximize/close (no system chrome)
├── AppTabBar (horizontal) ← one tab per managed app
└── AppContent
    ├── AppSidebar         ← sub-sections for the active tab
    └── ContentArea        ← rendered section
```

**Sub-sections per app:**

| App | Sections |
|-----|----------|
| Keep Track | Overview · Announcements · Releases · Analytics |
| Time Tracker | Overview (dev status only) |
| Ari Connect | Overview · Analytics |
| Minecraft | Overview (dev status only) |

---

## Folder Structure

```
crm/lib/
├── main.dart
├── core/
│   ├── di/            ← DiContainer, ServiceLocator, Disposable, DILogger
│   ├── state/         ← StreamState<T>, AsyncState<T>, StreamStateBuilder
│   ├── theme/         ← AppColors, AppStyling (dark professional theme)
│   ├── routing/       ← AppRoutes, AppRouter
│   └── ui/
│       ├── desktop_title_bar.dart
│       └── scope_screen.dart
└── features/
    ├── shell/
    │   ├── presentation/
    │   │   ├── screen/  ← app_shell_screen.dart
    │   │   ├── widget/  ← app_tab_bar.dart, app_sidebar.dart
    │   │   └── state/   ← shell_state.dart
    │   └── domain/
    │       └── controller/ ← shell_controller.dart
    ├── keep_track/
    │   ├── presentation/
    │   │   ├── screen/   ← keep_track_screen.dart
    │   │   ├── section/  ← overview, announcements, releases, analytics
    │   │   └── state/    ← keep_track_state.dart
    │   ├── domain/
    │   │   ├── controller/ ← keep_track_controller.dart
    │   │   └── repository/ ← keep_track_repository.dart (abstract)
    │   ├── data/
    │   │   ├── repository/ ← keep_track_repository_impl.dart
    │   │   └── datasource/ ← keep_track_datasource.dart
    │   ├── di.dart
    │   └── api.dart
    ├── time_tracker/   ← same structure, skeleton only
    ├── ari_connect/    ← same structure, ari connect specific
    └── minecraft/      ← same structure, skeleton only
```

---

## Theme

Dark, professional desktop aesthetic:

| Token | Value |
|-------|-------|
| Background | `#0D0D0F` |
| Surface | `#141416` |
| Surface elevated | `#1C1C1F` |
| Border | `#2A2A30` |
| Text primary | `#F0F0F5` |
| Text secondary | `#8A8A9A` |
| Accent (Keep Track) | `#14B8A6` (teal) |
| Accent (Time Tracker) | `#3B82F6` (blue) |
| Accent (Ari Connect) | `#7C3AED` (purple) |
| Accent (Minecraft) | `#22C55E` (green) |

Typography: DM Sans (UI) + DM Mono (stats/numbers) via `google_fonts`.

---

## Key Technical Decisions

- **State**: `StreamState<T>` + `StreamStateBuilder` — same as keep-track, no BLoC/Riverpod.
- **DI**: Custom `ServiceLocator` + `ScopedServiceLocator` — same as keep-track, no GetIt.
- **Window chrome**: `window_manager` package — hidden system title bar, custom draggable header.
- **HTTP**: `Dio` — one instance per app datasource, base URL configured per app.
- **No backend**: CRM calls each app's existing API. If a central store is needed later, add a backend then.
- **ScopeScreen**: Every screen uses a scoped DI lifetime — same pattern as keep-track.

---

## Build Order

### Phase 1 — Core Infrastructure
- [x] `pubspec.yaml` with dependencies
- [x] `core/di/` — DI container + service locator
- [x] `core/state/` — StreamState + StreamStateBuilder
- [x] `core/theme/` — AppColors + AppStyling (dark theme)
- [x] `core/ui/desktop_title_bar.dart` — custom window chrome
- [x] `core/ui/scope_screen.dart`
- [x] `main.dart` — bootstrap, window setup, DI init

### Phase 2 — App Shell
- [x] `features/shell/` — ShellController, ShellState, AppShellScreen
- [x] `AppTabBar` widget — tab per app, accent color per tab
- [x] `AppSidebar` widget — sub-sections for active tab

### Phase 3 — Keep Track Feature (full)
- [x] Datasource — calls keep-track NestJS API
- [x] Repository + impl
- [x] Controllers with AsyncState
- [x] Sections: Overview, Announcements, Releases, Analytics
- [x] DI factory + barrel export

### Phase 4 — Remaining App Features (skeletons → real)
- [x] Time Tracker — skeleton (dev status overview)
- [x] Ari Connect — overview + analytics sections
- [x] Minecraft — skeleton (dev status overview)

---

## Open Questions (decide before Phase 3)

1. **Keep Track API base URL** — what is the deployed backend URL?
2. **Announcements** — does the keep-track backend already have an announcements endpoint, or does that need to be built?
3. **Releases** — where are release files stored (Vercel Blob, GitHub Releases)? Upload goes to where exactly?
4. **Analytics** — what data is already available from the keep-track API? (active users, download count, etc.)
5. **Ari Connect** — what API/bot framework exposes stats? Discord API directly, or a custom bot API?
