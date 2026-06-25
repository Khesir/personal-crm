<div align="center">

<img src="assets/icon.png" alt="Avyn" width="96" height="96"/>

# Avyn

A personal desktop app combining project/issue tracking (kanban) with a
local AI agent — persistent memory, tool access, and a self-hosted agent
server.

[![Flutter](https://img.shields.io/badge/Flutter-3.35-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9-0175C2?logo=dart)](https://dart.dev)
[![Python](https://img.shields.io/badge/Python-agent%20server-3776AB?logo=python)](https://python.org)
[![Version](https://img.shields.io/badge/version-1.0.0-informational)]()

</div>

---

> Desktop-first today. See [ROADMAP.md](ROADMAP.md) for where this is headed —
> self-hosted web access, a built-in code editor, and a plugin system.

---

## What it is

Avyn is a desktop shell built around one project at a time, with a kanban
board as the home base and a dockable workspace underneath it:

- **Kanban board** — projects/issues live as plain markdown files with
  YAML frontmatter, organized into `backlog/ready/in-progress/qa/done`
  folders. Board view, a detail view with an inline raw-markdown editor,
  and read-only viewing of archived past cycles.
- **A docked terminal and agent chat, alongside the board** — not
  separate full-screen tabs. The board's dock can open a real PTY-backed
  terminal and an AI agent chat pane at the same time the board itself is
  visible, resizable and collapsible, so you can watch the agent work,
  drop into a shell, and see the board update, all in one view.
- **A local, self-hosted Python agent server** (`agent/`) — runs
  alongside the app on `localhost:8765`, holds the assistant's persistent
  memory ("the brain"), and runs the actual tool-use loop: the model
  decides, calls a tool (file read/write, shell, web search/fetch,
  research), gets a result, streams an event back, repeats until done.

Flutter and the agent server are separate processes by design — Flutter
spawns the agent server on launch (or connects to one already running)
and talks to it over HTTP/SSE, the same shape this app is moving toward
supporting remotely (see the roadmap).

---

## Features

- **Kanban board** — markdown-file issues with YAML frontmatter, an
  inline raw-markdown editor (Write/Preview tabs, formatting toolbar),
  and an archive of completed feature cycles.
- **Unified dock** — toggle a real terminal and/or an agent chat pane
  open *alongside* the kanban board, in one resizable dock, instead of
  switching between full-screen tabs.
- **Home chat** — a full-screen version of the same agent chat, with a
  model picker and a session sidebar, for when you're not anchored to a
  specific project's board.
- **Local agent server** — persistent memory (`identity.md`/`soul.md`/
  `memory.md`), a working-project file/shell sandbox, deep research, and
  tool calls rendered inline in the chat as they happen.
- **Multi-provider LLM support** — Anthropic, OpenAI, local Ollama, and
  several other API providers, each configurable with its own
  enable/default/health-check in Settings.
- **Settings** — manage registered projects, configure LLM providers,
  download/manage local models, and edit the brain's memory files.

---

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Flutter SDK | 3.35+ | `flutter --version` to check |
| Dart SDK | 3.9+ | Included with Flutter |
| Python | 3.11+ | Powers the local agent server (`agent/`) |
| Docker | latest | Only needed for deep research (SearXNG) |
| Ollama | latest | Optional — only if you want a local LLM provider |

---

## Getting Started

### 1. Install Flutter dependencies

```bash
flutter pub get
```

### 2. Set up the agent server

```bash
cd agent
pip install -r requirements.txt
```

The Flutter app spawns `agent/main.py` automatically on launch (or
connects to one already running via its `/health` check) — no separate
step needed to start it by hand during development.

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
│   ├── di/         # Custom service locator (no GetIt)
│   ├── state/      # StreamState + StreamStateBuilder
│   ├── theme/      # AppStyling/AppColors — colors, text styles
│   ├── cache/      # Hive (local-first data store)
│   └── ui/         # Shared widgets (ScopeScreen, desktop title bar)
└── features/
    ├── shell/      # App shell — rail (Home/Projects/Settings), sidebar
    ├── kanban/      # Board, issue editor, and the docked terminal/chat
    ├── home/        # Home chat — full-screen agent chat surface
    ├── agent/       # Agent server lifecycle/status (surfaced in Settings)
    ├── brain/       # Persistent-memory file management (no own UI)
    └── settings/    # Projects, LLM providers, model discovery, brain

agent/
├── main.py          # FastAPI app — /chat, /sessions, /health, /shutdown
├── providers/       # Anthropic / OpenAI / Ollama, behind one interface
├── tools/           # filesystem, shell, memory, web, research
├── brain.py         # Loads identity/soul/memory into the system prompt
├── db.py            # SQLite — conversation/session history
└── vector.py        # ChromaDB — vector memory
```

Each Flutter feature follows the standard folder contract:

```
features/<feature>/
├── presentation/
│   ├── screen/     # ScopeScreen entry points
│   ├── section/    # Composed UI regions
│   ├── widget/     # Reusable, domain-logic-free components
│   ├── dialogs/    # Dialogs specific to the feature
│   └── state/      # StreamState subclasses
├── domain/
│   ├── controller/ # Orchestrates use cases
│   ├── helper/      # Pure functions — no widget/IO dependency
│   └── repository/ # Abstract interfaces
└── data/
    ├── repository/ # Concrete implementations
    └── datasource/ # Remote (HTTP) / local (Hive) data sources
```

---

## Architecture Notes

- **State management:** `StreamState` + `StreamStateBuilder` only.
- **DI:** Custom service locator in `core/di/`. No GetIt, BLoC, Riverpod.
- **Offline-first:** Hive is the local source of truth; nothing in the
  app today depends on a remote backend to function.
- **Agent server:** separate local process, provider-agnostic LLM loop,
  SQLite + ChromaDB for its own storage — isolated from Flutter's
  `shared_preferences`.
- **Desktop-first:** Windows is the primary supported platform today.
  Web support is planned — see [ROADMAP.md](ROADMAP.md).
