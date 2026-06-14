---
id: issue-001
title: "Brain repository: seed, read & assemble system prompt"
feature: brain
status: done
created_at: 2026-06-13
tags: [afk, p1]
---

# [001] Brain repository: seed, read & assemble system prompt

**Type:** AFK
**Priority:** P1
**Blocked by:** None
**User stories covered:** 1, 2, 3, 4, 5, 6, 7, 10, 11, 13

---

## What to build

A new `lib/features/brain/` feature module (standard layout: `domain/repository/`, `data/repository/`,
`api.dart`, `di.dart`) providing a `BrainRepository` with a single method:

```dart
Future<String?> buildSystemPrompt();
```

**Path resolution:** the brain folder lives at `%APPDATA%/Codex/brain/<dev|prod>/`, resolved via
`Platform.environment['APPDATA']` joined with `kDataNamespace` (`lib/core/config/data_namespace.dart`). No
new dependency (`path_provider` is not used in this app). `BrainRepositoryImpl` is constructed with the
brain folder as a `Directory`, so tests can point it at a temp directory.

**First-run seeding:** if the brain folder doesn't exist when `buildSystemPrompt()` is first called, create
it and seed:
- `identity.md` — Avyn's identity (seed content is in `issues/prd.md` under "Seed content for
  `identity.md`" — copy verbatim).
- `soul.md` — Avyn's personality (seed content is in `issues/prd.md` under "Seed content for `soul.md`" —
  copy verbatim).
- `memory.md` — empty file (or a single `# Memory` heading).
- `skills/` — empty subfolder.

If the folder already exists but individual files are missing (user deleted them), do **not** re-seed —
just treat them as absent in assembly.

**Assembly (`buildSystemPrompt()`):**
- Read `identity.md`, `soul.md`, `memory.md` fresh on every call (no caching).
- For each file: if missing or its trimmed content is empty, omit it from the prompt entirely.
- Join non-empty sections in order (identity → soul → memory) with separator `\n\n---\n\n`.
- If `skills/` exists and contains files, append a short note listing them after the memory section (same
  separator). If `skills/` is empty or absent, omit this note.
- If everything is empty/missing, return `null`.

---

## Acceptance criteria

- [ ] `BrainRepository` interface + `BrainRepositoryImpl` exist in `lib/features/brain/`, with `api.dart`
  and `di.dart` following the standard module pattern.
- [ ] On first use with no existing brain folder: folder is created, `identity.md`/`soul.md` contain the
  seed content from `issues/prd.md` verbatim, `memory.md` is empty, `skills/` exists and is empty.
- [ ] `buildSystemPrompt()` returns the three sections joined with `\n\n---\n\n`, in identity → soul →
  memory order, omitting any missing/empty file.
- [ ] `buildSystemPrompt()` returns `null` when `identity.md`, `soul.md`, and `memory.md` are all
  missing/empty and `skills/` is empty/absent.
- [ ] A non-empty `skills/` folder adds a short note to the assembled prompt; an empty/absent `skills/`
  folder does not.
- [ ] If the brain folder exists but some files are missing, those files are omitted (not re-seeded).

---

## Tests required

Yes — `BrainRepositoryImpl` tests using `Directory.systemTemp.createTempSync()` (same pattern as
`test/features/kanban/data/repository/issues_repository_impl_test.dart`), writing
`identity.md`/`soul.md`/`memory.md`/`skills/*` directly into the temp dir and asserting on
`buildSystemPrompt()`'s output. Cover: all three present/non-empty; one or more missing; one or more empty;
`skills/` with files vs. empty/absent; brain folder entirely absent (seeding triggers and seed content
matches PRD verbatim).

---

## Notes

- Seed content for `identity.md`/`soul.md` is in `issues/prd.md` — copy verbatim, do not paraphrase.
- Storing brain files as app-local markdown (not `shared_preferences`) is a deliberate decision — see
  `docs/adr/0003-brain-files-as-app-local-markdown.md`.
- Glossary: "Brain", "Brain folder", "Identity", "Soul", "Memory" are defined in `CONTEXT.md`.

---

## Log

_Updated as work progresses._

- Implemented `BrainRepository`/`BrainRepositoryImpl` in `lib/features/brain/` with `api.dart` and `di.dart`
  (incl. `resolveBrainFolderPath()` for `%APPDATA%/Codex/brain/<dev|prod>/`). Seed content for
  `identity.md`/`soul.md` lives in `lib/features/brain/data/datasource/brain_seed_content.dart`, copied
  verbatim from `issues/prd.md`.
- 9 tests added in `test/features/brain/data/repository/brain_repository_impl_test.dart` covering seeding,
  join order, missing/empty files, skills note presence/absence, and the all-empty `null` case. All pass;
  `flutter analyze` clean on the new files.
- QA rejected on 2026-06-13. Bug appended — Home chat explains/describes Avyn in the third person instead
  of speaking as Avyn.

---

## Bug

**Reported:** 2026-06-13
**Found during:** Visual QA
**Description:** The assembled system prompt (identity.md + soul.md content) is written entirely in third
person ("Avyn is...", "She believes..."), so the LLM explains/describes Avyn rather than speaking as Avyn
in Home chat. `buildSystemPrompt()` needs to wrap the assembled identity/soul/memory content with a framing
instruction (e.g. "You are Avyn. Embody this identity and personality fully — respond in first person, in
character, do not describe Avyn in the third person.") without modifying the verbatim seed files themselves.

### What to fix
_To be investigated during implementation._

### Acceptance Criteria
- [ ] Bug no longer reproduces
- [ ] Original acceptance criteria still met
- [ ] A test exists that would have caught this

---

## Log (cont.)

Bug fixed on 2026-06-13. `buildSystemPrompt()` now prefixes the assembled
identity/soul/memory/skills sections with a framing instruction ("You are
Avyn. Embody this identity and personality fully. Respond in first person, in
character, as Avyn — do not describe Avyn in the third person.") so the LLM
speaks as Avyn instead of describing her. The framing constant lives in
`brain_repository_impl.dart` only; `brain_seed_content.dart` is untouched, and
the all-empty case still returns `null`. Added 2 new tests plus updated the 9
existing tests to check `contains(...)` instead of exact equality; all 11
brain tests and 32 home tests pass, `flutter analyze` clean.
- QA approved by user on 2026-06-13.
