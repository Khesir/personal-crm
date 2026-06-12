---
id: issue-004
title: "Service cards cache, .env removal, and migration"
feature: service-cards
status: done
created_at: 2026-06-12
tags: [afk, p2]
---

# [004] Service cards cache, `.env` removal, and migration

**Type:** AFK
**Priority:** P2
**Blocked by:** 003
**User stories covered:** 24, 25, 26, 27, 28

---

## What to build

Replace `.env`/`flutter_dotenv`/`env_override_<KEY>` entirely with the service-card storage from issue 003,
via a synchronous in-memory cache, a one-time migration, and mechanical DI updates.

- New `ServiceCardsCache` singleton exposing a synchronous `field(type, key) → String` getter. Populated
  once at startup (after SharedPreferences is ready) from the card list, indexing the default-or-only card
  per back-compat type (`ollama`, `n8n`, `customUrl`).
- Hardcoded defaults table (`kServiceTypeDefaults`) providing fallbacks when no card of that type/field
  exists:
  - `ollama.baseUrl → http://localhost:11434`
  - `n8n.baseUrl → http://localhost:5678`
  - `customUrl.baseUrl → http://localhost:3000`, `customUrl.secret → ''`
- One-time migration, run at startup before the cache is populated: if the new card-list key is
  absent/empty **and** any of the old `env_override_*` keys (n8n URL, Ollama URL, DevCenter Backend URL,
  CRM secret, Claude API key) exist, build cards from them and persist via the repository from issue 003:
  - Ollama URL → Ollama card, `isDefault: true`
  - n8n URL → n8n card, `isDefault: true`
  - DevCenter Backend URL (+ CRM secret if present) → Custom URL card with `secret` field, `isDefault:
    true`
  - Claude API key (if non-empty) → Claude (Anthropic) card
  - Old `env_override_*` keys are left in place afterward (now unused, harmless).
  - On a fresh install (neither the new key nor old `env_override_*` keys exist), no cards are seeded —
    the cache falls back to `kServiceTypeDefaults` and Settings shows empty states.
- Remove the `flutter_dotenv` dependency; delete `.env` and `.env.example`; delete the env-override
  datasource, its SharedPreferences key prefix, and the env-override merge loop in app startup.
- App startup sequence becomes: get SharedPreferences → run migration if needed → load the card list into
  `ServiceCardsCache` → continue with existing window setup (unchanged).
- Mechanical DI rewrites, staying synchronous:
  - Agent Run's n8n base-URL lookup reads `ServiceCardsCache.instance.field(n8n, 'baseUrl')` instead of
    `dotenv.env['N8N_BASE_URL']`.
  - Projects' Announcements/Bug Reports DI reads DevCenter base URL/secret from
    `ServiceCardsCache.instance.field(customUrl, 'baseUrl' / 'secret')` instead of
    `dotenv.env['DEVCENTER_BACKEND_URL']` / `dotenv.env['CRM_SECRET']`, still passed into the existing
    shared Dio factory that injects the `x-crm-secret` header.
- The Settings UI updates the cache in-memory immediately on save, so a card's own health-check status
  reflects new values right away. Agent Run / Home / Projects controllers only re-read the cache the next
  time their DI factories run (app restart) — this preserves today's "Restart the app to apply" behavior
  and messaging.

---

## Acceptance criteria

- [x] On any install — fresh or upgrade from a version that had `env_override_*` keys — no service cards
  are ever auto-created; Settings > Services shows only cards the user has manually added (empty on a
  fresh/upgraded install with none added yet).
- [x] Old `env_override_*` keys, if present from a prior version, are left in place and unused — nothing
  reads or writes them anymore.
- [x] On a fresh install (no `env_override_*` keys, no card list), no cards are seeded, Settings > Services
  shows empty states, and the hardcoded defaults apply silently.
- [x] Agent Run continues to reach n8n using the default/only n8n card's base URL, or the hardcoded
  `localhost:5678` default if no n8n card exists.
- [x] Announcements/Bug Reports continue to reach DevCenter Backend using the default/only Custom URL
  card's base URL + secret (sent as `x-crm-secret`), or the hardcoded defaults if no Custom URL card
  exists.
- [x] `flutter_dotenv` is removed from `pubspec.yaml`, and `.env`/`.env.example` no longer exist in the
  repo.
- [x] The app builds and runs correctly with no `.env` file present.

---

## Tests required

Yes — `ServiceCardsCache` unit tests (pure, no SharedPreferences): given a card list, `field()` returns the
default/only card's value, or the `kServiceTypeDefaults` fallback when no matching card exists. Migration
unit tests using SharedPreferences' mock-initial-values support: seeded `env_override_*` keys produce the
expected card list; the migration is a no-op when the card-list key already exists; the result is empty on
a fresh install.

---

## Notes

- This is the highest-risk slice in the PRD: it deletes the `.env` mechanism and migrates the CRM secret —
  double-check the migration's field mapping against the exact old `env_override_*` key names before
  merging.
- Per the PRD, this slice does not change any existing datasource's request logic — only how base
  URLs/headers/keys are sourced (cache vs. `dotenv.env`).
- Home's DI is *not* touched here — Ollama's Dio construction moves to the per-card cookbook plumbing in
  issue 007, not the cache.

---

## Log

_Updated as work progresses._

- Added `ServiceCardsCache` singleton + `kServiceTypeDefaults` (`lib/features/settings/domain/model/service_cards_cache.dart`),
  indexing the default-or-only card per back-compat type (`ollama`, `n8n`, `customUrl`) with hardcoded fallbacks.
- Added a one-time `.env` -> service-card migration (`lib/features/settings/data/migration/service_cards_migration.dart`),
  no-op if the card list already exists or no `env_override_*` keys are present. Wired into a new
  `initServiceCardsCache(prefs)` orchestration function in `lib/features/settings/di.dart`.
- Rewrote `lib/main.dart` startup: removed `flutter_dotenv`/`kSettingsPrefix`/env-merge loop, now calls
  `SharedPreferences.getInstance()` -> `initServiceCardsCache(prefs)` before window setup.
- Mechanical DI rewrites to read from `ServiceCardsCache.instance.field(...)` instead of `dotenv.env[...]`:
  `agent_run/di.dart` (n8n base URL), `projects/di.dart` (Custom URL base URL/secret, empty secret -> `null`),
  and `home/di.dart` (Ollama base URL, required for compile after removing `flutter_dotenv`).
- Added cache-sync (`ServiceCardsCache.instance.load(updated)`) to `addCard`/`updateCard`/`removeCard`/`setDefault`
  in `service_cards_controller.dart` so Settings reflects new values immediately.
- Deleted the dead env-override settings chain (`settings_env_datasource.dart`, `settings_repository.dart`,
  `settings_repository_impl.dart`, `settings_controller.dart`, `createSettingsController()`) and its export from
  `lib/features/settings/api.dart`. No orphaned tests existed for these.
- Removed `flutter_dotenv` from `pubspec.yaml` (dependency + `.env` asset entry), deleted `.env` and `.env.example`,
  ran `flutter pub get` to refresh `pubspec.lock`.
- Tests: added `test/features/settings/domain/model/service_cards_cache_test.dart` (7 tests) and
  `test/features/settings/data/migration/service_cards_migration_test.dart` (6 tests), all passing.
  `flutter analyze` is clean (only 2 pre-existing `activeColor` deprecation infos in unrelated files), and the
  full `flutter test` suite passes (107/107).
- QA rejected on 2026-06-13. Bug appended — the automatic `.env` -> service-card migration auto-seeds "Default" cards (Ollama, n8n, Custom URL, Claude) without user action; this is unwanted. Service cards should be configured manually by the user.
- Bug fixed on 2026-06-13. Removed the one-time `.env` -> service-card migration entirely (deleted `service_cards_migration.dart` and its test, and the call from `initServiceCardsCache` in `lib/features/settings/di.dart`); `ServiceCardsCache` + `kServiceTypeDefaults` are kept exactly as implemented as a synchronous DI-only localhost fallback that creates no visible cards; acceptance criteria updated to require that no cards are ever auto-created and that old `env_override_*` keys are left unused.
- QA approved by user on 2026-06-13. User noted any further migration/seeding work should be revisited via a future PRD rather than as part of this issue.

---

## Bug

**Reported:** 2026-06-13
**Found during:** Visual QA
**Description:** The `.env` -> service-card migration automatically creates "Default" cards (Ollama, n8n, Custom URL, Claude) from old `env_override_*` values at app startup, with no user action. The user does not want this: connections like Ollama and n8n are set up manually by the user in Settings > Services, not auto-generated by the system. Given this constraint, the scope of this issue (the auto-migration and its auto-"Default" cards) may need to be significantly reduced or removed entirely — re-evaluate before reimplementing.

### What to fix
_To be investigated during implementation — discuss/decide with the user whether:_
- _the `.env` -> service-card migration should be removed entirely (no cards auto-seeded on upgrade; the user adds them manually in Settings > Services)_
- _`ServiceCardsCache`'s hardcoded `kServiceTypeDefaults` fallback should remain as the no-cards-configured behavior, or whether dependent features (Agent Run, Announcements/Bug Reports) should instead show a clear "not configured" state until the user manually adds a card_
- _the `.env`/`flutter_dotenv` removal and dead-code deletion from this issue's original scope should be kept regardless of the migration's fate (these seem independently desirable)_

### Acceptance Criteria
- [x] Bug no longer reproduces
- [x] Original acceptance criteria still met
- [x] A test exists that would have caught this
