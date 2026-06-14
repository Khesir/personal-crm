---
id: issue-004
title: "Agent-mode domain model: ChatRole.tool, ToolCall, ChatMessage/ChatConversation fields"
feature: home-chat-agent-mode
status: qa
created_at: 2026-06-14
tags: [afk, p1]
---

# [004] Agent-mode domain model: ChatRole.tool, ToolCall, ChatMessage/ChatConversation fields

**Type:** AFK
**Priority:** P1
**Blocked by:** None
**User stories covered:** 25

---

## What to build

Extend the Home chat domain models (`lib/features/home/domain/model/`) to support agent-mode tool calls,
while keeping all existing persisted conversations loading unchanged.

- `ChatRole` gains a new value `tool` (alongside `user`, `assistant`, `system`). `value`/`fromValue` extended;
  unrecognized values still fall back to `user`.
- New `ToolCall` model: `{ id: String, name: String, arguments: Map<String, dynamic> }`, with `toJson`/`fromJson`.
- `ChatMessage` gains:
  - `toolCalls: List<ToolCall>` (default `[]`) — set on `assistant` messages that requested tool calls.
  - `toolCallId: String?` and `toolName: String?` — set on `tool`-role messages, linking back to the
    `ToolCall.id`/`name` they answer.
  - All new fields default to empty/null in `fromJson` when absent.
- `ChatConversation` gains:
  - `workingProjectId: String?` (default `null`) — `null` means a normal (non-agent) conversation.
  - `trustedReferenceProjectIds: List<String>` (default `[]`).
  - Both default safely for existing persisted conversations.

No controller/repository/UI changes in this issue — this is purely the model layer plus its persistence
round-trip.

---

## Acceptance criteria

- [ ] `ChatRole.tool` exists; `value`/`fromValue` cover all four roles and unknown values fall back to `user`.
- [ ] `ToolCall` model exists with `toJson`/`fromJson`.
- [ ] `ChatMessage` has `toolCalls`, `toolCallId`, `toolName` with safe defaults in `fromJson` and `copyWith`.
- [ ] `ChatConversation` has `workingProjectId` and `trustedReferenceProjectIds` with safe defaults in
  `fromJson` and `copyWith`.
- [ ] Old persisted JSON (no new fields) deserializes into the new shapes without error, with defaults
  (`toolCalls: []`, `toolCallId: null`, `toolName: null`, `workingProjectId: null`,
  `trustedReferenceProjectIds: []`).
- [ ] New persisted JSON (with new fields populated) round-trips through `toJson`/`fromJson` unchanged.

---

## Tests required

Yes — model tests for `ChatMessage` and `ChatConversation`: round-trip `toJson`/`fromJson` for both the old
shape (no new fields present in the JSON) and the new shape (new fields populated), per the PRD's
Persistence/back-compat testing decision.

---

## Notes

- This is the foundational issue for the whole PRD (`issues/prd-home-chat-agent-mode.md`) — issues 005-012
  depend on these types.
- Story 24 (existing non-agent conversations keep working) and story 25 (back-compat persistence) are the
  acceptance bar here.
- See PRD section "Domain model changes" for the exact field shapes.

---

## Log

_Updated as work progresses._

- Added `ChatRole.tool`, new `ToolCall` model (`tool_call.dart`), and `toolCalls`/`toolCallId`/`toolName` fields
  on `ChatMessage`; added `workingProjectId`/`trustedReferenceProjectIds` on `ChatConversation`. All new
  `fromJson` fields default safely for old persisted JSON; `copyWith`/`toJson` updated accordingly.
- Added `test/features/home/domain/model/chat_message_test.dart` and `chat_conversation_test.dart` covering
  `ChatRole.tool`/`fromValue` fallback, `ToolCall` round trip, old-shape back-compat defaults, new-shape
  round trips, and `copyWith`. `flutter test test/features/home/domain/model/` (10 tests) and
  `flutter analyze` on touched files both pass with no issues.
