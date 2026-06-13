# 3. Store brain files as app-local markdown, not shared_preferences

## Status

Accepted

## Context

The "brain" feature gives Home chat persistent identity/personality/memory via
three files (`identity.md`, `soul.md`, `memory.md`) injected into the system
prompt on every request. All other local app state in `crm` is currently
stored in `shared_preferences` (project registry, chat history, env
overrides), namespaced `dev`/`prod` via `kDataNamespace`.

## Decision

Store the brain files as plain markdown files on disk under
`%APPDATA%/Codex/brain/<dev|prod>/`, resolved via `Platform.environment['APPDATA']`
(no new dependency — `path_provider` is not used in this app). `shared_preferences`
was rejected for this case.

## Consequences

### Positive

- The files are directly editable in any text editor — no in-app editor UI
  needed for v1.
- File-based storage is the natural interface for agentic tooling. A future
  tool-using Home chat (see
  [handoff-home-chat-agent-mode.md](../handoffs/handoff-home-chat-agent-mode.md))
  can read/update its own `memory.md` with the exact same `read_file`/`edit_file`
  tools it uses for general tasks — no bespoke "update my memory" API.

### Negative / Risks

- Breaks from the "everything is shared_preferences" precedent — this is the
  first feature in `crm` to read/write app-owned files directly (separate from
  `kanban`, which reads/writes files inside user-registered *project*
  directories, not app-owned state).
- `kDataNamespace` dev/prod separation must be replicated as a subfolder
  (`brain/dev/` vs `brain/prod/`) rather than reusing the existing key-prefix
  mechanism.

## Alternatives Considered

- **`shared_preferences`** — consistent with existing persistence, dev/prod
  separation comes free via `kDataNamespace` key prefixes, but content becomes
  an opaque string blob requiring a dedicated in-app editor, and is unusable by
  future file-based agent tooling without a translation layer.
