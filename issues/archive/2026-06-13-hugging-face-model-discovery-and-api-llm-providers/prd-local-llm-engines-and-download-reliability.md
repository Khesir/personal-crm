# PRD: Local LLM Engines/Models Split & Reliable Download Errors

**Status:** Draft
**Date:** 2026-06-13

---

## Problem Statement

In Settings > Services > Local LLM, when a user starts downloading a model via "Search Hugging Face" and
Ollama isn't running, the download card shows a raw `DioException` message ("DioException [connection
error]: The connection errored: The remote computer refused the network connection.") instead of telling
the user what actually went wrong and how to fix it.

Separately, the Local LLM category currently lists Ollama/Custom Local service cards (which are inference
*engines* — runtimes that host and serve models) as peers of the Hugging Face downloads tracked by
`HuggingFaceDownloadTracker` (which are *models*). This conflates two different concepts, and there's no
way to see at a glance which engine is online, or which downloaded models belong to which engine.

---

## Solution

`ModelDiscoveryController.download()` performs a quick reachability check against the target Ollama card
before starting a pull. If the engine isn't reachable, the download fails immediately with a clear message
naming the engine's base URL and stating it isn't reachable — no waiting for a connection timeout, and no
raw Dio text. If the engine becomes unreachable *during* a pull (or any other unmapped connection error
occurs), the failure message is rebuilt from Dio's underlying error description instead of its full object
dump, so the user always sees the real, specific reason.

Settings > Services > Local LLM is restructured into two subsections:

- **Engines** — the existing service cards for Ollama/Custom Local, unchanged (name, health badge, edit,
  delete, refresh, set default, enable toggle).
- **Models** — the Hugging Face downloads tracked via `HuggingFaceDownloadTracker` (from the previous
  cycle), relabeled from "Hugging Face downloads" to "Models".

Above "Models", a horizontal row of engine filter chips ("All" + one chip per engine card, each with a
name and a live online/offline/error indicator reusing the existing health-check status) lets the user
filter the Models list down to a single engine's downloads. "All" is the default and shows every tracked
download, matching today's behavior. Each tracked download now records which engine card it was pulled
into, so this filtering is possible.

---

## User Stories

### Reliable download errors

1. As a user, when I start downloading a model into Ollama and Ollama isn't running, I want to see a clear
   message telling me Ollama isn't reachable at the address the app tried, so I know exactly what to check.
2. As a user, I want that failure to happen immediately, without waiting for a connection timeout, so I'm
   not left staring at a spinner for something that can't succeed.
3. As a user, I never want to see a raw `DioException`/object-dump message in a download card, so the
   error always reads like something a human wrote.
4. As a user, when Ollama becomes unreachable *during* a download (e.g. it crashes or is stopped mid-pull),
   I want a clear "Ollama became unreachable" message that still includes the actual underlying connection
   error detail, so I can tell this apart from a Hugging Face/repo problem.
5. As a user, for any other unexpected download error, I want the message to show the real underlying
   reason rather than a generic "try again later"-style placeholder, so I can diagnose it myself or report
   it accurately.
6. As a user, retrying a failed download (existing retry affordance) should re-run the same reachability
   check, so a retry after starting Ollama succeeds without other changes.

### Engines vs. Models in Settings > Services

7. As a user, I want Settings > Services > Local LLM to show an "Engines" subsection containing my
   configured Ollama/Custom Local cards, so I understand these are the runtimes that host models.
8. As a user, I want all existing engine card actions (edit, delete, refresh, set default, enable/disable)
   to keep working exactly as before in the Engines subsection.
9. As a user, I want a "Models" subsection below Engines showing models I've downloaded via "Search Hugging
   Face", so I can see what's been pulled and its status (downloading/added/failed), same as before.
10. As a user, I want a row of filter chips above "Models" — one per configured engine, plus an "All"
    chip — so I can see which engines exist and quickly narrow the Models list to one of them.
11. As a user, I want each engine chip to show a small colored indicator reflecting that engine's current
    online/offline/error status (the same status shown on its card), so I can tell at a glance whether an
    engine is reachable without scrolling up to the Engines cards.
12. As a user, I want "All" selected by default, so I see every tracked model without extra clicks — this
    must not change the Models list I see today.
13. As a user, tapping an engine chip filters "Models" to only that engine's downloads.
14. As a user, tapping "All" (or tapping the currently-selected engine chip again) clears the filter and
    shows every tracked model again.
15. As a user, if I delete the engine card I currently have selected as a filter, I want the filter to
    reset to "All" automatically, so I don't end up looking at a filter that no longer makes sense.
16. As a user, if I have no engines configured at all, I want the filter-chip row to be hidden entirely
    (Models still shows whatever is tracked, unfiltered), so there's nothing confusing to interact with.
17. As a user, the "Models" subsection should keep behaving exactly as before when unfiltered — live
    progress for in-progress downloads, an "Added" badge for completed ones, an error message + dismiss for
    failed ones — this enhancement must not regress that.
18. As a developer, the chip/filter pattern should be generic over any engine-type service card (currently
    `ollama` and `customLocal`), not hardcoded to Ollama, so a future local-engine type fits the same UI
    without changes.

---

## Implementation Decisions

### Data model

- `HuggingFaceDownload` (`domain/model/huggingface_download.dart`) gains a nullable `serviceCardId`
  (`String?`) — the `id` of the Ollama `ServiceCard` the download was pulled into. `copyWith` is extended to
  support it. `key` (`repoId:quant`) is unchanged.
- `HuggingFaceDownloadTracker` requires no structural changes — `track`/`statusFor`/`dismiss` continue to
  operate on `HuggingFaceDownload` as a whole, now carrying the extra field.

### `ModelDiscoveryController.download()` — pre-flight reachability + error messages

- New constructor parameter `healthCheckRepository` (type `HealthCheckRepository`, the existing interface
  with `Future<HealthStatus> check(ServiceCard card)`), defaulting to `HealthCheckRepositoryImpl()` —
  injectable so tests can supply a fake, following the same pattern as `downloadTracker`.
- At the start of `download()`, after resolving the target card (`card ?? _resolveCardOrNull()`):
  - If a target card was resolved, call `healthCheckRepository.check(target)` **before** calling
    `pullModel()`.
    - `HealthStatus.offline` → set `DownloadStatus.failed("Ollama isn't reachable at <baseUrl>. Make sure
      it's running.")` and return — `pullModel()` is never called.
    - `HealthStatus.online` or `HealthStatus.error` → proceed to `pullModel()` as today (an `error` status
      means *something* answered at that address, so let the actual pull attempt surface whatever's
      specifically wrong).
  - If no target card could be resolved (none/ambiguous), behavior is unchanged from today (existing
    "No Ollama service card is configured"/"Multiple Ollama service cards are configured" messages); no
    health check is performed since there's no card to check.
- In the existing `catch` block around `pullModel()`'s stream:
  - `e is ChatRequestException` → unchanged (`e.message`, from `describeChatError`'s JSON-error mapping).
  - `e is DioException && e.response == null` (connection-level failure, e.g. Ollama stopped mid-pull) →
    `DownloadStatus.failed("Ollama became unreachable at <baseUrl> (${e.message}). Make sure it's
    running.")`, where `<baseUrl>` is the target card's `fields['baseUrl']` and `e.message` is Dio's
    cleaned description (e.g. "The connection errored: The remote computer refused the network
    connection."), not `e.toString()`.
  - Any other `DioException` → `e.message ?? e.toString()` (previously always `e.toString()`).
  - Any other error type → `e.toString()` (unchanged).
- `_setStatus(target, status)` now sets `serviceCardId` on the `HuggingFaceDownload` passed to
  `downloadTracker.track(...)`:
  - When a target card was resolved (the normal path, including both pre-flight-failed and pull-failed
    cases above): `serviceCardId: target.id`.
  - When no target card could be resolved (none/ambiguous failure): `serviceCardId: null`.

### Presentation — Engines/Models split and filter chips

- New widget `EngineFilterChips` (`presentation/widget/engine_filter_chips.dart`) — pure presentation, no
  domain logic, generic over `List<ServiceCard>`:
  - Props: `engines` (`List<ServiceCard>`), `healthStatuses` (`Map<String, HealthStatus>`), `selectedId`
    (`String?`), `onSelect` (`ValueChanged<String?>`).
  - Renders a horizontally scrollable row: an "All" chip (highlighted when `selectedId == null`) followed
    by one chip per engine — label = `card.name`, dot color from `healthStatuses[card.id]` using the same
    color mapping as the existing `_StatusBadge` (online=success, offline/unknown=muted, error=error,
    checking=warning).
  - Tap behavior: tapping "All" calls `onSelect(null)`; tapping an unselected engine chip calls
    `onSelect(card.id)`; tapping the currently-selected engine chip calls `onSelect(null)` (toggles back to
    "All").
- `HuggingFaceDownloadsSection` is renamed to `LocalLlmModelsSection` (same file, renamed), with:
  - Heading text changed from "Hugging Face downloads" to "Models".
  - New optional parameter `filterServiceCardId` (`String?`, default `null`). When non-null, the rendered
    list is additionally filtered to entries where `download.serviceCardId == filterServiceCardId`.
  - All other behavior (non-idle filter, `DownloadProgressIndicator`/`DownloadAddedBadge`/
    `DownloadErrorMessage`, dismiss for added/failed, "render nothing if empty") is unchanged from the
    previous cycle.
- New stateful composing widget (e.g. `presentation/section/local_llm_models_area.dart`) that:
  - Takes the Local LLM category's engine cards (`List<ServiceCard>`, already filtered to
    `category == localLlm`) and the health-status stream/snapshot from `ServiceCardsController`.
  - Owns `selectedEngineCardId` (`String?`) state, defaulting to `null` ("All").
  - If `engines.isEmpty`, renders only `LocalLlmModelsSection()` (no `filterServiceCardId`, no chip row) —
    matches today's behavior with zero engines configured.
  - Otherwise renders `EngineFilterChips(engines: ..., healthStatuses: ..., selectedId:
    selectedEngineCardId, onSelect: ...)` followed by `LocalLlmModelsSection(filterServiceCardId:
    selectedEngineCardId)`.
  - If `selectedEngineCardId` no longer matches any `id` in `engines` (e.g. the selected engine's card was
    deleted), reset it to `null` before rendering.
- `services_section.dart`'s Local LLM `_CategorySection`:
  - Adds an "Engines" heading above the existing card `ListView` (the cards already shown there today —
    `categoryCards` for `ServiceCategory.localLlm`, i.e. `ollama`/`customLocal` types per
    `availableTypes`).
  - Replaces the current direct `HuggingFaceDownloadsSection()` placement with the new composing widget,
    passing `categoryCards` and the controller's health-status stream/snapshot.
  - "Search Hugging Face" and "Add" buttons remain in the category header, unchanged.

### DI

- No changes required to `createModelDiscoveryController` beyond `ModelDiscoveryController`'s new
  `healthCheckRepository` parameter defaulting to `HealthCheckRepositoryImpl()` — the DI factory doesn't
  need to pass it explicitly.

---

## Testing Decisions

General principle (consistent with the previous cycle): test through public interfaces and observable
state — `controller.data`/`tracker.statusFor(...)`/rendered widget output — not private methods. Mock only
boundaries (HTTP via fake Dio adapters / fake repositories), following the fake-implementation pattern
already used for `FakeHuggingFaceDatasource`, `FakeHardwareInfoRepository`, etc.

- **`ModelDiscoveryController` (extend `model_discovery_controller_test.dart`)**:
  - New `FakeHealthCheckRepository implements HealthCheckRepository` whose `check()` returns a
    pre-configured `HealthStatus` and records whether it was called.
  - Test: when the fake returns `HealthStatus.offline`, `download()` sets a `DownloadStatusFailed` whose
    message mentions the card's `baseUrl` and that it isn't reachable, and the fake Ollama datasource's
    `pullModel()` is never invoked.
  - Test: when the fake returns `HealthStatus.online` (or `error`), `download()` proceeds to `pullModel()`
    as before — existing success-path test continues to pass with the fake wired to `online`.
  - Test: a mid-pull `DioException` with no response (simulate via a fake `OllamaDatasource` whose
    `pullModel()` stream errors with a connection-level `DioException`) results in a `DownloadStatusFailed`
    whose message contains Dio's `.message` text and not a `"DioException [...]"` prefix.
  - Test: after a download (success or failure) with a resolved target card, the corresponding
    `HuggingFaceDownload` in the tracker has `serviceCardId` equal to that card's `id`; when no card could
    be resolved (none/ambiguous), `serviceCardId` is `null`.
- **`HuggingFaceDownload`**: extend existing model tests (or add if none exist for this model) to cover
  `serviceCardId` in the constructor and `copyWith`.
- **`EngineFilterChips`** (new widget test file, following the `pumpWidget`/`MaterialApp` pattern from
  `test/core/state/stream_builder_widget_test.dart`):
  - Renders "All" plus one chip per provided engine card, with labels matching `card.name`.
  - Each engine chip's indicator color matches its `HealthStatus` (online/offline/error/checking) via the
    same color mapping as `_StatusBadge`.
  - Tapping an unselected engine chip invokes `onSelect(card.id)`.
  - Tapping the currently-selected engine chip invokes `onSelect(null)`.
  - Tapping "All" invokes `onSelect(null)`.
- **`LocalLlmModelsSection`** (new widget test file):
  - With a tracker containing entries for multiple `serviceCardId`s, `filterServiceCardId: null` renders
    all non-idle entries (regression check for the renamed/previous-cycle behavior).
  - A non-null `filterServiceCardId` renders only entries whose `serviceCardId` matches.
  - Renders nothing when the filtered list is empty.
- **Composing widget** (new widget test file):
  - With ≥1 engine, the chip row is rendered; tapping an engine chip filters the rendered Models list to
    that engine's entries, and tapping "All"/the active chip again restores the full list.
  - With zero engines, no chip row is rendered and `LocalLlmModelsSection` renders unfiltered.
  - If the selected engine's card is no longer present in `engines` on rebuild, the filter resets to "All"
    (full list shown, no chip highlighted).
- `services_section.dart`'s overall composition (Engines heading placement, header buttons) — flagged for
  visual QA, not new automated tests, consistent with how the rest of that screen has been treated.

---

## Out of Scope

- A native/bundled inference engine (e.g. llama.cpp) as an alternative to Ollama — discussed and parked as
  a separate future roadmap item; this PRD only improves error handling and presentation around the
  existing Ollama-based flow.
- Persisting `HuggingFaceDownloadTracker` across app restarts — it remains in-memory/app-lifetime only, as
  scoped in the previous cycle. The Models list (and its per-engine filter) reflects only downloads tracked
  during the current session.
- Querying Ollama's actual installed-model list (`/api/tags` for models) to populate "Models" — Models
  remains "things downloaded through this app's Search Hugging Face dialog," not a full reflection of an
  engine's model library.
- Multi-select engine filtering — the filter row is single-select ("All" or exactly one engine).
- Editing/managing engines via the filter chips — chips are filter-only; all engine management (edit,
  delete, set default, etc.) stays on the existing Engine cards.
- Changes to which engines can be download targets — `resolveOllamaCard()` remains specific to
  `ServiceType.ollama`. `customLocal` engines appear in the filter row (for UI consistency and to keep the
  pattern open to future engine types) but will never have associated Models entries today, since downloads
  can only target Ollama.

---

## Further Notes

- This builds directly on the previous cycle's `HuggingFaceDownloadTracker`/`HuggingFaceDownloadsSection`
  (file rename + new optional parameter, not a rewrite) and on the existing `HealthCheckRepository` (reused
  as-is, no interface changes).
- No new `ServiceType`/`ServiceCategory` enum values are introduced — "Engines" and "Models" are a
  presentation-layer grouping of the existing `ollama`/`customLocal` types within
  `ServiceCategory.localLlm`, plus the existing download tracker.
- Error-message wording always names the concrete engine address and either states it's unreachable or
  includes Dio's underlying `.message` — never a generic "try again later"-style placeholder.
