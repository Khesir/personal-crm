---
id: issue-006
title: "Persist and surface Hugging Face download status outside the search dialog"
feature: model-discovery
status: done
created_at: 2026-06-13
tags: [afk, p2]
---

# [006] Persist and surface Hugging Face download status outside the search dialog

**Type:** AFK
**Priority:** P2
**Blocked by:** None (builds on 003/005, both in qa)

---

## What to build

`ModelDiscoveryController` (and its per-result download status) is currently created fresh each time
the "Search Hugging Face" dialog opens and disposed when it closes. If a user starts a download and
closes the dialog before it finishes, the pull keeps running in Ollama but the UI loses all track of
it — reopening the dialog shows every result back at idle, and Settings has no indication a download
is/was in progress.

Lift download tracking into a small app-lifetime singleton that survives the dialog closing, and
surface it from the Local LLM category in Settings > Services:

- New `HuggingFaceDownload` model: `repoId`, `quant`, `displayName`, `status` (reuse the existing
  `DownloadStatus` sealed class), keyed by `repoId:quant`.
- New `HuggingFaceDownloadTracker` (singleton `StreamState<List<HuggingFaceDownload>>`, app lifetime,
  in-memory only — no persistence across app restarts):
  - `statusFor(repoId, quant)` — current tracked status, or `DownloadStatus.idle()` if untracked.
  - `track(HuggingFaceDownload)` — insert or update an entry by key.
  - `dismiss(repoId, quant)` — remove a completed/failed entry from the list.
- `ModelDiscoveryController.download()` mirrors every status transition
  (`downloading` → `added`/`failed`) into the tracker via `track(...)`, in addition to its existing
  per-result `_setStatus` update.
- `ModelDiscoveryController._withFit` initializes each `ModelDiscoveryResult.downloadStatus` from
  `tracker.statusFor(model.repoId, model.quant)` instead of always starting at `idle` — so
  `load()`/`search()` (including a fresh controller after reopening the dialog) reflect any
  in-progress/completed/failed download for that (repo, quant).
- New section in the Local LLM category (Settings > Services) listing tracked downloads: shows
  `displayName` plus the same inline progress bar / "Added" badge / error+dismiss treatment used in
  the search dialog. Entries can be dismissed once `added` or `failed`; in-progress entries update
  live via the tracker's stream.
- `HuggingFaceDownloadTracker` is injected into `ModelDiscoveryController` (defaulting to
  `HuggingFaceDownloadTracker.instance` in `createModelDiscoveryController`), so tests can supply a
  fresh instance per test.

---

## Acceptance criteria

- [ ] Starting a download from "Search Hugging Face" and closing the dialog before it finishes does
  not lose progress — the pull continues against Ollama and its status keeps updating.
- [ ] Reopening "Search Hugging Face" shows the correct status (downloading with current progress,
  added, or failed) for any previously started download of the same (repo, quantization), instead of
  resetting to idle.
- [ ] The Local LLM category in Settings > Services shows a list of in-progress and
  recently-completed/failed Hugging Face downloads, with live progress for in-progress entries.
- [ ] A completed ("Added") or failed download can be dismissed from the Local LLM list.
- [ ] Existing "Search Hugging Face" download behavior (idle → downloading → added/failed, retry on
  failure, card-picker for ambiguous Ollama cards) continues to work as before.

---

## Tests required

Yes:
- New `HuggingFaceDownloadTracker` test: `track()` inserts/updates entries by (repoId, quant) key,
  `statusFor()` returns `idle` for untracked keys and the tracked status otherwise, `dismiss()`
  removes an entry, and the stream emits on each change.
- Extend `model_discovery_controller_test.dart`: `download()` mirrors status transitions into a
  fake/fresh tracker instance; a fresh `ModelDiscoveryController` constructed with a tracker that
  already has a `downloading`/`added`/`failed` entry for a result's (repoId, quant) initializes that
  result's `downloadStatus` accordingly on `load()`.

---

## Notes

- In-memory only for this issue — surviving an app restart (and reconciling with whatever Ollama
  actually finished pulling while the app was closed) is out of scope; flag as a further follow-up if
  it comes up again.
- Reuse the existing `DownloadStatus` sealed class and the search dialog's progress/added/failed cell
  widgets where practical rather than duplicating presentation logic.
- Builds on 003 (`ModelDiscoveryController`, `HuggingFaceSearchDialog`) and 005 (`DownloadStatus`,
  `download()`) — both currently in `qa`.

---

## Log

- Added `HuggingFaceDownload` model (`lib/features/settings/domain/model/huggingface_download.dart`):
  `repoId`, `quant`, `displayName`, `status`, keyed by `repoId:quant`.
- Added `HuggingFaceDownloadTracker` (`lib/features/settings/domain/controller/huggingface_download_tracker.dart`):
  app-lifetime singleton `StreamState<List<HuggingFaceDownload>>` with `statusFor`, `track`,
  `dismiss`.
- `ModelDiscoveryController` now takes an injectable `downloadTracker` (defaults to
  `HuggingFaceDownloadTracker.instance`):
  - `_withFit` seeds each result's `downloadStatus` from `downloadTracker.statusFor(repoId, quant)`
    instead of always `idle`.
  - `_setStatus` mirrors every transition (`downloading` → `added`/`failed`) into the tracker via
    `track(...)`.
- Extracted the search dialog's progress/added/error cells into shared widgets
  (`lib/features/settings/presentation/widget/huggingface_download_status_widgets.dart`):
  `DownloadProgressIndicator`, `DownloadAddedBadge`, `DownloadErrorMessage`. Updated
  `huggingface_search_dialog.dart` to use them and removed the old private
  `_ProgressIndicatorCell`/`_AddedBadge` classes.
- Added `HuggingFaceDownloadsSection` (`lib/features/settings/presentation/section/huggingface_downloads_section.dart`):
  lists non-idle tracked downloads (live via the tracker's stream), with a dismiss button for
  `added`/`failed` entries. Wired into the Local LLM category of `services_section.dart`, rendering
  nothing when no downloads are tracked.
- Tests:
  - New `huggingface_download_tracker_test.dart` — `track()` insert/update by key, `statusFor()`
    idle vs tracked, `dismiss()`, stream emission.
  - Extended `model_discovery_controller_test.dart` — `download()` mirrors transitions into the
    tracker (success and failure), and a fresh controller initializes `downloadStatus` from a
    tracker entry left by a previous controller.
- Verified: `flutter analyze` clean (only pre-existing `activeColor` deprecation infos),
  `flutter test` 191/191 pass, `flutter build windows --debug` succeeds.
- QA approved by user on 2026-06-13.
