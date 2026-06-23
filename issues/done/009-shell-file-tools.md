---
id: issue-009
title: "shell + file_read + file_write tools"
feature: agent
status: done
created_at: 2026-06-16
tags: [afk, p2]
---

# [009] shell + file_read + file_write tools

**Type:** AFK
**Priority:** P2
**Blocked by:** 004
**User stories covered:** 4, 5, 6

---

## What to build

Add three tools to the agent loop: `shell`, `file_read`, and `file_write`. All three are scoped to the working project's `local_path`. If `local_path` is null (general-purpose mode), all three tools return an error result — they are unavailable without a working project.

**shell** — executes a shell command in the working project directory. Input: `{"command": "string"}`. Returns `{stdout, stderr, exit_code}`. Commands run with a 30-second timeout — if exceeded, the process is killed and an error result is returned. On Windows, commands run via `cmd.exe /c`.

**file_read** — reads a file relative to `local_path`. Input: `{"path": "string"}`. Returns the file content as a string. Rejects paths that escape `local_path` via `..` traversal (returns error result). Truncates files larger than 50,000 chars with a notice.

**file_write** — writes content to a file relative to `local_path`. Input: `{"path": "string", "content": "string"}`. Creates parent directories if needed. Rejects paths that escape `local_path`. Returns `{success: true}` on completion.

All three emit `tool_call` and `tool_result` SSE events.

---

## Acceptance criteria

- [ ] `shell` runs commands in `local_path` and returns stdout/stderr/exit_code
- [ ] `shell` enforces a 30-second timeout
- [ ] `file_read` reads files relative to `local_path` and rejects path traversal
- [ ] `file_write` writes files relative to `local_path` and rejects path traversal
- [ ] All three return error results (not crashes) when `local_path` is null
- [ ] All three emit `tool_call` + `tool_result` SSE events
- [ ] Path traversal attempts (`../../../etc/passwd`) are rejected

---

## Tests required

Yes — use temp directories:
- `shell`: assert command output returned correctly; assert timeout kills long-running commands
- `file_read`: assert correct content returned; assert path traversal rejected
- `file_write`: assert file written to disk; assert path traversal rejected
- All three: assert error result when `local_path` is null

---

## Notes

The `shell` tool has the same OS-permission risk profile as the PTY terminal (ADR-0004) — no additional sandboxing beyond `local_path` scoping. This is by design and consistent with the existing terminal pane behaviour.

---

## Log

Implemented 2026-06-19. Created tools/filesystem.py with shell (30s timeout, cmd.exe/bash), file_read (path traversal guard, 50k traversal guard), file_write (mkdir -p, traversal guard). Updated main.py to call set_local_path per request. test_filesystem.py: all tests passing.

QA approved by user on 2026-06-24.
