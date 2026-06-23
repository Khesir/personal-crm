---
id: issue-002
title: "Python agent server scaffold (FastAPI + /health + /shutdown)"
feature: agent
status: done
created_at: 2026-06-16
tags: [afk, p1]
---

# [002] Python agent server scaffold (FastAPI + /health + /shutdown)

**Type:** AFK
**Priority:** P1
**Blocked by:** None
**User stories covered:** 22, 28, 32

---

## What to build

Create the `agent/` directory at the root of the `crm` repo (sibling to `lib/`). This is the Python/FastAPI server that will eventually host the agent loop.

For this issue, the server only needs to start, respond to a health check, and shut down cleanly. No loop logic yet.

Endpoints required:
- `GET /health` — returns `{"status": "ok"}` with HTTP 200
- `POST /shutdown` — triggers clean uvicorn shutdown, returns `{"status": "shutting_down"}`

The server must:
- Run on port `8765` by default, overridable via a `--port` CLI argument or `AVYN_AGENT_PORT` environment variable
- Write its PID to `%APPDATA%\Avyn\agent\agent.pid` on startup and delete it on clean shutdown
- Create `%APPDATA%\Avyn\agent\` if it does not exist
- Log startup and shutdown to stdout

Include `requirements.txt` with `fastapi`, `uvicorn`, and `httpx` (for tests). Include a `README.md` in `agent/` describing how to run the server locally (`python main.py` or `uvicorn main:app`).

---

## Acceptance criteria

- [ ] `agent/` directory exists at repo root with `main.py`, `requirements.txt`, `README.md`
- [ ] `GET /health` returns `{"status": "ok"}` with HTTP 200
- [ ] `POST /shutdown` shuts down the server cleanly
- [ ] Server writes PID file to `%APPDATA%\Avyn\agent\agent.pid` on start
- [ ] PID file is deleted on clean shutdown
- [ ] Port defaults to `8765`, overridable via `--port` or `AVYN_AGENT_PORT`
- [ ] Server starts with `python main.py` or `uvicorn main:app --port 8765`

---

## Tests required

Yes — use FastAPI's `TestClient` to assert:
- `GET /health` returns 200 and `{"status": "ok"}`
- `POST /shutdown` returns `{"status": "shutting_down"}`

---

## Notes

Data directory is `%APPDATA%\Avyn\agent\` on Windows. Use `os.environ.get("APPDATA")` to locate it. Create it with `os.makedirs(..., exist_ok=True)` on startup.

---

## Log

Implemented 2026-06-18. Created agent/ directory with main.py (FastAPI, /health, /shutdown, PID file management), requirements.txt, test_main.py (TestClient tests passing), and README.md.