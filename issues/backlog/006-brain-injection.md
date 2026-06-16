---
id: issue-006
title: "Brain injection into system prompt"
feature: agent
status: backlog
created_at: 2026-06-16
tags: [afk, p2]
---

# [006] Brain injection into system prompt

**Type:** AFK
**Priority:** P2
**Blocked by:** 004
**User stories covered:** 12, 13

---

## What to build

At the start of each agent loop run, the Python server reads the Brain files (`identity.md`, `soul.md`, `memory.md`) from the Brain folder and prepends their content to the LLM's system prompt.

The Brain folder path is passed in the `/chat` request body alongside the message. Flutter knows the Brain folder path (it already uses it for Home chat). Add a `brain_path` field to the request:

```json
{
  "session_id": "...",
  "message": "...",
  "local_path": "...",
  "brain_path": "string | null",
  "brain_files": ["identity", "soul", "memory"]
}
```

`brain_files` is the list of files to inject — the user can toggle each on/off in settings. The server reads only the listed files. Files are read fresh on every request — edits take effect without restarting the server. If `brain_path` is null or a file is missing, that file is silently skipped.

Brain files are read from the `dev` or `prod` subfolder based on the current data namespace (passed as part of `brain_path`).

---

## Acceptance criteria

- [ ] Brain files listed in `brain_files` are read from `brain_path` and prepended to the system prompt
- [ ] Files missing from disk are silently skipped (no error)
- [ ] Brain files are read fresh on every request (no caching)
- [ ] Removing a file from `brain_files` stops it being injected on the next request
- [ ] `brain_path: null` results in no Brain injection (general-purpose mode)

---

## Tests required

Yes — write Brain files to a temp directory, call `/chat` with `brain_path` pointing to it, mock the LLM and assert the system prompt contains the expected Brain content. Test with a missing file — assert the loop still runs.

---

## Notes

Brain files follow ADR-0002 dev/prod separation — the `brain_path` passed by Flutter already includes the correct namespace subfolder. The Python server does not need to know about namespaces directly.

---

## Log

_Updated as work progresses._
