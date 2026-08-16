# Avyn

A personal desktop app for tracking projects and issues as plain markdown files — a `.md`-based kanban board, with a project rail for switching between registered projects.

## Language

**Brain**:
An app-local folder of markdown files (`identity.md`, `soul.md`, `memory.md`) — currently has no active consumer in the app (the AI agent that used to read it has been removed); kept as-is pending a decision on whether/how to revive it.
_Avoid_: Memory system (too generic on its own), vault (see Brain folder)

**Brain folder**:
The app-local, app-wide (not per-project) folder on disk holding the brain's markdown files — plain files editable in any text editor, not an Obsidian vault. Has separate `dev`/`prod` subfolders per [`kDataNamespace`](lib/core/config/data_namespace.dart).
_Avoid_: Vault (reserved for a possible future Obsidian-based long-term memory, out of scope for the brain PRD)

**Identity** (`identity.md`):
Factual/operational description of the assistant — who it is, its role/purpose, what it's allowed to do, current capabilities. Mostly static.

**Soul** (`soul.md`):
The assistant's personality and values — tone, communication style, behavioral traits. Can evolve over time as the user tunes how it talks to them.

**Memory** (`memory.md`):
Short-term/core memory — small, always loaded into the system prompt (e.g. user preferences, current focus).
_Avoid_: Long-term memory, notes (see Vault)

**Working project**:
The `Project` (see Settings > Projects, `localPath`) currently selected in the project rail — the board reads/writes issues under this path.
_Avoid_: Active project, sandbox

**Reference project**:
Any other registered `Project`, shown as a switchable icon in the project rail but not currently the working project. Kept for future cross-project features.

**Project rail**:
The leftmost icon strip in the app shell (`lib/features/shell/presentation/widget/app_rail.dart`) that lists every registered `Project` as a switchable icon, Discord-server-list style, plus a create/register action and a pinned Settings icon. Selecting a project icon makes it the working project and shows its board full-width. See `docs/adr/0003-discord-style-project-rail.md`.

**`.avyn/` folder**:
A hidden, app-owned metadata folder created inside every registered `Project`'s `localPath`, sibling to `issues/`. Holds `project.json` (the project's `id`, `name`, and an extensible `settings` object) and an optional `icon.<ext>` image file. Authoritative over the project's name/settings — unlike `issues/`, it is always auto-created (on both "create new" and "register existing" registration, and retroactively on first load for projects registered before this existed), and never requires an explicit "Initialize" step.
_Avoid_: Project config, project settings folder (use `.avyn/` folder or "project metadata")

**Project cache** (SharedPreferences):
`SharedPreferences` no longer stores full project data as the source of truth — it caches each registered `Project`'s `id`, `localPath`, and last-known `name` (and icon path once that lands), so the project rail can render instantly at startup without reading every project's `.avyn/project.json` from disk. The cache is refreshed from `.avyn/project.json` only when that specific project is visited (selected as the working project) — an unvisited project's cached name can be briefly stale if its `.avyn/project.json` was edited externally (e.g. by hand, or on another machine) until it's next selected.
