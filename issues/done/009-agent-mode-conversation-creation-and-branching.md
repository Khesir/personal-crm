---
id: issue-009
title: "Agent-mode conversation creation + branching UI, CookbookEntry.supportsTools"
feature: home-chat-agent-mode
status: done
created_at: 2026-06-14
tags: [afk, p2]
---

# [009] Agent-mode conversation creation + branching UI, CookbookEntry.supportsTools

**Type:** AFK
**Priority:** P2
**Blocked by:** 004, 008
**User stories covered:** 1, 2, 3, 22, 23, 24

---

## What to build

Let users start (and branch into) agent-mode conversations from the Home chat UI, restricted to
tool-capable models.

- `CookbookEntry` (`domain/model/cookbook_entry.dart`) gains `supportsTools: bool`.
  - During `ChatController.refresh()`, for `ServiceType.ollama` cards, query `/api/show` per model and set
    `supportsTools` from whether its `capabilities` array contains `"tools"`.
  - For all other `ServiceType`s, `supportsTools = true` (assumed).
- New-conversation flow gains an "Agent mode" toggle:
  - When enabled, a project picker (registered `Project`s, via `ProjectsRepository`) selects the working
    project.
  - The model picker is filtered to `supportsTools == true` cookbook entries.
  - `workingProjectId` is set on the new `ChatConversation` at creation and never changes for that
    conversation's lifetime.
- New "Branch into agent mode" action (conversation context menu / header):
  - Opens the same project+model picker, then creates a new `ChatConversation` whose `messages` are a copy of
    the source conversation's `messages` at branch time. The source conversation is untouched.

---

## Acceptance criteria

- [ ] `CookbookEntry.supportsTools` exists; Ollama cookbook entries reflect their model's `/api/show`
  `capabilities` (`true` only if `"tools"` is present); non-Ollama entries default to `true`.
- [ ] Starting a new conversation with "Agent mode" off behaves exactly as today (no project picker, full
  model list, `workingProjectId == null`).
- [ ] Starting a new conversation with "Agent mode" on requires picking a registered project, filters the
  model picker to `supportsTools == true` entries, and sets `workingProjectId` on the created conversation.
- [ ] "Branch into agent mode" on an existing conversation opens the project+model picker, creates a new
  conversation with `workingProjectId` set and `messages` copied from the source conversation at branch time,
  and leaves the source conversation's `messages` unchanged.
- [ ] A conversation's `workingProjectId` cannot be changed after creation (no UI affordance to do so).
- [ ] Existing non-agent conversations created before this change continue to load and behave as before.

---

## Tests required

No automated widget tests — covered via `/qa`'s visual checklist, per the PRD's UI testing decisions. If
`refresh()`'s `/api/show` capability check is straightforward to unit-test against the existing
`ChatController`/Ollama datasource fakes, add coverage for `supportsTools` mapping there.

---

## Notes

- Depends on 004 (`workingProjectId`/`trustedReferenceProjectIds` fields) and 008 (agent loop must exist for
  an agent-mode conversation to be usable after creation).
- See PRD sections "`CookbookEntry` / model capability" and "Conversation creation / branching UI".

---

## Log

- Added `CookbookEntry.supportsTools` (default `true`). `OllamaDatasource.getModelCapabilities()`
  (`POST /api/show`) and `OllamaRepositoryImpl.supportsTools()` query each Ollama model's
  capabilities; `ChatController.refresh()` sets `supportsTools` from `capabilities.contains("tools")`
  for `ServiceType.ollama` cards, and `true` for all other types. If `/api/show` fails (or the
  resolved repo isn't an `OllamaRepositoryImpl`, e.g. in tests with `FakeChatModelRepository`),
  `supportsTools` defaults to `false` — fail closed, so agent mode is never offered for a model whose
  capabilities couldn't be determined.
- Added `ChatController.newAgentConversation(projectId, entry)` and
  `branchIntoAgentMode(sourceConversationId, projectId, entry)`; both set `workingProjectId` only at
  creation time (immutable thereafter) and `branchIntoAgentMode` deep-copies the source
  conversation's messages via `ChatMessage.copyWith()` without mutating the source.
- Added `presentation/dialogs/agent_mode_picker_dialog.dart` (project + tool-capable model picker,
  reused by both flows) and `presentation/dialogs/new_chat_dialog.dart` (Agent mode toggle for "New
  chat"). Added `presentation/helpers/agent_mode_flow.dart` to wire these dialogs into
  `home_sidebar_section.dart`'s "New chat" button and a new hover-revealed "Branch into agent mode"
  popup menu item on `_ConversationItem`.
- Updated 6 pre-existing `ChatController` tests whose Ollama cookbook entries now resolve
  `supportsTools: false` (their fake repos aren't `OllamaRepositoryImpl`, so capability lookup
  fails closed). Added new tests: `CookbookEntry` equality/copyWith for `supportsTools`,
  `OllamaDatasource.getModelCapabilities()`, `refresh()` capability mapping (true/false/error cases
  via a real `OllamaRepositoryImpl` + fake Dio adapter), `newAgentConversation`, and
  `branchIntoAgentMode` (including the "source unchanged" guarantee).
- `flutter test` (299 tests) and `flutter analyze` both clean — only the 2 pre-existing
  `deprecated_member_use` warnings remain (`announcements_section.dart`, `project_form_dialog.dart`).

QA approved by user on 2026-06-14.
