# QA Report

_Date: 2026-06-13_

---

## Automated QA Results

| Issue | Title | Build | Tests Pass | Test Quality | Lint | Code Review | Result |
|-------|-------|-------|------------|--------------|------|-------------|--------|
| [001](qa/001-brain-repository-seed-read-assemble.md) | Brain repository: seed, read & assemble system prompt | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [002](qa/002-inject-brain-into-chat-system-prompt.md) | Inject brain into Home chat's system prompt | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [003](qa/003-settings-open-brain-folder.md) | Settings: "Brain" section with Open brain folder button | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |

- **Build**: `flutter analyze` is clean on every file touched by these three issues (the only 2 analyzer findings in the whole project are pre-existing `activeColor` deprecation notices in unrelated files, untouched by this work).
- **Tests**: full suite — 226 tests, all passing (9 new for the brain repository, 3 new for the chat injection, 1 new for the Settings section).
- **Test quality**: all new tests exercise public interfaces only (`buildSystemPrompt()`, `sendMessage()` + captured `streamChat` args, a widget tap → fake `ProcessRunner.run`), describe behavior (e.g. "skills folder with files adds a note after memory section", "the prepended brain system message never appears in conversation.messages or persisted data"), and would survive an internal refactor.
- **Code review**: implementation is minimal and follows existing module/DI/section conventions closely (mirrors `kanban`'s repository pattern, `home/di.dart`'s controller wiring, and `projects_section.dart`/`about_section.dart`'s visual structure). No scope creep — diffs are confined to the brain module plus the exact wiring points each issue specified.

---

## Issues with automated failures

None. All three issues pass automated QA.

One minor, non-blocking style note (does not affect functionality, tests, or acceptance criteria):

- `BrainRepository.buildSystemPrompt()` has a multi-line doc comment explaining its seeding/assembly/null behavior. This project's stated convention is no added docstrings/dartdoc unless requested. Since the comment is accurate and the method's contract is non-obvious from its name alone, this is a judgment call worth a quick look — flagging for awareness rather than as a failure.

---

## Visual QA Checklist

## Visual QA — 003 Settings: "Brain" section with Open brain folder button

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | The "Brain" entry appears in the Settings sidebar | Settings tab → left sidebar, between "Services" and "About" | A "Brain" item is listed and selectable like the other Settings sections |
| 2 | Selecting "Brain" shows the new section | Settings tab → click "Brain" in the sidebar | Page title "Brain", a short description of the brain folder (identity/soul/memory/skills markdown files that shape Home chat's personality), and an "Open brain folder" button below it |
| 3 | Tapping "Open brain folder" opens the folder | Settings → Brain → click "Open brain folder" | Windows Explorer opens to `%APPDATA%\Codex\brain\dev\` (dev build) or `...\brain\prod\` (prod build), showing `identity.md`, `soul.md`, `memory.md`, and an empty `skills\` folder (created on first Home chat message if this is the first run) |
| 4 | Visual styling matches other Settings sections | Settings → Brain vs. Settings → Projects/About | Same page padding, title/sub text styles, and button styling (accent-colored button, consistent spacing) — no hardcoded colors/sizes that look out of place |

**Edge cases to manually test:**
- [ ] Brain folder doesn't exist yet (first run, before any Home chat message sent) — clicking "Open brain folder" should still open Explorer at the target path (Explorer will show "this folder doesn't exist yet" or create-on-demand behavior is acceptable; the important thing is the path matches `%APPDATA%\Codex\brain\<dev|prod>\`)
- [ ] After sending a Home chat message (which triggers brain seeding), reopen the Brain folder — `identity.md` and `soul.md` should contain Avyn's identity/personality text, `memory.md` should be empty, `skills\` should exist and be empty

---

## How to sign off

For each issue you visually verify:
- Approved → run `/qa-approve [issue number]`
- Something is wrong → run `/qa-reject [issue number] [what you saw]`
