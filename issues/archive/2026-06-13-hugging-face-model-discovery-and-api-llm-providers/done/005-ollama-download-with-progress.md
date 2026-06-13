---
id: issue-005
title: "One-click download into Ollama with progress"
feature: model-discovery
status: done
created_at: 2026-06-13
tags: [afk, p2]
---

# [005] One-click download into Ollama with progress

**Type:** AFK
**Priority:** P2
**Blocked by:** 003
**User stories covered:** 25, 26, 27, 28, 29, 30, 31, 32

---

## What to build

A "Download" action on each Hugging Face search result (from issue 003) that pulls the chosen model+quant
into the user's Ollama install, with inline progress and automatic cookbook pickup on success.

- `OllamaDatasource.pullModel({required String name})`:
  - `POST /api/pull` with `{"name": name, "stream": true}`, `responseType: stream`.
  - Parses newline-delimited JSON progress objects (`{"status": ..., "total": ..., "completed": ...}`) into
    `Stream<OllamaPullProgress { status, totalBytes, completedBytes }>`, completing on
    `{"status": "success"}`.
  - Errors (Ollama unreachable, invalid repo/quant, etc.) are mapped via the same
    `describeChatError`-style approach as `chat_error_mapper.dart`, surfacing a meaningful message.
- `ModelDiscoveryController.download(HuggingFaceModelResult result)`:
  - Resolves the target Ollama card: the Default-marked Ollama card if one exists; the sole Ollama card if
    there's exactly one; otherwise prompts the user to pick one. If there is no Ollama card at all, download
    is unavailable.
  - Calls `pullModel(name: 'hf.co/${result.repoId}:${result.quant}')`.
  - Exposes per-result state (`idle`, `downloading(progress)`, `added`, `failed(error)`) via the
    controller's state stream, keyed by result.
- UI: "Download" button per row. While downloading, the row shows an inline progress bar/percentage instead
  of the button; on success the row shows "Added"; on failure the row shows an error and the Download
  button again. The user can keep searching/browsing while a download is in progress.
- On successful pull, no extra wiring is needed for the model to reach the Home chat cookbook — the
  existing `ChatController.refresh()` (already triggered whenever Home becomes visible, via `home/di.dart`)
  re-lists models from each enabled Ollama card and will pick up the newly pulled model.

---

## Acceptance criteria

- [ ] Each result row has a "Download" button.
- [ ] If no Ollama card is configured, the Download button is disabled with an explanation; search/browse
  and FIT info remain usable.
- [ ] If exactly one Ollama card exists (or one is marked Default), clicking Download pulls into that card
  without prompting.
- [ ] If multiple Ollama cards exist and none is Default, clicking Download prompts the user to choose one.
- [ ] While downloading, the row shows an inline progress indicator reflecting `/api/pull`'s streamed
  progress; the rest of the dialog (search, other rows) remains interactive.
- [ ] On success, the row shows it was added, and the model appears in the Home chat cookbook for that
  Ollama card (after the existing refresh-on-visit) without requiring an app restart.
- [ ] On failure (e.g. Ollama not running, invalid repo/quant), the row shows an error and offers Download
  again.

---

## Tests required

Yes:
- New `OllamaDatasource.pullModel()` test (same fake-adapter streaming pattern as the existing `streamChat`
  tests): feed canned NDJSON progress lines and assert the resulting `OllamaPullProgress` stream; an error
  case (non-2xx response) asserts the mapped error.
- Extend the `ModelDiscoveryController` test from issue 003: `download()` transitions a result through
  `idle → downloading → added` given a fake pull stream; download is unavailable when no Ollama card
  exists; a failed pull surfaces a `failed` state with the mapped error.

---

## Notes

- Download is Ollama-only — Custom Local (e.g. LM Studio) servers have no documented pull-from-HF API and
  are out of scope.
- `ollama pull hf.co/<repo>:<quant>` is the exact pull-name format Ollama expects for Hugging Face GGUF
  repos.
- Builds on issue 003's results and controller; does not require issue 004's FIT scoring to function
  (FIT/SPEED/SCORE columns and the Download column can land independently once 003 is done).

---

## Log

_Updated as work progresses._

- Implemented `OllamaPullProgress`, `OllamaDatasource.pullModel()` (NDJSON `/api/pull`, completes on
  `{"status":"success"}`, errors mapped via `describeChatError`), `DownloadStatus`/`OllamaCardResolution`
  sealed classes, `ModelDiscoveryResult.downloadStatus` + `copyWith`, and
  `ModelDiscoveryController.resolveOllamaCard()`/`download()` (factory-injected `OllamaDatasource`, surgical
  `update()` per-row status transitions idle -> downloading -> added/failed).
- Wired DI: `createModelDiscoveryController(List<ServiceCard> cards)` now takes the already-loaded service
  cards (sync, no new SharedPreferences dep); `_openHuggingFaceSearch` passes `controller.data`. Added a
  DOWNLOAD column to `HuggingFaceSearchDialog`/`_ResultRow` with a Download button (disabled + tooltip when
  no Ollama card), inline progress bar while downloading, "Added" badge, failed+retry, and an Ollama-card
  picker dialog for the ambiguous (multiple, none Default) case.
- Tests: new `test/features/home/data/datasource/ollama_datasource_test.dart` (3 tests: NDJSON progress
  parsing, success-line completion, mapped error) and 8 new tests in `model_discovery_controller_test.dart`
  (`resolveOllamaCard` for none/sole/default/ambiguous, and `download()` for success progression, explicit
  card choice, no-card failure, and mapped pull-error failure). Full suite: 182/182 passing;
  `flutter analyze` clean (same 2 pre-existing `activeColor` infos).

QA approved by user on 2026-06-13.
