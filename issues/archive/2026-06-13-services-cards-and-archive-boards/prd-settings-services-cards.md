# PRD: Settings > Services Cards & Local Chat Cookbook

**Status:** Draft
**Date:** 2026-06-12

---

## Problem Statement

Settings > Services is currently a flat list of five raw env-var text fields (n8n URL, Ollama URL, DevCenter
Backend URL, CRM secret, Claude API key) with no indication of whether any of these services are actually
reachable, and no way to configure more than one instance of a given service — e.g. a second Ollama
install or an LM Studio server.

The Home chat screen's model picker only shows models from a single hardcoded Ollama instance, with no way
to add other local model servers or hide installed models the user doesn't want cluttering the picker.

Configuration today depends on a `.env` file plus a SharedPreferences override layer (`flutter_dotenv` +
`env_override_<KEY>`), which is an extra moving part with no UI visibility into what's configured vs.
defaulted, and adds friction every time a new configurable connection is needed.

---

## Solution

Redesign Settings > Services into a card-based UI organized into three fixed categories — **Local LLM**,
**API LLM**, and **Services** — where each card represents one configured connection (a specific Ollama
install, an n8n instance, a Claude API key, a custom HTTP service, etc.), with its own fields, a live
health-check status, and add/edit/remove actions via a dialog, mirroring the existing Projects section's
list-of-cards + form-dialog pattern.

Replace `.env` / `flutter_dotenv` / `env_override_<KEY>` entirely with a single SharedPreferences-backed
JSON list of cards as the sole source of configuration truth, with hardcoded fallback defaults baked into
code and a one-time migration from the old env-override keys on first launch.

Extend the Home chat's model picker into a "cookbook" — a flattened list of models from every enabled
Local LLM card, each independently selectable, with per-card curation (enable/disable individual installed
models) and routing so sending a message goes to the exact server that owns the selected model.

---

## User Stories

### Settings > Services — general

1. As a user, I want Settings > Services organized into Local LLM, API LLM, and Services categories, so I
   can find and manage connections by purpose.
2. As a user, I want each category to show a list of configured cards with an "Add" action, so I can add
   multiple connections of the same kind (e.g. two Ollama servers).
3. As a user, I want each card to show a live status indicator (Checking / Online / Offline / Error), so I
   know at a glance whether a connection is working.
4. As a user, I want a manual refresh action per card, so I can re-check status on demand without
   restarting the app.
5. As a user, I want health checks to run automatically when I open Settings > Services and whenever I add
   or edit a card, so status is fresh without extra effort.
6. As a user, I want secret/API-key fields shown masked (`••••••••`) in the card list and only revealable
   in the edit dialog, so sensitive values aren't exposed by default.
7. As a user, I want to add a card via a type picker (the types available for that category) followed by a
   form dialog, so the add flow matches the existing "Add Project" flow.
8. As a user, I want to edit a card's fields via a dialog with Cancel/Save, so editing is consistent with
   the Projects section.
9. As a user, I want to delete a card with a single click and no confirmation, consistent with how Projects
   cards are deleted today.
10. As a user, when I have multiple cards of a type that backs an existing single-value consumer (Ollama,
    n8n, Custom URL), I want to mark one as "Default" and see a "Default" tag, so the app knows which one
    to use for those consumers.

### Local LLM category

11. As a user, I want to add an "Ollama" card (base URL only), so I can configure my local Ollama server.
12. As a user, I want Ollama's health check to call `GET /api/tags`, so status reflects whether Ollama is
    actually running and responding.
13. As a user, I want to add a "Custom Local (OpenAI-compatible)" card (base URL only), so I can configure
    tools like LM Studio or llama.cpp's server.
14. As a user, I want Custom Local's health check to call `GET {baseUrl}/v1/models`, so status reflects
    whether the OpenAI-compatible server is reachable.

### API LLM category

15. As a user, I want to add a "Claude (Anthropic)" card (API key only), so I can store my Anthropic API
    key for future use.
16. As a user, I want Claude's health check to call Anthropic's `/v1/models` endpoint with my API key, so I
    can verify the key is valid without burning generation quota.
17. As a user, I want to add a "Custom (OpenAI-compatible API)" card (base URL + API key), so I can
    configure OpenAI, OpenRouter, or similar providers.
18. As a user, I want Custom API's health check to call `GET {baseUrl}/v1/models` with the API key, so
    status reflects whether the provider/key combination works.
19. ~~As a user, I understand API LLM cards are configuration + health-check only in this release and are
    not yet selectable in the chat cookbook, so I know what to expect.~~ Extended by issue 008: API LLM
    cards (Claude Anthropic, Custom API) now feed the chat cookbook the same as Local LLM cards — selectable,
    routed, and curated via `disabledModels`.

### Services category

20. As a user, I want to add an "n8n" card (base URL only), so I can configure the n8n instance used by
    Agent Run.
21. As a user, I want to add a "Custom URL" card (base URL + optional secret), so I can configure DevCenter
    Backend or any other personal HTTP service.
22. As a user, I want Services health checks to use a uniform "GET base URL, any response = Online" check,
    so status works for arbitrary services without needing per-service endpoint knowledge.
23. As a user, I want the optional secret field on a Custom URL card to be sent as the `x-crm-secret`
    header, matching today's DevCenter Backend behavior, so existing DevCenter integration keeps working.

### Storage / `.env` removal / migration

24. As a user, I want all service configuration stored in one place (SharedPreferences), so I don't need a
    separate `.env` file anymore.
25. As a user, I want sensible hardcoded defaults (e.g. `http://localhost:11434` for Ollama,
    `http://localhost:5678` for n8n, `http://localhost:3000` for Custom URL) used when no card of a given
    type exists, so the app works out of the box on a fresh install.
26. As a user upgrading from the old `.env`/`env_override_<KEY>` system, I want my existing n8n, Ollama,
    DevCenter Backend, CRM secret, and Claude API key values automatically migrated into corresponding
    cards on first launch, so I don't lose my configuration — especially the CRM secret.
27. As a user, I want Agent Run, Home chat, and Projects (Announcements/Bug Reports) to keep working exactly
    as before, so this redesign doesn't regress existing features.
28. As a user, I want editing a card to affect Agent Run/Projects/Home's underlying connections only after
    restarting the app (consistent with today's "Restart to apply" behavior), while the card's own
    health-check status updates live.

### Cookbook (Home chat)

29. As a user, I want the chat model picker to show models from every enabled Local LLM card, not just one
    hardcoded Ollama instance, so I can use multiple local servers.
30. As a user, I want each picker entry to show which card it came from (e.g. "llama3 — Ollama" vs "llama3
    — LM Studio"), so I can tell apart identically-named models from different servers.
31. As a user, I want to enable/disable individual installed models per card, so I can hide models I don't
    want cluttering the picker (e.g. certain Llama or Qwen variants).
32. As a user, I want sending a message to route to the exact server that owns the selected model, so chat
    actually works against the right backend.
33. As a user, if the card backing my currently-selected model is removed or disabled, I want the picker to
    fall back to the first available entry (or show nothing if none remain), so the app doesn't get stuck
    on a dead selection.
34. As a user, if a Local LLM card is unreachable when the cookbook loads, I want it to silently contribute
    zero entries rather than break the rest of the picker, so one offline server doesn't take down the
    whole picker.

### Scope acknowledgement

35. As a user, I understand that scanning models for hardware compatibility and downloading new models are
    out of scope for this release and are planned for a future PRD.

---

## Implementation Decisions

### Domain model — `ServiceCard`

- New model: `{ id, category, type, name, fields: Map<String, String>, enabled: bool, isDefault: bool,
  disabledModels: List<String> }`, with `toJson`/`fromJson`/`copyWith` following the existing `Project`
  model's shape.
- `category` enum: `localLlm | apiLlm | services`.
- `type` enum: `ollama | customLocal | claudeAnthropic | customApi | n8n | customUrl`, each with a `.value`
  string for JSON (same convention as the existing announcement/chat-role enums).
- `fields` keys per type:
  - `ollama`, `customLocal`, `n8n` → `{ baseUrl }`
  - `customUrl` → `{ baseUrl, secret? }`
  - `claudeAnthropic` → `{ apiKey }`
  - `customApi` → `{ baseUrl, apiKey }`
- `disabledModels` is only meaningful for `localLlm`-category cards (cookbook curation); empty by default.

### Storage — datasource / repository / controller

- New SharedPreferences key following the existing namespacing convention (same pattern as the projects
  registry key), storing a JSON-encoded list of `ServiceCard`.
- New datasource (read/write the JSON list) → new repository implementation (`getCards()` /
  `saveCards()`) → new controller extending the async stream-state base class used by the Projects
  controller, exposing `addCard`, `updateCard`, `removeCard`, `setDefault(type, cardId)`, and
  `toggleModelEnabled(cardId, modelName)`.
- `setDefault(type, cardId)` clears `isDefault` on every other card of the same `type` and sets it on the
  target. The first card created for a back-compat type (`ollama`, `n8n`, `customUrl`) is automatically
  `isDefault: true`.

### In-memory configuration cache (replaces `dotenv.env`)

- New singleton cache exposing a synchronous `field(type, key) → String` getter.
- Populated once at startup (after SharedPreferences is ready) from the card list, indexing the
  default-or-only card per back-compat type (`ollama`, `n8n`, `customUrl`).
- A hardcoded defaults table provides fallbacks when no card of that type/field exists:
  - `ollama.baseUrl → http://localhost:11434`
  - `n8n.baseUrl → http://localhost:5678`
  - `customUrl.baseUrl → http://localhost:3000`, `customUrl.secret → ''`
- The Settings UI updates the cache in-memory immediately on save, so health-check status reflects new
  values right away. Agent Run / Home / Projects controllers only re-read the cache the next time their DI
  factories run (app restart) — this preserves today's "Restart the app to apply" behavior.

### Consumer DI updates (mechanical, stay synchronous)

- Agent Run's DI factory: its n8n base-URL lookup (currently `dotenv.env['N8N_BASE_URL'] ?? <default>`)
  becomes a read from the new cache for the `n8n` type. No change to its async/sync shape.
- Projects' DI factories (Announcements, Bug Reports): their DevCenter base-URL and CRM-secret lookups
  become reads from the new cache for the `customUrl` type's `baseUrl`/`secret` fields, still passed into
  the existing shared Dio factory that injects the `x-crm-secret` header.
- Home's DI: the single hardcoded Ollama Dio factory is removed; Ollama/Custom Local Dio construction moves
  into the per-card cookbook plumbing described below.

### `.env` removal

- Remove the `flutter_dotenv` dependency; delete `.env` and `.env.example`.
- Delete the env-override datasource, its SharedPreferences key prefix, and the env-override merge loop in
  app startup.
- App startup sequence becomes: get SharedPreferences → run one-time migration (below) if needed → load the
  card list into the in-memory cache → continue with existing window setup.

### One-time migration

- Runs once at startup, before the cache is populated: if the new card-list key is absent/empty **and** any
  of the old `env_override_*` keys (n8n URL, Ollama URL, DevCenter Backend URL, CRM secret, Claude API key)
  exist, build cards from them:
  - Ollama URL → Ollama card, `isDefault: true`
  - n8n URL → n8n card, `isDefault: true`
  - DevCenter Backend URL (+ CRM secret if present) → Custom URL card with `secret` field, `isDefault: true`
  - Claude API key (if non-empty) → Claude (Anthropic) card
  - Save the resulting list. Old `env_override_*` keys are left in place (now unused, harmless).
- On a fresh install (neither the new key nor old `env_override_*` keys exist), no cards are seeded —
  categories start empty, the cache falls back to the hardcoded defaults table, and each category shows the
  same "nothing here yet" empty state the Projects section uses.

### Health checks

- New `HealthStatus`: `checking | online | offline | error`.
- New `HealthCheckRepository` interface: `check(ServiceCard) → HealthStatus`, with an implementation that
  dispatches per `type`:
  - `ollama` → `GET {baseUrl}/api/tags`
  - `customLocal`, `customApi` → `GET {baseUrl}/v1/models` (with bearer auth for `customApi`)
  - `claudeAnthropic` → Anthropic's `GET /v1/models` with the configured API key
  - `n8n`, `customUrl` → `GET {baseUrl}` with a short timeout (matching the existing shared Dio timeout
    convention); **any** HTTP response = online, connection failure/timeout = offline (no "error" state for
    this uniform check)
  - For the typed checks (everything except `n8n`/`customUrl`): 2xx = online, connection failure/timeout =
    offline, other HTTP responses = error.
- The Services controller tracks status per card id, set to `checking` then resolved. Triggers: on Settings
  > Services mount (all cards), after add/edit of a card (that card only), and via a manual per-card
  refresh action. No periodic/background polling.

### Cookbook (Home chat)

- New `CookbookEntry { cardId, cardName, cardType, model }` value object.
- New `LocalLlmRepository` interface generalizing the existing Ollama repository's contract
  (`listModels()`, `streamChat({model, messages})`):
  - The existing Ollama repository implementation satisfies it unchanged for `ollama`-type cards.
  - A new OpenAI-compatible implementation (list models via `GET {baseUrl}/v1/models`, stream chat via
    `POST {baseUrl}/v1/chat/completions` with `stream: true`, parsing OpenAI-style SSE `data: {...}` lines
    terminated by `data: [DONE]`) satisfies it for `customLocal`-type cards.
- Chat state's `availableModels: List<String>` becomes `List<CookbookEntry>`; `activeModel: String?` becomes
  `activeEntry: CookbookEntry?`.
- On load: for every **enabled** Local LLM card, build the matching `LocalLlmRepository` pointed at that
  card's base URL, call `listModels()` (errors caught per-card — a failing card contributes zero entries),
  filter out models in that card's `disabledModels`, and flatten into the cookbook list. If the previous
  active entry is still present, keep it; otherwise fall back to the first entry, or `null` if the list is
  empty.
- On send: resolve `activeEntry.cardId` back to its card, build the matching `LocalLlmRepository`, and
  stream from it.
- The model switcher renders each entry as `"<model> — <card name>"`.
- The chat empty-state copy ("Chat privately with a local Ollama model...") becomes provider-agnostic since
  Custom Local cards may not be Ollama.

### UI — Settings > Services rewrite

- The Services section is rewritten into three sub-sections (Local LLM, API LLM, Services), each rendering
  the card list for that category as a separated list of card tiles — mirroring the existing Projects
  card-tile layout: name, type label, status dot + label, masked field preview, "Default" tag where
  applicable, and Refresh/Edit/Delete actions.
- Each category's "Add" action opens a small type picker (the category's available types), then the same
  form dialog used for editing, pre-filled empty — mirroring the existing Add/Edit Project dialog
  (type-specific fields, masked obscure+toggle inputs for secrets/API keys, Cancel/Save).
- For Local LLM cards, the edit dialog additionally shows a per-model enable/disable checklist, populated by
  calling `listModels()` for that card when the dialog opens (shows an inline "Unable to load models" message
  if the card is unreachable).

---

## Testing Decisions

A good test here exercises observable state/behavior (persisted data shape, emitted controller state,
routing decisions) rather than internal HTTP call details — consistent with how this codebase already
tests controllers against hand-written fake repositories, with no Dio/HTTP mocking framework in use.

- **Services controller** (new): tested against a fake repository, mirroring the existing Projects
  controller test — add/update/remove/set-default/toggle-model-enabled, plus a persistence round trip
  through the fake.
- **Chat controller cookbook changes**: extends the existing chat controller test — a fake
  service-cards repository supplies enabled Local LLM cards (with `disabledModels`), and a fake
  `LocalLlmRepository` per card (generalizing today's fake Ollama repository) is used to verify: aggregation
  across multiple cards, curation filtering, active-entry selection/switching, `sendMessage` routing to the
  correct fake per card, fallback behavior when the active entry's card disappears, and that one card's
  error doesn't prevent others from contributing entries.
- **Configuration cache**: pure unit tests with no SharedPreferences — given a card list, `field()` returns
  the default-or-only card's value, or the hardcoded fallback when no matching card exists.
- **Migration**: unit tests using SharedPreferences' mock-initial-values support — seed old
  `env_override_*` keys and assert the resulting card list; assert it's a no-op when the new key already
  exists; assert an empty result on a fresh install (neither old nor new keys present).
- **`HealthCheckRepository`**: faked at the controller/state level to cover status-transition behavior
  (checking → online/offline/error triggers and per-card targeting). The real per-type HTTP implementations
  are not unit tested, consistent with the existing Ollama/announcements datasources having no
  datasource-level tests.
- **`ServiceCard` model**: a direct `toJson`/`fromJson` round-trip test given the richer `fields` map and
  `disabledModels` list, similar in spirit to the existing chat-conversation model's serialization shape.

---

## Out of Scope

- Scanning models for hardware compatibility, and browsing/downloading new models — a future PRD.
- ~~API LLM cards (Claude, Custom API) feeding the chat cookbook — configuration + health-check only in this
  release.~~ Implemented by issue 008.
- Live-applying Services/Local LLM/API LLM card edits to already-constructed Agent Run / Home / Projects
  controllers without a restart — only the card's own health-check status and the in-memory cache update
  live.
- Per-project DevCenter Backend URL overrides — Announcements/Bug Reports continue to use the single default
  Custom URL card.
- Periodic/background health-check polling.
- Reordering cards via drag-and-drop.
- Confirmation dialogs on card delete (matches the existing Projects convention of immediate delete).

---

## Further Notes

- The old `CLAUDE_API_KEY` field is retired as a literal env var; its concept lives on as the "Claude
  (Anthropic)" API LLM card type, with any previously-saved value migrated into that card on first launch.
- "DevCenter Backend" is not a distinct card type — it is simply the default "Custom URL" card, whose
  optional `secret` field is sent as the `x-crm-secret` header, matching current behavior.
- This PRD does not change any existing datasource's request logic beyond the new OpenAI-compatible
  datasource and the per-type health-check calls — only how base URLs/headers/keys are sourced (cache vs.
  `dotenv.env`).
- The new SharedPreferences key for the card list follows the same data-namespacing convention as the
  existing projects-registry and chat-conversations keys (per ADR 0002), so dev/prod builds and multiple
  instances remain isolated.
