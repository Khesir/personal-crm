# Handoff: Settings > Services card redesign (/grill-me in progress)

## Goal
Redesign the CRM frontend's Settings > Services section from a flat list of env-var text fields into a
card-based UI, organized into categories, where each card represents one configured service with its own
inputs and a live health-check status. Also (per latest scoping decision) extend the Home chat "model
picker" so it pulls from these configured LLM cards ("cookbook" of selectable models).

## Status
We are mid-`/grill-me` (Phase 2 — relentless one-question-at-a-time interview). Phase 1 (understanding) was
confirmed by the user. Several Phase 2 decisions are locked in below. **Grilling is NOT finished** — do not
jump to `/to-prd` until the open questions below are resolved.

## Relevant code (read these, don't re-derive from memory)
- `lib/features/settings/presentation/section/services_section.dart` — current flat-field UI to be replaced
  (`_kServiceFields`: N8N_BASE_URL, OLLAMA_BASE_URL, DEVCENTER_BACKEND_URL, CRM_SECRET, CLAUDE_API_KEY)
- `lib/features/settings/data/datasource/settings_env_datasource.dart` — persists via
  `prefs.setString('env_override_<KEY>', value)` and mirrors into `dotenv.env`
- `lib/features/settings/domain/{controller,repository}/settings_*` + `data/repository/settings_repository_impl.dart`
- `lib/features/settings/di.dart`, `lib/features/settings/api.dart` — wiring/barrel export
- Consumers reading `dotenv.env` directly at DI time (will need to adapt to new storage, or the new storage
  must keep writing the same `env_override_<KEY>` keys for back-compat):
  - `lib/features/agent_run/di.dart` → `N8N_BASE_URL`
  - `lib/features/home/di.dart` → `OLLAMA_BASE_URL`
  - `lib/features/projects/di.dart` → `DEVCENTER_BACKEND_URL`, `CRM_SECRET`
- `lib/features/home/data/datasource/ollama_datasource.dart` — has `listModels()` (GET `/api/tags`), useful
  for the Local LLM card's health check + the future model "cookbook"
- `lib/core/network/base_api.dart` — shared Dio factory with optional `x-crm-secret` header injection
- `.env.example` — current canonical list of env keys
- Prior related issue (closed, for reference on conventions used): `issues/archive/2026-06-12-dev-command-center/done/002-settings-services-about.md`
- No existing health-check infrastructure anywhere in the codebase — this is net-new.

## Decisions locked in so far
1. **Categories (3, fixed):**
   - **Local LLM** — e.g. Ollama: base URL only, no API key. Feeds the chat model picker/"cookbook".
   - **API LLM** — e.g. Claude: API key based. Also feeds the model picker.
   - **Services** — e.g. n8n, DevCenter Backend, custom URL services. Health-checked but NOT part of the
     chat model picker.
2. **Multiple cards per category** — each category is a list. An "Add" action opens a picker of known
   service types for that category (e.g. Local LLM → Ollama, possibly LM Studio-compatible; API LLM →
   Claude, possibly OpenAI-compatible; Services → n8n, DevCenter Backend, Custom URL). User can add several
   cards per category, each with its own inputs and health check.
3. **Scope = both in one PRD**: this PRD covers BOTH (a) the Settings > Services card UI/storage/health
   checks AND (b) redesigning the Home chat screen's model selector to pull from all configured Local LLM +
   API LLM cards ("cookbook").

## Open questions (resume grilling here, one at a time, with a recommended option each)
- Exact known service "types" per category for the "Add" picker (confirm: Ollama for Local LLM; Claude
  for API LLM — any others like OpenAI/LM Studio in v1 or later?).
- Data model / storage for the new card list: new SharedPreferences-backed JSON list (id, category, type,
  name, fields map, enabled) vs. continuing to layer on `env_override_<KEY>`. How do existing single-value
  consumers (`agent_run`, `home`, `projects` di.dart) resolve "the" active n8n/DevCenter Backend/Ollama
  config when multiple cards could exist per category — is there a concept of "default"/"active" card per
  category, or per-type?
- Health-check implementation per type: Ollama (`GET /api/tags`, already have datasource), n8n (what
  endpoint — `/healthz`?), DevCenter Backend (NestJS — `/api/v1` health route?), Claude API (lightweight
  call without burning quota?), Custom (plain GET, check 2xx?). Manual refresh button vs. auto on screen
  load vs. periodic polling?
- Card UI details: collapsed vs expanded state, status indicator design (dot + label: checking/online/
  offline/error), per-card "Remove" action, secret/API-key field masking (existing `_EnvField.secret`
  pattern).
- The chat "cookbook" model picker: where does it live in the Home chat UI, how are Local LLM models
  (via `listModels()`) vs API LLM models (e.g. fixed Claude model list) merged into one picker, what
  happens to the currently-selected model when its backing card is removed/disabled.
- Back-compat: do `agent_run/di.dart`, `home/di.dart`, `projects/di.dart` get rewritten to read from the new
  service-card storage now, or keep reading `env_override_<KEY>` (written by a "default" card of each
  relevant type) to minimize blast radius?

## Suggested skills for next session
1. `/grill-me` (no args needed) — resume Phase 2 using the open questions above as the starting point.
2. `/to-prd` — once grilling concludes ("I think we've resolved everything").
3. `/to-issues` — after the PRD is written, to break it into issue files under `issues/`.

## Notes
- No code has been changed yet — this is purely a planning/grilling session.
- Project follows Flutter Clean Architecture per `CLAUDE.md`: feature folder with
  presentation/{screen,section,widget,state,sheets,dialogs,helpers}, domain/{controller,repository},
  data/{repository,datasource}; `StreamState`/`StreamStateBuilder` only; custom DI/service locator only;
  `AppStyling`/`AppColors` for all styling; 500-line file limit; module barrel `api.dart`.
