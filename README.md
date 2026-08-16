<div align="center">

<img src="assets/icon.png" alt="Avyn" width="96" height="96"/>

# Avyn

A personal desktop app for tracking projects and issues as plain markdown files — a `.md`-based kanban board with a Discord-style project rail for switching between registered projects.

[![Flutter](https://img.shields.io/badge/Flutter-3.35-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9-0175C2?logo=dart)](https://dart.dev)
[![Version](https://img.shields.io/badge/version-1.0.0-informational)]()

</div>

---

## Features

- **Kanban board** — markdown-file issues with YAML frontmatter, inline raw-markdown editor, and an archive of completed cycles.
- **Project rail** — every registered project shown as a switchable icon (initials or a custom icon) down the left edge; a "+" button creates a new project folder or registers an existing one.
- **Project metadata (`.avyn/`)** — each project folder gets a hidden `.avyn/` folder holding its name, icon, and extensible settings, so it's portable and self-describing wherever the folder goes.
- **File watcher** — the board stays in sync with issue files edited on disk by any tool (e.g. Claude Code), no manual refresh needed.

---

## Prerequisites

| Tool | Version |
|---|---|
| Flutter SDK | 3.35+ |

---

## Getting Started

```bash
flutter pub get
flutter run -d windows
```

---

## Project Structure

```
lib/
├── core/           # DI, state, theme, shared widgets
└── features/
    ├── shell/      # App shell — project rail, settings sidebar
    ├── kanban/     # Board, issue editor, file watcher
    └── settings/   # Project registry, project metadata, about
```
