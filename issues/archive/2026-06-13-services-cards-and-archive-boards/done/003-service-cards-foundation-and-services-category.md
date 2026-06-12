---
id: issue-003
title: "Service cards foundation + Services category (n8n & Custom URL)"
feature: service-cards
status: done
created_at: 2026-06-12
tags: [afk, p1]
---

# [003] Service cards foundation + Services category (n8n & Custom URL)

**Type:** AFK
**Priority:** P1
**Blocked by:** None
**User stories covered:** 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 21, 22, 23

---

## What to build

The data-layer foundation for service cards, plus a complete vertical slice rewriting Settings > Services
into a 3-category card UI, with the **Services** category (n8n, Custom URL) fully working end-to-end.

- `ServiceCard` model: `{ id, category, type, name, fields: Map<String, String>, enabled: bool, isDefault:
  bool, disabledModels: List<String> }`, with `toJson`/`fromJson`/`copyWith` following the existing
  Project model's shape.
  - `category` enum: `localLlm | apiLlm | services`.
  - `type` enum: define all six values now — `ollama | customLocal | claudeAnthropic | customApi | n8n |
    customUrl` — even though only `n8n` and `customUrl` get working UI in this slice. Each has a `.value`
    string for JSON, matching the existing enum-serialization convention.
  - `fields` for this slice: `n8n` → `{ baseUrl }`, `customUrl` → `{ baseUrl, secret? }`.
  - `disabledModels` and `toggleModelEnabled` are part of the model/controller contract now but unused
    until the cookbook slice lands — no UI surface for them yet.
- New SharedPreferences-backed datasource (read/write a JSON list of `ServiceCard`) → repository
  (`getCards()` / `saveCards()`) → `ServiceCardsController` extending the async stream-state base class
  used by the Projects controller, exposing `addCard`, `updateCard`, `removeCard`, `setDefault(type,
  cardId)`, and `toggleModelEnabled(cardId, modelName)`.
  - The SharedPreferences key follows the same `$kDataNamespace.` namespacing convention as the projects
    registry key (per ADR 0002).
  - `setDefault(type, cardId)` clears `isDefault` on every other card of the same `type` and sets it on the
    target. The first card created for a back-compat type (`ollama`, `n8n`, `customUrl`) is automatically
    `isDefault: true`.
- `HealthStatus` enum: `checking | online | offline | error`. `HealthCheckRepository` interface:
  `check(ServiceCard) → HealthStatus`. This slice implements the dispatch branches for `n8n` and
  `customUrl` only: `GET {baseUrl}` with a short timeout — **any** HTTP response = online, connection
  failure/timeout = offline (no "error" state for this uniform check). Branches for the other four types
  are added by later slices.
- Settings > Services rewritten into three sections — Local LLM, API LLM, Services — each rendering its
  card list as separated tiles mirroring the existing Project card tile: name, type label, status dot +
  label, masked field preview, "Default" tag where applicable, and Refresh/Edit/Delete actions. Local LLM
  and API LLM sections render the same "nothing here yet" empty state used by Projects, since no card
  types are wired for them yet.
- Services category fully wired: "Add" opens a small type picker (n8n / Custom URL), then a generic
  `ServiceCardFormDialog` (mirroring the Project form dialog — type-specific fields, Cancel/Save, masked
  obscure+toggle input for Custom URL's optional `secret` field). Edit reopens the dialog prefilled.
  Delete removes immediately with no confirmation, matching Projects.
- Health checks: triggered on Settings > Services mount (all existing cards), after add/edit of a card
  (that card only), and via a manual per-card refresh action. Status badge shows
  Checking/Online/Offline/Error. No periodic/background polling.

---

## Acceptance criteria

- [ ] Settings > Services shows three sections: Local LLM, API LLM, Services.
- [ ] Local LLM and API LLM sections show a "nothing here yet" empty state with an Add action, since no
  card types are wired for them yet.
- [ ] Services section's "Add" opens a type picker for n8n / Custom URL, then a form dialog (Cancel/Save).
- [ ] Adding an n8n card (base URL) or Custom URL card (base URL + optional secret) persists it and renders
  a tile with name, type label, status, masked secret preview (if set), and a "Default" tag if applicable.
- [ ] Each tile has working Refresh/Edit/Delete actions; Edit reopens the dialog prefilled; Delete removes
  immediately with no confirmation.
- [ ] Opening Settings > Services triggers a health check for every existing card; status shows Checking →
  Online/Offline based on a `GET` to the card's base URL.
- [ ] Adding or editing a card triggers a health check for that card only.
- [ ] The first card created for n8n (or Custom URL) is automatically marked Default; creating a second
  card of the same type and marking it Default un-defaults the first.

---

## Tests required

Yes — `ServiceCardsController` unit tests against a fake repository (add/update/remove/setDefault,
persistence round trip), mirroring `projects_controller_test.dart`, plus a `ServiceCard`
`toJson`/`fromJson` round-trip test. `HealthCheckRepository`'s n8n/Custom URL "any response = online"
behavior is faked at the controller/state level for status-transition tests; the real Dio-based check is
not unit tested.

---

## Notes

- Mirrors the Projects section's list-of-cards + form-dialog pattern: card tile layout, Add → type picker
  → dialog, Edit reopens prefilled, immediate no-confirm delete.
- Defining the full `ServiceType`/`ServiceCategory` enums now means issues 005 and 006 only need to add
  dialog fields and health-check dispatch branches — no model changes.
- This slice does not touch `.env`, the migration, or any existing DI factories — that's issue 004.

---

## Log

_Updated as work progresses._

- Implemented `ServiceCard`/`ServiceCategory`/`ServiceType`/`HealthStatus` models, SharedPreferences-backed
  datasource/repository/`ServiceCardsController` (add/update/remove/setDefault/toggleModelEnabled,
  first-card-auto-default for `ollama`/`n8n`/`customUrl`, and per-card health-status tracking via a
  broadcast stream), and `HealthCheckRepositoryImpl` (uniform GET for `n8n`/`customUrl`, `error` stub for
  the other four types).
- Rewrote Settings > Services into three sections (Local LLM, API LLM, Services) with `AsyncStreamBuilder`
  card lists, "nothing here yet" empty states + Add actions for Local LLM/API LLM, and a full Services flow
  (type picker -> `ServiceCardFormDialog` -> add/edit/delete/refresh/set-default) wired through
  `createServiceCardsController()` in `di.dart` and `_ServicesContent` in `app_shell_screen.dart`. Health
  checks run on mount (`checkAllHealth`), after add/edit (`checkHealth` for that card), and via per-card
  Refresh.
- Added 14 new tests (`service_card_test.dart`, `service_cards_controller_test.dart` with
  `FakeServiceCardsRepository`/`FakeHealthCheckRepository`) covering the model round trip and all
  controller behaviors including health-status transitions. Full suite: 94/94 passing.
  `flutter analyze` clean except 2 pre-existing unrelated `activeColor` deprecation infos.
- QA approved by user on 2026-06-13.
