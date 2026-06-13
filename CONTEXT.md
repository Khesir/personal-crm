# CRM (Codex / Dev Command Center)

A personal desktop app combining project/issue tracking (kanban) with an AI assistant ("Home chat") that can be extended with persistent memory and tooling.

## Language

**Brain**:
The persistent-memory subsystem for Home chat — an app-local folder of markdown files (`identity.md`, `soul.md`, `memory.md`) plus the logic that loads them into the assistant's context.
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

**Home chat**:
The in-app chat surface (`lib/features/home`) — the primary AI assistant surface, intended to grow Claude-Code-like tooling (file access, running tasks) in a later effort. The brain feeds this surface.
