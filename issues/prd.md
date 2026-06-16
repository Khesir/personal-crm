# PRD: Avyn Agent — Local AI Agent Loop

**Status:** Draft
**Date:** 2026-06-16

---

## Problem Statement

Avyn's current agent feature (`agent_run`) is a broken script runner — the user picks a hardcoded skill from a dialog, the backend executes a fixed sequence, and a streaming log is displayed. There is no LLM driving the loop, no memory, no tools, no persona, and no conversational interface. It does not behave like an AI agent in any meaningful sense, and it is not functional.

Additionally, the Chat pane and Agent pane in the kanban dock are two separate surfaces doing overlapping jobs, creating unnecessary complexity in both the code and the UI.

---

## Solution

Replace the entire `agent_run` feature with **Avyn Agent** — a local Python/FastAPI server that runs on the user's machine and implements a real LLM-driven tool-use loop. The loop receives a message, injects the Brain's persona and memory into the system prompt, calls the configured LLM, executes whatever tools the model requests, streams each event back to Flutter via SSE, and repeats until the model signals it is done.

Flutter becomes a pure streaming UI. The agent loop, tool execution, memory, and LLM calls all live in the Python server. The Chat pane and Agent pane in the dock are merged into a single unified Chat pane — because chat and agent are the same thing once the LLM has tools available.

The agent server runs locally like Ollama: the user installs Avyn, the server starts automatically, nothing is hosted externally.

---

## User Stories

1. As a user, I want the agent to respond conversationally to my messages so that I can interact with it naturally without picking from a skill menu.
2. As a user, I want the agent to search the web so that it can answer questions about current events and topics outside its training data.
3. As a user, I want the agent to fetch and read the content of a URL so that I can ask it to summarise or analyse any web page.
4. As a user, I want the agent to run shell commands scoped to my working project so that it can execute tasks in my codebase on my behalf.
5. As a user, I want the agent to read files from my working project so that it can answer questions about my code.
6. As a user, I want the agent to write files to my working project so that it can make changes to my codebase directly.
7. As a user, I want the agent to read and update my Brain files so that its memory and persona stay current as I work.
8. As a user, I want the agent to trigger a deep research pipeline so that I can get a thorough, cited report on any topic.
9. As a user, I want to read the results of a deep research run so that I can review what the agent found.
10. As a user, I want to see the agent's thinking steps as they happen so that I understand what it is doing.
11. As a user, I want to see each tool call and its result inline in the conversation so that I can follow the agent's reasoning.
12. As a user, I want the agent to use my Brain files (identity, soul, memory) as its persona so that it behaves consistently with how I have configured it.
13. As a user, I want to toggle which Brain files are injected into the agent's context so that I can control how much persona context it receives.
14. As a user, I want conversation history to persist across sessions so that I can resume a past conversation with the agent.
15. As a user, I want to start a new conversation session so that I can begin a fresh context without losing past sessions.
16. As a user, I want to switch between past conversation sessions so that I can return to earlier work.
17. As a user, I want to choose between a local LLM (Ollama) and cloud providers (OpenAI, Anthropic) so that I can balance privacy and capability.
18. As a user, I want to configure the agent's LLM provider in settings so that I can change the model without restarting the server.
19. As a user, I want to use the agent without selecting a working project so that I can have a general-purpose assistant conversation.
20. As a user, I want to select a working project for the agent so that its file and shell tools are scoped to that project's directory.
21. As a user, I want to switch the working project mid-conversation so that I can move between projects without starting a new session.
22. As a user, I want the agent server to start automatically when I launch Avyn so that I do not need to start it manually.
23. As a user, I want the agent server to keep running if I close Avyn while a loop is active so that long-running tasks complete without interruption.
24. As a user, I want Avyn to appear in the Windows system tray when minimised so that I know it is still running.
25. As a user, I want to see the agent's current status (running / idle) in the system tray so that I can tell at a glance whether a loop is active.
26. As a user, I want to open Avyn from the system tray so that I can return to the UI quickly.
27. As a user, I want to stop the agent from the system tray so that I can cancel a running loop without opening the app.
28. As a user, I want the agent server to shut down cleanly when I quit Avyn and no loop is running so that it does not linger in the background unnecessarily.
29. As a user, I want the agent server to self-terminate after 10 minutes of idle time with no Flutter connection so that it does not consume resources indefinitely.
30. As a user, I want the Chat pane in the kanban dock to serve as both a chat and agent surface so that I do not need to switch between two separate panes.
31. As a user, I want the dock to have two panes — Chat and Terminal — so that the layout is simpler than before.
32. As a user, I want the agent server to run on a fixed default port (8765) so that it is predictable and easy to configure.
33. As a user, I want to override the agent server port in settings so that I can resolve conflicts with other local services.
34. As a user, I want web search powered by my local SearXNG instance so that my searches are private and self-hosted.
35. As a user, I want the agent to use ChromaDB for vector memory so that it can semantically retrieve relevant context from past interactions.
36. As a user, I want conversation history stored in a local SQLite database so that my data never leaves my machine.
37. As a user, I want the agent server packaged as a self-contained executable so that I do not need to install Python to use Avyn.

---

## Implementation Decisions

### Deletion of existing agent_run feature
The entire `features/agent_run/` module, `agent_pane.dart`, and all `SkillPickerDialog` / `AgentRunScreen` code is deleted. Git history is the archive. The `DockPane.agent` enum value is removed; the dock has two panes: `terminal` and `chat`.

### Python agent server location
Lives at `agent/` inside the `crm` repo — a sibling to `lib/`. The `crm` repo owns both the Flutter UI and the agent server.

### Agent server tech stack
- Python 3.11+, FastAPI, uvicorn
- SSE streaming via `EventSourceResponse`
- SQLite (`agent.db`) for conversation history and session management
- ChromaDB for vector memory
- LLM abstraction layer supporting Ollama, OpenAI, and Anthropic — provider selected per user config, loop is provider-agnostic

### Agent data directory
All runtime files (PID file, `agent.db`, ChromaDB data, research output) stored at `%APPDATA%\Avyn\agent\` on Windows.

### Agent loop
Classic tool-use loop: receive message → build system prompt (Brain injection + conversation history) → call LLM → parse tool calls → execute tool → emit SSE event → feed result back to LLM → repeat until model signals done. One loop per user message.

### SSE event format
The Python server defines its own native SSE event schema. Flutter adapts to that format — the existing sealed event types (`AgentThinking`, `AgentToolUse`, `AgentToolResult`, `AgentResult`) are replaced with new types derived from the Python server's output shape. Events streamed as `text/event-stream`.

### Tools (v1)
Nine tools available to the LLM:
- `web_search` — queries local SearXNG instance, returns structured results
- `web_fetch` — fetches and reads a URL's content
- `shell` — executes a shell command scoped to the working project's `localPath`
- `file_read` — reads a file within the working project
- `file_write` — writes a file within the working project
- `memory_read` — reads one or more Brain files (`identity.md`, `soul.md`, `memory.md`)
- `memory_write` — writes to a Brain file
- `trigger_research` — starts the deep research pipeline (query decomposition → SearXNG → synthesis → report)
- `manage_research` — reads deep research results

### Brain injection
At the start of each loop, the agent server reads `identity.md`, `soul.md`, and `memory.md` from disk and prepends them to the system prompt. Which files are injected is configurable per user (toggleable in settings). Files are read fresh on every request — edits take effect immediately without restarting the server.

### Conversation history
Each conversation is a Session stored in SQLite with a unique ID. The full message history for the active session is passed to the LLM on each turn. Flutter can list past sessions and resume any of them. Sessions are independent of working project — switching projects mid-session is allowed.

### Working project
Optional per-message field (`localPath`). When present, `shell` and file tools operate within that directory. When absent, the agent runs in general-purpose mode with no file/shell access. Flutter sends the currently selected project's `localPath` with each message; switching is immediate.

### Flutter agent feature
A new `features/agent/` module replaces `features/agent_run/`. Follows the standard module structure: `AgentController` (StreamState), `AgentRepository` (interface), `AgentRepositoryImpl` (SSE client), `AgentDatasource` (HTTP). `AgentController` owns the session ID, working project path, and event list. The `ChatPane` is rewritten to use `AgentController` directly — it is no longer a wrapper around `HomeChatSection`.

### Server lifecycle (Flutter side)
On app launch, Flutter checks `%APPDATA%\Avyn\agent\agent.pid` — if the PID is alive, it reconnects; otherwise it spawns the PyInstaller `.exe` as a child process and polls `GET /health` until the server is ready. On app close with no active loop, Flutter calls `POST /shutdown`. On app close with an active loop, Flutter minimises to tray. The server self-terminates after 10 minutes idle with no Flutter connection.

### System tray
Flutter owns the system tray icon via `tray_manager`. Closing the window while a loop is active minimises to tray instead of quitting. Tray menu: Open Avyn, Agent status (running / idle), Stop agent, Quit.

### Agent server packaging
The Python server is compiled to a self-contained `.exe` via PyInstaller and bundled in the Flutter Windows installer. Prerequisites: Docker (for SearXNG) and Ollama.

### Port
Default `8765`. Configurable in Avyn settings. Flutter always reads the port from settings, never hardcodes it.

### Agent server shutdown
`POST /shutdown` — immediate clean shutdown. Server self-terminates after 10 minutes idle with no active loop and no Flutter connection.

---

## Testing Decisions

Good tests assert observable external behaviour — what state the controller emits, what events arrive from the SSE stream, what the widget renders — not internal implementation details like which methods were called or how the loop iterates.

### Python agent server

- **Tool unit tests** — each tool function tested in isolation with mocked dependencies (mock SearXNG HTTP, mock filesystem). Assert correct output shape for known inputs.
- **Agent loop unit tests** — mock LLM provider that returns deterministic tool calls and a final done signal. Assert the correct sequence of SSE events is emitted and the loop terminates.
- **SSE endpoint integration test** — spin up the FastAPI test client, POST a message, assert the event stream contains events in the expected order and the connection closes when done.
- **Brain injection test** — mock Brain files on disk, assert their content appears in the system prompt passed to the LLM.

### Flutter

- **`AgentController` state machine** — fake `AgentRepository` that emits a controlled event stream. Assert `idle → running → done/error/stopped` transitions and that events accumulate correctly. Prior art: `test/features/agent_run/domain/controller/agent_run_controller_test.dart` (same fake-repository pattern, same `StreamState` assertions).
- **`AgentDatasource` SSE parsing** — mock HTTP server emitting raw SSE text. Assert events are parsed into the correct typed models.
- **`DockState` pane enum** — assert `DockPane` has exactly two values (`terminal`, `chat`), toggle logic still enforces minimum one active pane. Prior art: `test/features/kanban/presentation/state/dock_state_test.dart`.
- **`ChatPane` widget test** — assert message input renders, submitting a message emits the correct call to the controller, and event tiles appear in the transcript.

---

## Out of Scope

- Discord and Telegram adapters (v2, tracked in `docs/roadmap.md`)
- Kanban-specific agent tools (create issue, update issue, query board state) — deferred
- MCP server support
- Deep research model presets based on hardware
- Mobile or web support — agent server and system tray are desktop-only by construction
- Any changes to the NestJS Vercel backend
- Home chat agent mode — previously disabled, remains out of scope

---

## Further Notes

- SearXNG must be running via Docker for `web_search` and deep research to function. Avyn should surface a clear warning in the Chat pane when SearXNG is unreachable rather than silently failing.
- Ollama must be running for local LLM use. Same pattern — surface a clear warning when unreachable.
- The agent server's `shell` tool executes with the same OS permissions as the Avyn process. No sandboxing beyond the working project path restriction. This is consistent with ADR-0004's precedent (the PTY terminal has the same risk profile).
- The deep research pipeline is adapted from the Odysseus project's pattern (query decomposition → SearXNG searches → page reading → synthesis → structured report with citations). It is not a code fork.
- Brain files are read from the app-local Brain folder per `data_namespace` (dev/prod separation per ADR-0002).
