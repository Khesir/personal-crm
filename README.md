<div align="center">

<img src="assets/icon.png" alt="Personal CRM" width="96" height="96"/>

# Personal CRM

Internal dashboard for managing Keep Track — analytics, releases, support, and portfolio.

[![Flutter](https://img.shields.io/badge/Flutter-3.35-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9-0175C2?logo=dart)](https://dart.dev)
[![Version](https://img.shields.io/badge/version-1.0.0-informational)]()

</div>

---

> **Private tool.** Desktop-only app for managing Keep Track's operational data — not intended for end users.

---

## Features

- **Keep Track** — app overview, announcements, release history, analytics, and support tickets
- **Portfolio** — manage portfolio content (projects, blog posts, experience, config)
- **Time Tracker** — internal time tracking
- **Minecraft** — Minecraft server/world management
- **Ari Connect** — Ari Connect project dashboard

---

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Flutter SDK | 3.35+ | `flutter --version` to check |
| Dart SDK | 3.9+ | Included with Flutter |

---

## Getting Started

### 1. Install dependencies

```bash
cd crm
flutter pub get
```

### 2. Environment setup

Create a `.env` file in the `crm/` directory:

```env
API_BASE_URL=<ask the project owner>
```

### 3. Run the app

```bash
# Windows
flutter run -d windows
```

---

## Project Structure

```
lib/
├── core/
│   ├── di/         # Custom service locator
│   ├── network/    # Dio HTTP client
│   ├── state/      # StreamState + StreamStateBuilder
│   ├── theme/      # AppStyling — colors, text styles
│   └── ui/         # Shared widgets (ScopeScreen, desktop title bar)
└── features/
    ├── shell/          # App shell, sidebar, tab bar
    ├── keep_track/     # Keep Track app management (analytics, releases, support)
    ├── portfolio/      # Portfolio content management
    ├── time_tracker/   # Time tracking
    ├── minecraft/      # Minecraft project dashboard
    └── ari_connect/    # Ari Connect project dashboard
```

Each feature follows the standard folder contract:

```
features/<feature>/
├── presentation/
│   ├── screen/     # ScopeScreen entry points
│   ├── section/    # Composed UI regions
│   ├── widget/     # Reusable, domain-logic-free components
│   └── state/      # StreamState subclasses
├── domain/
│   ├── controller/ # Orchestrates use cases
│   └── repository/ # Abstract interfaces
└── data/
    ├── repository/ # Concrete implementations
    └── datasource/ # Remote (HTTP) data sources
```

---

## Architecture Notes

- **State management:** `StreamState` + `StreamStateBuilder` only.
- **DI:** Custom service locator in `core/di/`. No GetIt.
- **Backend:** NestJS REST API. All business logic lives there.
- **Desktop-only:** Windows is the primary and only supported platform.
