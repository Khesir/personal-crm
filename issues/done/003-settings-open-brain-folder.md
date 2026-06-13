---
id: issue-003
title: "Settings: \"Brain\" section with Open brain folder button"
feature: brain
status: done
created_at: 2026-06-13
tags: [afk, p2]
---

# [003] Settings: "Brain" section with Open brain folder button

**Type:** AFK
**Priority:** P2
**Blocked by:** 001
**User stories covered:** 12

---

## What to build

Add a new "Brain" section to Settings (alongside existing sections like Services/Projects/About) with a
short description and an "Open brain folder" button.

- The button resolves the brain folder path (same resolution as `BrainRepository` in issue 001 —
  `%APPDATA%/Codex/brain/<dev|prod>/`) and opens it in the OS file explorer.
- Use the existing `ProcessRunner` abstraction
  (`lib/features/settings/domain/repository/process_runner.dart`, `IoProcessRunner`) to run
  `explorer <path>` (Windows).
- No in-app file viewer/editor, no enable/disable toggle — out of scope per `issues/prd.md`.

---

## Acceptance criteria

- [ ] A new "Brain" section appears in Settings navigation/sidebar alongside existing sections.
- [ ] The section shows a short description and an "Open brain folder" button.
- [ ] Tapping the button calls `ProcessRunner.run('explorer', [<resolved brain folder path>])`.
- [ ] The resolved path matches the brain folder path used by `BrainRepository` (issue 001), including
  `dev`/`prod` namespacing.

---

## Tests required

Yes — test the button's tap handler with a fake `ProcessRunner` (mirroring existing `ProcessRunner`-based
tests in `settings`), asserting `run('explorer', [<resolved brain path>])` is called with the correct path.

---

## Notes

- Path resolution logic should be shared with / reused from issue 001's `BrainRepository` (or its
  underlying path-resolution helper) rather than duplicated.

---

## Log

_Updated as work progresses._

- Added `SettingsSection.brain` enum case (label "Brain"), wired automatically into the sidebar via existing `_SettingsSidebar` iteration.
- Created `BrainSection` widget (`lib/features/settings/presentation/section/brain_section.dart`) with description + "Open brain folder" button calling `ProcessRunner.run('explorer', [resolveBrainFolderPath()])`. Added `createProcessRunner()` factory to `lib/features/settings/di.dart` and wired the new section into `_SettingsContent` in `app_shell_screen.dart`.
- Test `test/features/settings/presentation/section/brain_section_test.dart` covers the tap handler using `resolveBrainFolderPath()` for the expected path. `flutter test test/features/settings/` (120 tests) and `flutter analyze` on changed files both pass.
- QA rejected on 2026-06-13. Bug appended — "Open brain folder" opens the Documents folder instead of the
  brain folder.

---

## Bug

**Reported:** 2026-06-13
**Found during:** Visual QA
**Description:** Tapping "Open brain folder" in Settings > Brain does not open the brain folder
(`%APPDATA%\Codex\brain\<dev|prod>\`) — it opens the Documents folder instead. The resolved path is correct
(verified to exist on disk with `identity.md`/`soul.md`/`memory.md`/`skills\`), so the bug is in how
`Process.run('explorer', [path])` launches Explorer — needs a different invocation (e.g. `runInShell: true`,
or `explorer` via `cmd /c start`) that reliably opens the target folder.

### What to fix
_To be investigated during implementation._

### Acceptance Criteria
- [ ] Bug no longer reproduces
- [ ] Original acceptance criteria still met
- [ ] A test exists that would have caught this

---

## Log

Bug fixed on 2026-06-13. Changed `_openBrainFolder()` in `brain_section.dart` to call
`processRunner.run('explorer.exe', [resolveBrainFolderPath()], runInShell: true)`. Added an optional
`runInShell` parameter (default `false`) to `ProcessRunner.run` and `IoProcessRunner.run`, updated both
`FakeProcessRunner` test doubles accordingly. `flutter test test/features/settings/` (120 tests) and
`flutter analyze` on changed files both pass.
- QA approved by user on 2026-06-13.
