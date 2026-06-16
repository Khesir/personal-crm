---
id: issue-017
title: "PyInstaller packaging"
feature: agent
status: backlog
created_at: 2026-06-16
tags: [hitl, p3]
---

# [017] PyInstaller packaging

**Type:** HITL
**Priority:** P3
**Blocked by:** 004, 005, 006, 007, 008, 009, 010, 012
**User stories covered:** 37

---

## What to build

Compile the Python agent server into a self-contained Windows `.exe` using PyInstaller so users do not need Python installed.

Add a `build.spec` (PyInstaller spec file) in `agent/` that bundles `main.py` and all dependencies into a single `.exe`. The output should go to `agent/dist/avyn-agent.exe`.

Verify that the compiled `.exe`:
- Starts correctly on a machine without Python installed
- Writes the PID file to `%APPDATA%\Avyn\agent\agent.pid`
- Responds to `GET /health`
- Accepts and responds to `POST /chat` with a real LLM configured

Add a build script (`agent/build.ps1` or `agent/Makefile`) so the `.exe` can be rebuilt with a single command. Document the build step in `agent/README.md`.

This issue is HITL because it requires manual verification on a clean Windows machine (or VM) without Python installed.

---

## Acceptance criteria

- [ ] `pyinstaller build.spec` produces `agent/dist/avyn-agent.exe`
- [ ] `.exe` starts and responds to `GET /health` on a machine without Python
- [ ] PID file is written to `%APPDATA%\Avyn\agent\agent.pid`
- [ ] `POST /chat` works end-to-end with a configured LLM provider
- [ ] Build is reproducible via a single script command
- [ ] `agent/README.md` documents the build step

---

## Tests required

No automated tests — manual verification on a clean Windows environment is the acceptance gate.

---

## Notes

PyInstaller bundles can be large (~150–300MB). This is expected and acceptable. The `.exe` is not committed to git — it is a build artifact. The `agent/dist/` directory should be in `.gitignore`.

---

## Log

_Updated as work progresses._
