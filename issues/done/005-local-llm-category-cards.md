---
id: issue-005
title: "Local LLM category cards (Ollama & Custom Local)"
feature: service-cards
status: done
created_at: 2026-06-12
tags: [afk, p1]
---

# [005] Local LLM category cards (Ollama & Custom Local)

**Type:** AFK
**Priority:** P1
**Blocked by:** 003
**User stories covered:** 11, 12, 13, 14

---

## What to build

Add the two Local LLM card types to the generic card UI and health-check dispatch built in issue 003.

- The Local LLM category's "Add" type picker gains two options:
  - **Ollama** — `{ baseUrl }`, via the generic form dialog.
  - **Custom Local (OpenAI-compatible)** — `{ baseUrl }`, via the generic form dialog.
- `HealthCheckRepository` gains two new dispatch branches:
  - `ollama` → `GET {baseUrl}/api/tags`
  - `customLocal` → `GET {baseUrl}/v1/models`
  - Both: 2xx = online, connection failure/timeout = offline, other HTTP responses = error.
- Local LLM tiles populate from real cards using the generic tile layout from issue 003: name, type label
  ("Ollama" / "Custom Local (OpenAI-compatible)"), status (Checking/Online/Offline/Error),
  Refresh/Edit/Delete.
- The first Ollama card created is automatically marked Default, consistent with the n8n/Custom URL
  behavior from issue 003 (Custom Local is not a back-compat type and does not show a Default tag).

---

## Acceptance criteria

- [ ] Local LLM category's "Add" offers Ollama and Custom Local (OpenAI-compatible), each with a base-URL
  field via the generic form dialog.
- [ ] Adding an Ollama card persists it; its health check calls `GET {baseUrl}/api/tags`, showing
  Online/Offline/Error accordingly.
- [ ] Adding a Custom Local card persists it; its health check calls `GET {baseUrl}/v1/models`, showing
  Online/Offline/Error accordingly.
- [ ] Both card types support Refresh/Edit/Delete via the generic tile actions from issue 003.
- [ ] The first Ollama card created is marked Default.

---

## Tests required

No — this slice is additive dialog fields plus two new `HealthCheckRepository` dispatch branches over
existing `{ baseUrl }` field shapes; it's covered by the generic `ServiceCardsController`/health-check test
infrastructure from issue 003 (status-transition coverage is type-agnostic). The real
`/api/tags`/`/v1/models` HTTP calls are not unit tested.

---

## Notes

- These cards are the data source for the cookbook in issue 007 — `listModels()` for each card type is
  implemented there, not here.
- Per-model enable/disable curation UI (the `disabledModels` checklist) is added in issue 007, alongside
  the cookbook that consumes it.

---

## Log

_Updated as work progresses._

- Wired the Local LLM category's "Add" type picker to `[ServiceType.ollama, ServiceType.customLocal]`,
  reusing the existing generic form dialog and `{baseUrl}` field with no new fields.
- Added `HealthCheckRepositoryImpl._checkStatusAware(card, path)`: `ollama` → `GET {baseUrl}/api/tags`,
  `customLocal` → `GET {baseUrl}/v1/models`; maps 2xx → online, connection failure/timeout → offline,
  other HTTP responses (4xx/5xx) → error. Updated `_typeLabel`/`_label` in `services_section.dart` so
  Custom Local renders as "Custom Local (OpenAI-compatible)" on tiles and in the type picker.
- Verified `ServiceCardsController._backCompatTypes` already includes `ollama` (not `customLocal`), so the
  first Ollama card is auto-marked Default for free, with no controller changes needed.
- `flutter analyze`: clean (2 pre-existing, unrelated `deprecated_member_use` infos in
  `announcements_section.dart` / `project_form_dialog.dart`, untouched by this change).
  `flutter test`: all 94 tests pass, no new failures.
- QA approved by user on 2026-06-13.
