---
id: issue-015
title: "ChromaDB vector memory"
feature: agent
status: done
created_at: 2026-06-16
tags: [afk, p3]
---

# [015] ChromaDB vector memory

**Type:** AFK
**Priority:** P3
**Blocked by:** 007
**User stories covered:** 35

---

## What to build

Integrate ChromaDB as an embedded vector store alongside SQLite. ChromaDB data lives at `%APPDATA%\Avyn\agent\chroma\`.

After each completed loop run, embed the assistant's final response and store it in ChromaDB with metadata: `session_id`, `created_at`, a short summary. Before each loop run, perform a semantic similarity search against ChromaDB using the user's current message as the query. The top-k results (default k=3) are injected into the system prompt as "relevant past context" before the Brain files and conversation history.

This gives the agent access to semantically relevant content from past sessions — not just the current session's linear history.

ChromaDB is embedded (no separate server). Add `chromadb` to `requirements.txt`.

---

## Acceptance criteria

- [x] ChromaDB is initialised at `%APPDATA%\Avyn\agent\chroma\` on server startup
- [x] After each loop run, the assistant response is embedded and stored in ChromaDB
- [x] Before each loop run, top-k semantically similar past responses are retrieved
- [x] Retrieved context is injected into the system prompt
- [x] ChromaDB data persists across server restarts

---

## Tests required

Yes — use ChromaDB's in-memory mode for tests:
- Assert embeddings are stored after a loop run
- Assert semantic retrieval returns results for a related query
- Assert retrieved context appears in the system prompt passed to the LLM

---

## Notes

P3 — the agent is fully functional without this. Add it once the core loop, tools, and session persistence are stable.

---

## Log

- **2026-06-19**: Implemented. Created `agent/vector.py` with `init_vector`, `store_response`, `retrieve_context`. Added `chromadb` to `requirements.txt`. Updated `main.py`: import vector functions, call `init_vector()` in `on_startup`, inject retrieved context before brain content, call `store_response` after `save_messages`. Created `agent/test_vector.py` with three tests: `test_store_and_retrieve`, `test_retrieve_empty`, `test_context_injected_in_chat`.

QA approved by user on 2026-06-24.
