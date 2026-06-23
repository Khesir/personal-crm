---
id: issue-003
title: "LLM provider abstraction (Ollama, OpenAI, Anthropic)"
feature: agent
status: done
created_at: 2026-06-16
tags: [afk, p1]
---

# [003] LLM provider abstraction (Ollama, OpenAI, Anthropic)

**Type:** AFK
**Priority:** P1
**Blocked by:** 002
**User stories covered:** 17, 18

---

## What to build

Implement a provider-agnostic LLM interface inside the Python agent server. The loop will call this interface without knowing which provider is active. Three concrete implementations are required: Ollama (local), OpenAI, and Anthropic.

The interface must support:
- Sending a list of messages (system + conversation history) to the LLM
- Receiving a streamed response
- Passing tool schemas so the LLM can request tool calls
- Returning tool call requests alongside text tokens

Provider configuration is loaded from a JSON config file at `%APPDATA%\Avyn\agent\config.json`. Shape: `{"provider": "ollama", "model": "llama3", "api_key": "..."}`. If the file does not exist, default to Ollama with no API key.

Expose a `GET /config` endpoint that returns current provider config (omitting the API key value). Expose a `POST /config` endpoint that accepts a new config and writes it to disk. These endpoints allow Flutter's settings UI to read and update the provider without restarting the server.

---

## Acceptance criteria

- [ ] `LLMProvider` abstract interface defined with `stream_chat(messages, tools)` method
- [ ] Ollama, OpenAI, and Anthropic concrete implementations exist
- [ ] Active provider is determined by `config.json` at startup and on `POST /config`
- [ ] `GET /config` returns current provider and model (no API key)
- [ ] `POST /config` writes new config and switches provider without restart
- [ ] Each provider passes tool schemas correctly to the underlying API

---

## Tests required

Yes — mock each provider's HTTP endpoint and assert:
- Correct messages and tool schemas are sent
- Streamed tokens are returned in the expected shape
- Provider switches correctly when config changes

---

## Notes

The tool schema format differs between providers (OpenAI function-calling format vs Anthropic tool-use format vs Ollama tools). The abstraction layer normalises this — the loop always passes tools in one internal format and the provider implementation translates.

---

## Log

Implemented 2026-06-18. Created providers/ module with LLMProvider ABC and Ollama/OpenAI/Anthropic implementations. Added config.py for provider switching. Added /config GET and POST endpoints to main.py. Tests pass.

QA approved by user on 2026-06-24.
