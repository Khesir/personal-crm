# Avyn

A personal desktop app combining project/issue tracking (kanban) with a local AI agent ("Home chat") that has persistent memory, tool access, and a local Python agent server.

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

**Agent**:
The local Python/FastAPI server running on the user's machine that implements the tool-use loop — receives a message, injects memory/persona, calls the LLM, executes tool calls, streams events back, repeats until done. Replaces the former `agent_run` skill runner. Accessible from multiple surfaces (Flutter dock pane, Discord, Telegram) via thin adapters.
_Avoid_: Agent mode (former Home chat concept, retired), skill runner, agent service

**Agent loop**:
The core execution cycle inside the Agent: model decides → calls tool → gets result → streams event → repeat until the model signals done. One loop per user message. Streams events in the Python server's native format — Flutter adapts to that format, not the other way around.

**Agent surface**:
Any client that can send messages to the Agent and render its streamed responses — Flutter dock pane, Discord bot, Telegram bot. Each surface is a thin adapter; the loop itself is surface-agnostic.

**Agent server**:
The local Python/FastAPI process serving the agent loop at `localhost:8765` by default. Port is configurable in settings. Flutter spawns it on launch, detects if already running via a health check (`/health`), and connects. Runs as a background process while a loop is active.

**Chat pane**:
The unified agent chat surface in the kanban dock — replaces the former separate Agent pane and Chat pane, which are merged since chat and agent are interchangeable (the LLM always has tools available, it simply chooses whether to use them). The dock now has two panes: Chat and Terminal. Chat contains a message input, scrollable conversation transcript, and inline event rendering (thinking steps, tool calls, results as collapsible items within the assistant's turn).

**Agent data directory**:
All agent runtime files (PID file, `agent.db`, ChromaDB data, research output) live at `%APPDATA%\Avyn\agent\` on Windows. Isolated from the install directory, survives app updates.

**Agent location**:
The Python agent server lives inside the `crm` repo at `agent/` — a sibling to `lib/` (Flutter app). The `crm` repo owns both the Flutter UI and the local agent server. `keep-track/` is not a repo — each subfolder is its own independent git repo.

**Agent idle timeout**:
The agent server self-terminates after 10 minutes of no active loop and no Flutter connection. Flutter calling `POST /shutdown` triggers immediate clean shutdown. If Flutter closes while a loop is active, the server completes the loop then starts the idle timer.

**System tray**:
Flutter owns the Windows system tray icon via `tray_manager`. When the user closes Avyn while an agent loop is active, Flutter minimizes to tray instead of quitting. Tray menu: Open Avyn, Agent status (running/idle), Stop agent, Quit. The tray icon represents the whole app — not the Python agent server.

**Agent packaging**:
The Python agent server is compiled to a self-contained `.exe` via PyInstaller and bundled in the Flutter Windows installer. Users do not need Python installed. Prerequisites: Docker (for SearXNG) and Ollama.

**Agent streaming**:
The Python agent server streams events to Flutter via SSE (Server-Sent Events). Flutter opens a persistent SSE connection per loop run, receives events as they happen, and reconnects automatically if the server restarts. FastAPI serves SSE via `EventSourceResponse`.

**Working project (agent)**:
Optional project context sent with each agent message. When set, file and shell tools operate within that project's `localPath`. Can be null (general assistant mode, no file/shell access). Changeable at any time — switching projects takes effect on the next message, no session restart required.

**LLM provider**:
The LLM backend the agent loop calls. Configurable per user — supports local (Ollama) and cloud (OpenAI, Anthropic). The Python server abstracts all providers behind a common interface so the loop is provider-agnostic.

**Agent storage**:
The Python agent server persists data locally using SQLite (`agent.db`) for conversation history and session management, and ChromaDB for vector memory. Separate from Flutter's `shared_preferences` and the NestJS MongoDB backend.

**Brain injection**:
The Brain files (`identity.md`, `soul.md`, `memory.md`) loaded into the agent's system prompt at the start of each loop. Which files are injected is configurable — the user can toggle each on/off. Files are read from disk on every request so edits take effect without restarting the Agent server.

**Agent tools (v1)**:
The atomic functions the LLM can invoke during the agent loop: `web_search`, `web_fetch`, `shell`, `file_read`, `file_write`, `memory_read`, `memory_write`, `trigger_research`, `manage_research`. The LLM decides which tools to call and when — there are no pre-scripted sequences.

**Deep research**:
A multi-step pipeline the agent can trigger via `trigger_research`: query decomposition → SearXNG searches → page reading → synthesis → structured report with citations. Results are readable via `manage_research`. Adapted from Odysseus's research pipeline pattern.

**Working project**:
The `Project` (see Settings > Projects, `localPath`) selected for an agent session — the assistant has full read/write file access here, similar to Claude Code's working directory.
_Avoid_: Active project, sandbox

**Reference project**:
Any other registered `Project` the assistant can read files from during an agent session, for cross-project context (e.g. consulting the backend repo while working in the crm repo). Read-only — writes are never allowed outside the working project.
