---
id: issue-007
title: "Reliable Ollama download errors"
feature: local-llm-engines
status: done
created_at: 2026-06-13
tags: [afk, p1]
---

# [007] Reliable Ollama download errors

**Type:** AFK
**Priority:** P1
**Blocked by:** None
**User stories covered:** 1, 2, 3, 4, 5, 6 (Reliable download errors), plus the `serviceCardId` data-model addition from Implementation Decisions

---

## What to build

`ModelDiscoveryController.download()` performs a quick reachability check (via `HealthCheckRepository.check()`) against the resolved target Ollama card before calling `pullModel()`. If the engine is offline, the download fails immediately with a message naming the engine's `baseUrl` and stating it isn't reachable — `pullModel()` is never called, so there's no waiting on a connection timeout.

If the engine becomes unreachable mid-pull (a `DioException` with no `response`), or any other unmapped `DioException` occurs, the resulting failure message is built from Dio's `.message` (the cleaned description), not `e.toString()` — so the user always sees the real underlying reason instead of a raw object dump or a generic placeholder.

`HuggingFaceDownload` gains a nullable `serviceCardId` field recording which engine card a download targeted (the resolved card's `id`, or `null` if no card could be resolved). This field is set whenever `_setStatus()` tracks a download, for both success and failure paths, and is required groundwork for the engine-filtering work in issue 009.

Error message shapes:
- Pre-flight offline: `"Ollama isn't reachable at <baseUrl>. Make sure it's running."`
- Mid-pull connection drop: `"Ollama became unreachable at <baseUrl> (<dio .message>). Make sure it's running."`
- Any other `DioException`: `e.message ?? e.toString()`
- Anything else: `e.toString()` (unchanged)

---

## Acceptance criteria

- [ ] Starting a download while the target Ollama engine is offline fails immediately (no `pullModel()` call) with a message naming the engine's `baseUrl` and stating it isn't reachable.
- [ ] When the health check returns `online` or `error`, `download()` proceeds to `pullModel()` as before.
- [ ] A mid-pull connection-level `DioException` (no `response`) produces a failure message containing Dio's `.message` text, with no raw `"DioException [...]"` prefix and no generic "try again later"-style text.
- [ ] Any other `DioException` without a mapped message falls back to `e.message ?? e.toString()` instead of always `e.toString()`.
- [ ] If no target card could be resolved (none/ambiguous), existing behavior and messages are unchanged, and no health check is performed.
- [ ] `HuggingFaceDownload.serviceCardId` is set to the resolved target card's `id` on both success and failure, or `null` when no card could be resolved.
- [ ] Retrying a failed download re-runs the reachability check (no special-casing needed — same `download()` path).

---

## Tests required

Yes — extend `model_discovery_controller_test.dart`:
- New `FakeHealthCheckRepository implements HealthCheckRepository` (configurable `HealthStatus`, records call).
- `offline` health check → `DownloadStatusFailed` with the "isn't reachable" message naming `baseUrl`; fake datasource's `pullModel()` never invoked.
- `online`/`error` health check → existing success path still passes (fake wired to `online`).
- Mid-pull connection-level `DioException` (no response) → failure message contains Dio's `.message`, not a `DioException [...]` dump.
- After any download (success or failure) with a resolved target card, the tracked `HuggingFaceDownload.serviceCardId` equals that card's `id`; when unresolved, it's `null`.

Extend `HuggingFaceDownload` model tests for `serviceCardId` in the constructor and `copyWith`.

---

## Notes

- `healthCheckRepository` is a new constructor parameter on `ModelDiscoveryController`, defaulting to `HealthCheckRepositoryImpl()` — same injection pattern as the existing `downloadTracker` parameter. No DI factory changes needed beyond this default.
- `HealthCheckRepository`/`HealthStatus` interfaces are unchanged — reuse as-is.
- Error wording must always name the concrete engine address and either state it's unreachable or include Dio's underlying `.message` — never a generic placeholder (explicit user requirement).

---

## Log

_Updated as work progresses._

- Added `HuggingFaceDownload.serviceCardId` (nullable, `copyWith` support) and a new `healthCheckRepository` constructor param (defaults to `HealthCheckRepositoryImpl()`) on `ModelDiscoveryController`.
- `download()` now health-checks the resolved target card before `pullModel()`: `offline` fails immediately with an "isn't reachable at <baseUrl>" message without calling `pullModel()`; `online`/`error` proceed as before. The catch block now distinguishes connection-level `DioException` (no `response`, "became unreachable at <baseUrl> (<dio message>)"), other `DioException`s (`e.message ?? e.toString()`), and other errors (`e.toString()`, unchanged). `_setStatus` now tracks `serviceCardId` (resolved card's `id`, or `null`).
- Added `test/features/settings/domain/model/huggingface_download_test.dart` (4 tests) and extended `model_discovery_controller_test.dart` with `FakeHealthCheckRepository` and 6 new tests (offline pre-check, mid-pull connection error, other DioException fallback, serviceCardId tracking for resolved/unresolved cards). All 25 tests pass; `flutter analyze` clean on touched files.
- QA approved by user on 2026-06-13.
