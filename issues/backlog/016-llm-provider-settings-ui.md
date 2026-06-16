---
id: issue-016
title: "LLM provider + port settings UI"
feature: agent
status: backlog
created_at: 2026-06-16
tags: [afk, p3]
---

# [016] LLM provider + port settings UI

**Type:** AFK
**Priority:** P3
**Blocked by:** 005
**User stories covered:** 17, 18, 33

---

## What to build

Add an Agent settings section to the existing settings screen where the user can configure the LLM provider, model, API key, and agent server port.

Settings exposed:
- **Provider** — dropdown: Ollama / OpenAI / Anthropic
- **Model** — text field (e.g. `llama3`, `gpt-4o`, `claude-sonnet-4-6`)
- **API key** — text field, masked; only shown for OpenAI and Anthropic
- **Agent server port** — number field, default `8765`

On save, Flutter calls `POST /config` on the agent server with the new provider/model/key. Port changes take effect on next server restart (Flutter shows a note to that effect).

The current config is loaded via `GET /config` when the settings section mounts.

---

## Acceptance criteria

- [ ] Agent settings section visible in the settings screen
- [ ] Provider, model, API key, and port fields are editable
- [ ] Saving calls `POST /config` and the agent server switches provider without restart
- [ ] Port field shows a "takes effect on restart" note when changed
- [ ] API key field is masked and only shown for cloud providers
- [ ] Current config is loaded from `GET /config` on mount

---

## Tests required

Yes:
- Widget test: assert fields render with current config values from `GET /config`
- Assert saving calls `POST /config` with correct payload
- Assert port change shows restart note

---

## Notes

P3 — the provider can be configured directly via `config.json` until this UI exists.

---

## Log

_Updated as work progresses._
