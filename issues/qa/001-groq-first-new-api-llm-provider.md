---
id: issue-001
title: "Groq as the first new API LLM provider (tracer bullet)"
feature: model-discovery
status: qa
created_at: 2026-06-13
tags: [afk, p1]
---

# [001] Groq as the first new API LLM provider (tracer bullet)

**Type:** AFK
**Priority:** P1
**Blocked by:** None
**User stories covered:** 1, 9, 10, 11, 12, 13, 14 (partial 15)

---

## What to build

Add Groq as a new `ServiceType` under `ServiceCategory.apiLlm`, reusing the existing OpenAI-compatible chat
pipeline end to end. This issue is the tracer bullet for the whole "new API LLM provider" pattern — issue
002 repeats it mechanically for the remaining 7 providers.

- New `ServiceType.groq` value (with `value`/`fromValue` JSON mapping `'groq'`), added to
  `ServiceCategory.apiLlm`.
- Add `groq` to the API LLM category's `availableTypes` list (type picker).
- New label-lookup entry: `groq` → `"Groq"`.
- New default-base-URL-lookup entry: `groq` → `"https://api.groq.com/openai/v1"`, used only to pre-fill the
  `baseUrl` field when the form opens for a *new* Groq card — the field stays editable.
- Extend the form dialog's visibility getters (`_showBaseUrlField`, `_showApiKeyField`, `_isApiLlmType`,
  `_showModelChecklist`) so `groq` behaves identically to `customApi`.
- Extend the existing `customApi` repository-construction case (in both the form dialog's
  `_repositoryForCard` and `home/di.dart`'s `_repositoryFor`) so `ServiceType.groq` shares the same case —
  `OpenAiCompatibleRepositoryImpl(OpenAiCompatibleDatasource(...))` with `Authorization: Bearer <apiKey>`
  and `baseUrl` from `card.fields['baseUrl']`.
- Extend the `customApi` case in `health_check_repository_impl.dart` so `ServiceType.groq` uses the same
  `_checkStatusAware(card, '/v1/models', headers: {'Authorization': 'Bearer $apiKey'})` check.
- No changes to `OpenAiCompatibleDatasource`, `OpenAiCompatibleRepositoryImpl`, or `chat_error_mapper.dart`
  — all reused as-is.

---

## Acceptance criteria

- [ ] "Groq" appears as an option in the API LLM "Add" type picker.
- [ ] Selecting "Groq" opens the form with `baseUrl` pre-filled to `https://api.groq.com/openai/v1`
  (editable) and an API key field.
- [ ] Saving a Groq card with a valid key shows "Online" after a health check (`GET {baseUrl}/v1/models`
  with Bearer auth); an invalid key shows "Error".
- [ ] Models from an enabled Groq card appear in the Home chat cookbook and can be enabled/disabled via the
  existing per-model checklist.
- [ ] Sending a chat message to a Groq model streams a response; a Groq API error (e.g. invalid key) is
  surfaced in the chat with the provider's own message, not a generic failure.

---

## Tests required

Yes:
- Extend `test/features/settings/domain/model/service_card_test.dart` with a `value`/`fromValue` round-trip
  case for `ServiceType.groq`.
- New unit test asserting `groq` has a non-empty label ("Groq") and a non-empty default base URL
  (`https://api.groq.com/openai/v1`) in their respective lookup tables.

---

## Notes

- This is purely a wiring/data change — "OpenAI-compatible with Bearer auth + a preset base URL" is the
  entire mechanism, matching how `customApi` already works today. No new datasource code.
- Get this pattern right here first; issue 002 repeats it for Gemini, OpenRouter, OpenAI, DeepSeek,
  Mistral, NVIDIA, and OpenCode Zen.

---

## Log

_Updated as work progresses._

Implemented `ServiceType.groq` (value `'groq'`) plus a new
`service_type_metadata.dart` providing `kServiceTypeLabels` (consolidating
the three near-duplicate label switches, including `'Groq'`) and
`kServiceTypeDefaultBaseUrls` (`groq` -> `https://api.groq.com/openai/v1`).
Wired `groq` through `_repositoryForCard`/`_repositoryFor` (shared with
`customApi`'s OpenAI-compatible Bearer-auth construction), the
`/v1/models` health check, the form dialog's API-key/base-URL visibility
and base-URL pre-fill, and the API LLM `availableTypes` picker list.

Tested via `flutter analyze` (clean, only the 2 pre-existing unrelated
`activeColor` deprecation infos) and `flutter test` (128/128 passing,
including the updated seven-type round-trip test and the new
`service_type_metadata_test.dart`).
