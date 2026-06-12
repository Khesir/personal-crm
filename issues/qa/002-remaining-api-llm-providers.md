---
id: issue-002
title: "Remaining 7 API LLM providers (Gemini, OpenRouter, OpenAI, DeepSeek, Mistral, NVIDIA, OpenCode Zen)"
feature: model-discovery
status: qa
created_at: 2026-06-13
tags: [afk, p2]
---

# [002] Remaining 7 API LLM providers (Gemini, OpenRouter, OpenAI, DeepSeek, Mistral, NVIDIA, OpenCode Zen)

**Type:** AFK
**Priority:** P2
**Blocked by:** 001
**User stories covered:** 2, 3, 4, 5, 6, 7, 8, 15

---

## What to build

Repeat the pattern established by issue 001 (Groq) for the remaining 7 API LLM provider types. Each is a
new `ServiceType` under `ServiceCategory.apiLlm`, added to the type picker's `availableTypes`, sharing the
same collapsed `customApi`-style repository/health-check case, with a label and a pre-filled-but-editable
default base URL:

| `ServiceType` value | Label | Default base URL |
|---|---|---|
| `gemini` | Gemini | `https://generativelanguage.googleapis.com/v1beta/openai` |
| `openRouter` | OpenRouter | `https://openrouter.ai/api/v1` |
| `openai` | OpenAI | `https://api.openai.com/v1` |
| `deepSeek` | DeepSeek | `https://api.deepseek.com/v1` |
| `mistral` | Mistral | `https://api.mistral.ai/v1` |
| `nvidia` | NVIDIA | `https://integrate.api.nvidia.com/v1` |
| `openCodeZen` | OpenCode Zen | best-effort placeholder — verify against current docs (see Notes) |

For each: add the `ServiceType` value (with `value`/`fromValue` JSON mapping), add it to the API LLM
category's `availableTypes`, add its label + default-base-URL lookup entries, and extend the collapsed
`customApi` case in `_repositoryForCard`, `_repositoryFor`, and `health_check_repository_impl.dart::check()`
to also match it.

---

## Acceptance criteria

- [ ] All 7 providers appear as options in the API LLM "Add" type picker (10 total, alongside Claude
  Anthropic, Custom API, and Groq).
- [ ] For each provider, selecting it opens the form with its base URL pre-filled (editable) and an API key
  field.
- [ ] For each provider, saving a card with a valid key shows "Online" after a health check
  (`GET {baseUrl}/v1/models` with Bearer auth).
- [ ] Models from any enabled new-provider card appear in the Home chat cookbook and can be
  enabled/disabled via the existing per-model checklist.
- [ ] Gemini specifically: confirm `generativelanguage.googleapis.com/v1beta/openai` correctly serves
  `/models` and `/chat/completions` with `Authorization: Bearer <apiKey>` (Google's OpenAI-compatibility
  layer) — if it doesn't behave as expected, flag rather than guess at a fix.
- [ ] Provider API errors (invalid key, rate limit, quota) are surfaced in the chat with the provider's own
  message, not a generic failure.

---

## Tests required

Yes:
- Extend `test/features/settings/domain/model/service_card_test.dart` with `value`/`fromValue` round-trip
  cases for all 7 new `ServiceType` values.
- Extend the lookup-table unit test from issue 001 to cover all 7 — each has a non-empty label and a
  non-empty default base URL.

---

## Notes

- OpenCode Zen's default base URL is an unverified placeholder in the PRD — confirm the correct
  OpenAI-compatible endpoint during implementation. Since the field is editable, an incorrect default
  doesn't block the user, but get it right if possible.
- "OpenAI" (not "ChatGPT") is the label for the `openai` type, matching the actual API/product name.
- No new datasource code — every provider reuses `OpenAiCompatibleDatasource`/`OpenAiCompatibleRepositoryImpl`
  exactly as issue 001 wired up for Groq.

---

## Log

_Updated as work progresses._

- Added all 7 remaining `ServiceType` values (`gemini`, `openRouter`, `openai`, `deepSeek`, `mistral`,
  `nvidia`, `openCodeZen`) with `value`/`fromValue` JSON mapping, labels, default base URLs, collapsed
  repository/health-check cases, and `ServiceCategory.apiLlm` availableTypes/API-key-field recognition —
  mirroring issue 001's Groq pattern exactly.
- `openCodeZen` default base URL set to `https://opencode.ai/zen/v1` based on web search (GitHub issue
  confirming `opencode.ai/zen/v1` as correct vs. an incorrect `api.opencode-zen.com` seen elsewhere); not
  independently verified against a live API call — flagged below.
- Tests: `flutter test` 171/171 passing (round-trip test now covers `hasLength(14)`; metadata test extended
  with non-empty-label coverage for all 14 types plus label/base-URL assertions for all 7 new types).
  `flutter analyze` clean — same 2 pre-existing `activeColor` deprecation infos, no new issues.

## Flagged

- `openCodeZen`'s default base URL (`https://opencode.ai/zen/v1`) is best-effort from a web search (a
  GitHub issue referencing OpenCode's provider config); it was not verified with a live `/v1/models` call.
  Since the field is user-editable this is non-blocking, but worth confirming against current OpenCode Zen
  docs/API if a user reports it not working.
- The acceptance-criteria items requiring live API verification (Gemini's OpenAI-compatibility layer at
  `generativelanguage.googleapis.com/v1beta/openai`, health checks returning "Online" with valid keys,
  provider error messages surfacing in chat) were not exercised against real provider APIs in this pass —
  no new/changed datasource code was needed (all 7 reuse `OpenAiCompatibleDatasource`/
  `OpenAiCompatibleRepositoryImpl` per the issue's Notes), but live-credential verification is outside the
  scope of this code change and would need manual QA with real API keys.
