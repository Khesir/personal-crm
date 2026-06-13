# Handoff: "Agent mode" for Home Chat (Claude Code / OpenCode-style local file & command access)

**Date:** 2026-06-13
**Repo:** `C:\Users\ajriz\Documents\Projects\keep-track\crm` (Flutter app, part of the `keep-track` monorepo — see `C:\Users\ajriz\Documents\Projects\keep-track\CLAUDE.md` for architecture rules)
**Status:** Idea discussed and roughly scoped in conversation. NOT yet groomed via `/grill-me`, NOT a PRD, NOT issues. Parked because something more urgent took priority.

---

## Why this exists

The user asked whether the Home chat (Settings > Services > Local LLM / API LLM powered chat) could act like a Claude Code or OpenCode agent — i.e. read/edit files in a local folder and run commands, not just exchange text with an LLM.

This doc captures the rough shape of what that would take, so a future session can pick it up with `/grill-me` and turn it into a real PRD/issues.

---

## Current state of the chat (as of this conversation)

- `lib/features/home/domain/repository/chat_model_repository.dart` — the core abstraction. `ChatModelRepository.streamChat({model, messages}) -> Stream<String>`. Plain text in, plain text out. No tool-calling, no structured response parsing.
- `lib/features/home/domain/model/chat_message.dart` — `ChatMessage { role, content, streaming }`. `content` is a plain `String`. No concept of tool-call/tool-result message parts.
- Implementations: `lib/features/home/data/datasource/{anthropic_datasource,openai_compatible_datasource,ollama_datasource}.dart` and corresponding `*_repository_impl.dart`. These call the providers' chat-completion endpoints and stream text deltas only.
- `lib/features/home/domain/controller/chat_controller.dart` — orchestrates a single request/response turn; no multi-turn "agent loop" exists.

This is the entire relevant surface — nothing else in `lib/features/home` is agent-related yet.

---

## Rough shape of "agent mode" (from conversation, not yet validated against codebase in depth)

Four building blocks, roughly in dependency order:

1. **Tool-calling support in the datasources.** Anthropic, OpenAI-compatible, and Ollama APIs all support sending a `tools` schema and receiving structured tool-call responses (instead of, or interleaved with, text). `streamChat()`'s `Stream<String>` contract is too narrow — it needs to be able to emit/return structured tool-call requests, not just text deltas. This is the "easy" part — provider support already exists, just unused.

2. **A local tool executor.** New module implementing tools like `read_file`, `write_file`/`edit_file`, `list_dir`/`glob`, `grep`, `run_command` — scoped to a folder the user explicitly picks (not arbitrary filesystem access).

3. **An agent loop in the controller.** Replace the current single-shot "send messages, stream text, done" flow with: send messages+tools → model returns tool call(s) → execute via (2) → feed results back as new messages → repeat until the model returns a final text-only response. This is the biggest architectural change — `chat_controller.dart` and `chat_state.dart` both likely need rework, and `ChatMessage`/conversation persistence (`chat_conversation.dart`, `chat_conversations_repository*`) need to represent tool-call/tool-result turns, not just user/assistant text.

4. **Permissions & UI.** A sandboxed root folder picker, confirmation dialogs before any write/edit/command execution (security-critical — this is local file/command access), and new message bubble types (`chat_message_bubble.dart`) to render tool calls, their results, and ideally diffs for file edits.

**Main tradeoff flagged to the user:** #1 is cheap (providers already support it), but #3 and #4 are a genuinely new subsystem (agent loop + sandboxing + approval UI), comparable in scope to what Claude Code itself does — not a small tweak.

---

## Suggested next steps / skills

1. **`/grill-me`** — start here. Feed it this doc's framing (or just "I want Home chat to act like a Claude Code/OpenCode agent with local file access"). Use Phase 1 (Understand) to read `lib/features/home/**` properly (this handoff only skimmed it), then Phase 2 (Grill) to resolve:
   - Which provider(s) get tool-calling support first (Anthropic/Claude likely easiest given existing `anthropic_datasource.dart`)?
   - Exact tool set for v1 (just file read/list, or also write/edit/run_command from day one?)
   - Sandbox model: single user-picked root folder? Per-conversation? Stored where (Hive? `core/cache`?)
   - Approval UX: confirm every write/command, or a "trust this session" toggle?
   - How tool-call/tool-result turns are persisted in `chat_conversation.dart` / Hive without breaking existing conversation history (back-compat for old conversations with plain-text-only messages)
   - `StreamState`/`ScopeScreen`/custom-DI constraints per `CLAUDE.md` — this is a Flutter desktop app, so `run_command` needs a platform-appropriate process-execution approach (check what's already used, if anything, for Ollama process management)

2. **`/to-prd`** — once `/grill-me` resolves the above, produce a PRD (likely save as `issues/prd-home-chat-agent-mode.md` — follow the same "separate PRD" pattern used for `issues/prd-local-llm-engines-and-download-reliability.md`, since `issues/prd.md` already holds a different completed PRD).

3. **`/to-issues`** — break the PRD into vertical-slice tracer-bullet issues. Given the scope, expect this to be a multi-issue effort (likely: tool-calling plumbing for one provider → agent loop + persistence → sandbox/permission UI → additional providers).

---

## Related/prior work (for context only — do not duplicate)

- `issues/kanban.md` — fully clean as of this handoff (everything in `done/`, `backlog`/`ready`/`in-progress`/`qa` all empty). The most recently shipped feature is `issues/prd-local-llm-engines-and-download-reliability.md` (issues 006-009, all done) — restructured Settings > Services > Local LLM into "Engines"/"Models" with health-check-aware error messages and engine filter chips.
- `issues/prd.md` — earlier PRD (Hugging Face model discovery, hardware-fit scoring, API LLM providers), also fully shipped.

No code has been written for the agent-mode idea yet. This handoff is purely a scoping head-start.

---

## Related work: "Brain" (persistent memory/identity) PRD — in progress

A separate effort (`/grill-with-docs`, see [`CONTEXT.md`](../../CONTEXT.md)) is scoping a "brain" feature for
Home chat: an Obsidian-compatible markdown vault (`identity.md`, `soul.md`, `memory.md`, `skills/`) that gets
concatenated into a system prompt and injected into every Home chat request.

**Why this matters for agent mode:**

- **Resolved, no longer a concern:** the brain does NOT need a `streamChat()` signature change.
  `ChatRole.system` already exists, `anthropic_datasource.dart` already extracts `ChatRole.system` messages
  into the `system` field, and `ollama_datasource.dart`/`openai_compatible_datasource.dart` already pass all
  messages through as-is (both APIs accept a `role: "system"` message natively). The brain prepends an
  ephemeral `ChatMessage(role: ChatRole.system, ...)` to the message list in `chat_controller.dart` —
  `streamChat()` itself is untouched. Block #1 (tool-calling) is free to change the signature later without
  any brain-related coordination.
- The brain's long-term vault (notes beyond `memory.md`) is explicitly **out of scope** for the brain PRD —
  the brain PRD only loads `identity.md`/`soul.md`/`memory.md` into the system prompt. Active retrieval of
  other vault notes (search/open-on-demand) was deferred *here*, to agent mode's tool-calling — i.e. a future
  `read_file`/`grep` tool could be the mechanism that lets the agent pull long-term memory notes into context
  when needed. Keep this in mind when designing the tool set for v1 (block #2) — vault-note retrieval may be
  a natural early use case for `read_file`/`grep` once those tools exist.
- `skills/` in the brain vault is markdown *documentation* of what the agent can do/how it should approach
  tasks — not an execution engine. Once agent mode's tool loop (block #3) exists, these skill docs become the
  natural place to describe how to use the new tools for specific workflows.
