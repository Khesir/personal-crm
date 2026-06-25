# Roadmap

This is the long-term direction for Avyn, beyond what's built today. It's a
living document — phases aren't committed dates, they're the order things
need to happen in because of what each one depends on.

**Where this is going, in one sentence:** Avyn becomes a self-hosted,
agent-driven coding environment — chat/agent pane + a simple built-in code
editor as the core, deployable to your own VPS or run locally, with
everything else (starting with the kanban board) becoming an optional
plugin on top of that core.

---

## Today

- Desktop-only (Windows primary), Flutter app + local Python agent server
  on the same machine, talking over `localhost:8765`.
- Kanban, Home chat, Settings are all built-in, hardcoded features — no
  separation between "core" and "extension" exists yet.
- The agent server has no authentication — it assumes it's only ever
  reachable by the one trusted user on that machine.

---

## Phase 1 — Self-hosted, remote access

**Goal:** run Avyn on your own VPS and use it from a browser, the same way
you'd use code-server or a cloud IDE — develop against a project that lives
on that server, not on your laptop.

- **Deployment model:** self-hosted, single-tenant. Each user runs their
  own instance on their own box. Not a multi-tenant SaaS — that would need
  a real account/auth/isolation model this doesn't try to solve yet.
- **Auth:** a single shared passphrase, set via env var at deploy time,
  enforced *inside the agent server itself* (not by a reverse proxy) so
  there's no way to expose it on the open internet unprotected. If no
  passphrase is configured, the gate is skipped entirely — desktop usage
  is unaffected.
- **Web client:** the same Flutter codebase, compiled to a web target —
  not a separate frontend. Desktop-only chrome (custom title bar, system
  tray) is conditionally hidden on web; the browser already provides that
  chrome.
- **Terminal:** the PTY backing the terminal pane moves into the Python
  agent server (one implementation, reached over a websocket) instead of
  spawning locally via `flutter_pty`. Desktop talks to its own local agent
  server the same way web talks to a remote one — same code path either
  way.
- **Claude Code / Codex usage:** through that terminal, as real CLI
  sessions — not through the agent's own tool-calling loop. The agent's
  existing `shell` tool has a 30s timeout and is built for one-shot
  commands; Claude Code/Codex are interactive sessions that don't fit that
  shape. The built-in agent loop and "running Claude Code" stay two
  separate things.
- **Code editor (v1 scope):** a single-file, syntax-highlighted editor
  plus a file tree to switch between files in the project. No tabs, no
  diff view yet — v1 is about *seeing and tweaking* what the agent
  changed, not competing with a full IDE on day one.
- **LLM providers on a VPS:** already supported — `agent/providers/`
  already abstracts Anthropic/OpenAI/Ollama behind one interface, so
  running Ollama on the VPS itself is a deployment/hardware choice
  (CPU-only VPS = limited model size), not a code change.

---

## Phase 2 — Plugin system (v1)

**Goal:** let real code — written in any language — add new panels to the
app, the way an Obsidian plugin (e.g. Graph view) adds a new sidebar icon
and view, without needing to know Dart/Flutter at all.

**Why this isn't a "normal" plugin system:** Dart/Flutter has no supported
way to load new compiled UI code into a running release build — no
`dlopen`-style hot loading, nothing on web, and dynamic code execution is
against iOS App Store policy outright. A VSCode/Obsidian-style live
install (download a plugin, it just works, no restart) isn't achievable
without a multi-month investment in something like a WASM-sandboxed UI
runtime. That's explicitly **not** what Phase 2 builds.

**What Phase 2 actually builds instead:**

- A plugin is a **manifest + an independent local process + a webview
  panel** — not compiled-in Dart code:
  - `plugin.yaml` — rail icon, label, and how to launch the plugin (a
    command, or a port if it's already running).
  - The plugin itself is any language — it just needs to serve a small
    local web server (its own HTML/CSS/JS).
  - The shell embeds that plugin's UI via a native webview (desktop) or
    an `<iframe>` (web), pointed at the plugin's URL.
- **Discovery is restart-based, not live.** The app scans a `plugins/`
  folder at startup, launches each declared plugin, and adds its rail
  item. "Installing" a plugin means dropping its folder in and restarting
  — not a hot, no-restart install. This is the actual achievable version
  of "feels like installing a VS extension," given Dart's constraints.
- **Process lifecycle + reverse proxy live in the agent server**, for both
  desktop and web. This isn't optional for the web case: a browser on your
  laptop can't start a process on the VPS, and can't reach
  `localhost:<port>` *on the VPS* — only the agent server's already-public
  HTTPS endpoint is reachable, so plugin traffic rides through it,
  proxied under `/plugins/<name>/...`. Desktop uses the same path against
  its own local agent server, so there's one implementation, not two.
- **Theming is CSS-only for v1.** Plugin authors get a static CSS/design-
  token package mirroring `AppStyling`/`AppColors` (colors, spacing, type)
  to reference in their own HTML — no required JS framework, no build
  step. Whether this grows into real prebuilt JS/web components is an
  open question, deliberately deferred until a handful of real plugins
  exist and show what's actually needed.
- **No host API in v1.** A plugin only ever gets the project's file path
  — it has no way to ask "what file is currently open" or react to
  anything else happening in the shell. Both reference examples (Obsidian
  Graph view, the kanban board itself) are fully file/folder-driven and
  need nothing more than that. A host API is a real, lasting commitment —
  better designed later from a second real plugin's actual needs than
  guessed at now.
- **`skills.md` is separate and simpler.** A plugin can optionally ship a
  `skills.md` the Python agent server reads directly (same pattern as
  Claude Code's own skill files) to extend what the agent can reference.
  This needs no process, no manifest, no proxy — just a file on disk.
- **Plugin registry:** a manually-curated list (name, description, git
  URL) in a markdown/JSON file — no submission pipeline, no
  infrastructure. A user clones a plugin into their own `plugins/` folder
  and restarts.

---

## Phase 3 — Kanban becomes the proof point

**Goal:** migrate the existing, built-in kanban board to actually run as
one of Phase 2's plugins.

Kanban is the natural dogfood candidate — it's already simple,
self-contained, and purely file/folder-driven (`issues/*.md` with YAML
frontmatter), with zero dependency on the agent loop. If kanban never
moves to the plugin mechanism, the "plugins" pitch rings hollow — a plugin
system none of the app's own features use. This phase doesn't have to
happen immediately after Phase 2 ships, but it's the validation that the
mechanism actually works for a real, non-trivial feature.

---

## Explicitly out of scope (for now)

- **Multi-tenant SaaS.** Self-hosted single-tenant is the model. A shared
  multi-user service is a different problem (real accounts, isolation,
  billing) that would be its own future phase, not an extension of this
  one.
- **Live, no-restart plugin installs.** Blocked by Dart/Flutter's lack of
  dynamic code loading. Revisit only if a WASM-sandboxed UI runtime
  becomes a realistic, scoped project of its own.
- **A host API for plugins.** Deferred until real plugins exist to design
  it against.
- **A JS/web-component plugin SDK.** Deferred for the same reason — CSS
  tokens are enough until there's evidence more is needed.
- **Multi-file tabs / diff view in the code editor.** Natural v2 editor
  work, not required to prove out the core agent+editor loop.
