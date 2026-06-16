---
id: issue-010
title: "memory_read + memory_write tools"
feature: agent
status: backlog
created_at: 2026-06-16
tags: [afk, p2]
---

# [010] memory_read + memory_write tools

**Type:** AFK
**Priority:** P2
**Blocked by:** 004
**User stories covered:** 7

---

## What to build

Add two tools to the agent loop: `memory_read` and `memory_write`. These allow the LLM to read and update the Brain files (`identity.md`, `soul.md`, `memory.md`) during a loop run.

The Brain folder path is already passed in the `/chat` request body as `brain_path` (added in issue 006). These tools use that same path.

**memory_read** — reads one or more Brain files. Input: `{"files": ["identity" | "soul" | "memory"]}`. Returns a map of `{filename: content}` for each requested file. Missing files return `null` for that key, not an error.

**memory_write** — writes content to a Brain file. Input: `{"file": "identity" | "soul" | "memory", "content": "string"}`. Overwrites the entire file. Returns `{success: true}`. If `brain_path` is null, returns an error result.

Both tools emit `tool_call` and `tool_result` SSE events.

---

## Acceptance criteria

- [ ] `memory_read` reads requested Brain files and returns their content
- [ ] `memory_read` returns null for missing files without error
- [ ] `memory_write` overwrites the specified Brain file with new content
- [ ] `memory_write` returns an error result when `brain_path` is null
- [ ] Both tools emit `tool_call` + `tool_result` SSE events
- [ ] Changes written by `memory_write` are reflected in the next Brain injection (since files are read fresh each request)

---

## Tests required

Yes — write Brain files to a temp directory:
- Assert `memory_read` returns correct content for existing files
- Assert `memory_read` returns null for missing files
- Assert `memory_write` overwrites file content on disk
- Assert `memory_write` returns error when `brain_path` is null

---

## Notes

`memory_write` overwrites the whole file — the LLM must include the full desired content in the `content` field, not just a diff. This keeps the tool simple and predictable.

---

## Log

_Updated as work progresses._
