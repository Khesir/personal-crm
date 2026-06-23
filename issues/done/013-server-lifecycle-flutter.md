---
id: issue-013
title: "Server lifecycle — Flutter spawns, PID check, reconnect"
feature: agent
status: done
created_at: 2026-06-16
tags: [afk, p2]
---

# [013] Server lifecycle — Flutter spawns, PID check, reconnect

**Type:** AFK
**Priority:** P2
**Blocked by:** 002, 005
**User stories covered:** 22, 29

---

## What to build

Implement the full lifecycle for how Flutter manages the agent server process. On app launch, Flutter must detect whether the server is already running and either reconnect or spawn a fresh process.

Lifecycle on launch:
1. Read `%APPDATA%\Avyn\agent\agent.pid`
2. If PID file exists and the process is alive → reconnect (poll `GET /health` once to confirm)
3. If PID file missing or process dead → spawn the agent server `.exe` as a child process, then poll `GET /health` every 500ms until it responds (timeout after 15 seconds)
4. If the server fails to start within 15 seconds → show an error state in `ChatPane`

Lifecycle on app close with no active loop:
- Call `POST /shutdown` and exit

Lifecycle on app close with an active loop:
- Minimise to tray instead (handled in issue 014) — this issue only covers the no-loop-active path

The agent server self-terminates after 10 minutes idle with no Flutter connection (implemented server-side: a watchdog timer resets on each `/chat` request and on `GET /health` pings; if 10 minutes pass with no activity, the server calls its own shutdown).

Create a `AgentServerManager` (or equivalent) in the Flutter `agent` feature to encapsulate this logic. It is not a widget — it is a service called from the app's startup path.

---

## Acceptance criteria

- [ ] On launch, Flutter reads the PID file and reconnects if the server is alive
- [ ] On launch, Flutter spawns the server if it is not running and waits for `/health`
- [ ] If the server fails to start in 15 seconds, `ChatPane` shows an error state
- [ ] On clean close (no loop active), Flutter calls `POST /shutdown`
- [ ] Server self-terminates after 10 minutes idle (watchdog on the Python side)
- [ ] No duplicate server processes are spawned when Flutter restarts quickly

---

## Tests required

Yes:
- Mock PID file with a live PID — assert Flutter reconnects without spawning
- Mock PID file with a dead PID — assert Flutter spawns a new process
- Mock server that never responds to `/health` — assert error state after 15 seconds
- Assert `POST /shutdown` is called on clean close

---

## Notes

The spawned process path points to the PyInstaller `.exe` bundled with the Flutter app. For development, use a configurable path override so the Python server can be run directly without PyInstaller.

---

## Log

Implemented 2026-06-18. Created AgentServerManager service (PID check, process spawn, health poll, shutdown). Added AgentServerStatus enum and serverStatus field to AgentStateData. ChatPane shows starting/failed states. App exit handler calls shutdown when no loop active.

QA approved by user on 2026-06-24.
