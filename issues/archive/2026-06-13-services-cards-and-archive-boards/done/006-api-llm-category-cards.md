---
id: issue-006
title: "API LLM category cards (Claude Anthropic & Custom API)"
feature: service-cards
status: done
created_at: 2026-06-12
tags: [afk, p2]
---

# [006] API LLM category cards (Claude Anthropic & Custom API)

**Type:** AFK
**Priority:** P2
**Blocked by:** 003
**User stories covered:** 15, 16, 17, 18, 19

---

## What to build

Add the two API LLM card types to the generic card UI and health-check dispatch built in issue 003.
Configuration + health-check only — these cards are not consumed anywhere else yet.

- The API LLM category's "Add" type picker gains two options:
  - **Claude (Anthropic)** — `{ apiKey }`, via the generic form dialog with a masked, toggleable API key
    field.
  - **Custom (OpenAI-compatible API)** — `{ baseUrl, apiKey }`, via the generic form dialog, API key
    masked/toggleable.
- `HealthCheckRepository` gains two new dispatch branches:
  - `claudeAnthropic` → Anthropic's `GET /v1/models` with the configured API key (`x-api-key` /
    `anthropic-version` headers).
  - `customApi` → `GET {baseUrl}/v1/models` with `Authorization: Bearer {apiKey}`.
  - Both: 2xx = online, connection failure/timeout = offline, other HTTP responses = error.
- API LLM tiles populate from real cards using the generic tile layout from issue 003: name, type label,
  status, masked API key preview, Refresh/Edit/Delete. No "Default" tag — API LLM types are not back-compat
  single-value consumers.

---

## Acceptance criteria

- [ ] API LLM category's "Add" offers Claude (Anthropic) (API key field) and Custom (OpenAI-compatible API)
  (base URL + API key fields) via the generic form dialog, with API key fields masked and revealable via a
  toggle.
- [ ] Adding a Claude (Anthropic) card persists it; its health check calls Anthropic's `GET /v1/models`
  with the configured key, showing Online/Offline/Error accordingly.
- [ ] Adding a Custom API card persists it; its health check calls `GET {baseUrl}/v1/models` with bearer
  auth, showing Online/Offline/Error accordingly.
- [ ] Both card types support Refresh/Edit/Delete via the generic tile actions from issue 003.
- [ ] Neither card type appears in or affects the Home chat model picker (the cookbook from issue 007 only
  lists Local LLM cards).

---

## Tests required

No — covered by the generic `ServiceCardsController`/health-check test infrastructure from issue 003
(additive dialog fields and dispatch branches); the Anthropic/OpenAI HTTP calls are not unit tested,
consistent with the other per-type health checks.

---

## Notes

- This is the slice where the old `CLAUDE_API_KEY` env var becomes an editable Claude (Anthropic) card (and
  the migration in issue 004, if it ran first, will have already seeded one from any previously-saved key).

---

## Log

_Updated as work progresses._

- Added `ServiceType.claudeAnthropic`/`customApi` to the API LLM type picker, generalized `_SecretField`
  (label/hintText params) and added a conditional API Key field plus `_showBaseUrlField`/`_showApiKeyField`
  getters and type-aware `_submit()` validation/fields-map in `service_card_form_dialog.dart`. Added
  masked "API Key: ••••••••" tile preview in `services_section.dart`.
- Extended `_checkStatusAware` in `health_check_repository_impl.dart` with optional `url`/`headers`
  overrides and added dispatch branches for `claudeAnthropic` (Anthropic `GET /v1/models` with
  `x-api-key`/`anthropic-version`) and `customApi` (`GET {baseUrl}/v1/models` with Bearer auth), both
  short-circuiting to offline when required fields are missing.
- Verified: `flutter analyze` clean (only 2 pre-existing unrelated deprecation infos), `flutter test`
  all 107 tests pass. No "Default" tag confirmed for these types (addCard only auto-defaults
  `_backCompatTypes`, which excludes `claudeAnthropic`/`customApi`).
- QA approved by user on 2026-06-13 (no live Claude/Custom API endpoint available to test against;
  accepted on the strength of code review and the generic health-check infrastructure from 003 —
  revisit in a future PRD if issues surface with real endpoints).
