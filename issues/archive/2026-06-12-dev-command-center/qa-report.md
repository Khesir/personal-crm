# QA Report

_Date: 2026-06-12_

---

## Automated QA Results

| Issue | Title | Build | Tests Pass | Test Quality | Lint | Code Review | Result |
|-------|-------|-------|------------|--------------|------|-------------|--------|
| [001](qa/001-shell-rewrite-and-theme.md) | Shell rewrite: icon rail, contextual sidebar, dark "Codex" theme | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [002](qa/002-settings-services-about.md) | Settings: Services configuration + About | ✅ | ✅ (no new tests required) | ✅ | ✅ | ✅ | Pass |
| [003](qa/003-settings-projects-registry.md) | Settings: Projects registry (CRUD) | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | **Fail** |
| [004](qa/004-projects-tab-and-section-switcher.md) | Projects tab: project list + section pill switcher | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [005](qa/005-kanban-board.md) | Kanban board (read-only, per project, rescan) | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [006](qa/006-issue-detail-edit-move.md) | Issue detail: view, edit, move, acceptance criteria | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [007](qa/007-announcements-per-project.md) | Announcements (project-scoped, generalized from Keep Track) | ✅ | ✅ | ✅ | ✅ | ⚠️ | Pass |
| [008](qa/008-bug-reports-inbox-detail.md) | Bug Reports inbox & detail (resolve/delete) | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [009](qa/009-home-ollama-chat.md) | Home: local Ollama chat | ✅ | ✅ | ✅ | ✅ | ⚠️ | Pass |
| [010](qa/010-agent-run-full-takeover.md) | Agent execution: "Run skill" full-takeover view | ✅ | ✅ | ✅ (no widget tests, by design) | ✅ | ✅ | Pass |
| [011](qa/011-bug-report-to-issue-conversion.md) | Bug Report → Issue conversion (both paths) | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [012](qa/012-cleanup-old-shell-and-dead-code.md) | Cleanup: remove old tabs, screens, and dead color tokens | ✅ | ✅ | ✅ (none required) | ✅ | ✅ | Pass |

**Project-wide checks:** `flutter analyze` → 0 errors, 2 pre-existing `deprecated_member_use` (`activeColor`) infos (unrelated to this batch, in the announcements section and the projects form dialog). `flutter test` → 72/72 pass. `flutter build windows --debug` → succeeds (an initial run failed on the CMake install step, but this was a transient lock/race from running `analyze`/`test`/`build` concurrently — a clean re-run built successfully with no errors).

---

## Issues with automated failures

### 003 — Settings: Projects registry (CRUD)

The core CRUD/slug logic (slug derivation, collision suffixing `-2`/`-3`, edits never re-slugging, persistence round-trip) is correct and well covered by tests. However, two problems surfaced — both already called out by the implementer in the issue's own "Flagged" section, and both confirmed real on review:

1. **The seeded `personal-crm` project's local path is a hardcoded, single-machine absolute path** baked into the source rather than derived at runtime or left as an obvious placeholder. On any other machine or checkout location, the seeded project points at a path that doesn't exist. This is a magic/hardcoded value the project's own conventions call out to avoid.
2. **Deleting the last/only registered project doesn't stick** — the repository re-seeds `personal-crm` automatically whenever the persisted project list is empty, including right after a user deletes it. There's no "seeded once" flag, so the seed project is effectively un-deletable.

A third, smaller open question from the same flagged section: the seeded `personal-crm` defaults to `hasBugReports: true, hasAnnouncements: true`, which isn't specified anywhere — and since the Services backend isn't configured yet, this could cause the Bug Reports/Announcements sections for `personal-crm` to hit an unconfigured backend by default.

**Scope of failures:** these are **two independent problems** (the hardcoded seed path, and the re-seed-on-delete behavior) plus one product-decision question (seed toggle defaults). None block each other — each can be fixed independently. None of them affect the underlying slug/CRUD logic, which is solid.

These need to be fixed before visual review of issue 003.

---

## Visual QA Checklist

## Visual QA — [001] Shell rewrite: icon rail, contextual sidebar, dark "Codex" theme

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Overall color palette and typography on first launch | Whole app window | Dark background throughout (deep near-black frame, slightly lighter sidebar/content, raised cards for panels), a single purple-ish accent color used for highlights/active states, UI text in a clean sans-serif (IBM Plex Sans) and any code/monospace fields in JetBrains Mono |
| 2 | Left icon rail | Far-left vertical strip | Home and Projects icons stacked near the top, Settings icon pinned to the bottom of the rail; the currently active icon has an accent-colored highlight and a left-edge accent bar |
| 3 | Switching top-level tabs | Click Home, then Projects, then Settings in the rail | Each click switches the active rail icon's highlight, and both the sidebar and main content area change to match the selected tab |
| 4 | Sidebar contents per tab | Sidebar (left panel next to the rail) | Home → conversation list + "New chat" button; Projects → list of registered projects; Settings → static list "Projects / Services / About" |
| 5 | No old-shell visuals | Whole app | No horizontal tab bar at the top, no leftover Portfolio/Time Tracker/Ari Connect/Minecraft tabs or screens anywhere |

**Edge cases to manually test:**
- [ ] Resize the window close to the minimum size (960×600) and confirm the rail/sidebar/content layout doesn't break
- [ ] Switch tabs rapidly several times and confirm the sidebar/content always matches the currently-highlighted rail icon

---

## Visual QA — [002] Settings: Services configuration + About

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Services form fields | Settings → Services | Text fields for N8N base URL, Ollama base URL, the shared backend URL (DEVCENTER_BACKEND_URL), the CRM secret, and an optional Claude API key |
| 2 | Saving a service value persists | Settings → Services: change a value, save, fully restart the app | The edited value is still shown after restart (confirms it was written and reloaded into the app's config) |
| 3 | About section | Settings → About | Shows the app name "Codex" and a version number |
| 4 | No Appearance/theme section | Settings sidebar and content | No "Appearance" entry or light/dark/system theme toggle anywhere in Settings |

**Edge cases to manually test:**
- [ ] Save a service field, then check whether features that depend on it (e.g. Ollama chat model list, or Announcements/Bug Reports for a project) pick up the new value without code changes
- [ ] Leave the optional Claude API key blank and confirm saving doesn't error

---

## Visual QA — [004] Projects tab: project list + section pill switcher

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Project list in sidebar | Projects tab → sidebar | Every project registered in Settings → Projects appears in the sidebar list |
| 2 | Selecting a project | Click a project in the sidebar | Page header in the content area updates to show that project's name, and a pill/segmented switcher appears below/beside the title |
| 3 | Pill visibility per project | Page header pill switcher, for projects with different toggle combinations | "Kanban" pill always present; "Bug Reports" pill only shown if that project has "Has Bug Reports" enabled; "Announcements" pill only shown if "Has Announcements" enabled |
| 4 | Switching projects resets section | Select project A, switch to a non-Kanban pill, then select project B | Project B's view starts on the Kanban pill, not whichever pill was active for project A |
| 5 | Switching pills | Click between the available pills for one project | The pill switcher's active-state styling updates, and the content area below changes to match the selected section |

**Edge cases to manually test:**
- [ ] Select a project with both Bug Reports and Announcements disabled — only the Kanban pill should appear, with no empty space where the other pills would be
- [ ] With only one project registered, confirm the sidebar still renders correctly (no "empty list" layout glitch)

---

## Visual QA — [005] Kanban board (read-only, per project, rescan)

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Five-column board | Projects → select `personal-crm` → Kanban pill | Five columns: Backlog, Ready, In Progress, QA, Done, populated from this repo's `issues/` folder |
| 2 | Issue card contents | Any issue card on the board | Shows the issue's title, a feature tag (with an icon and the accent-2 color), other tags, the issue id, and a date |
| 3 | Empty column state | A status column with no issue files (if any) | Shows a "No issues" empty state, not a blank space or an error |
| 4 | Rescan | Click "Rescan" in the page header | Board reloads from disk; if you add/move a markdown file in `issues/` on disk and click Rescan, the board reflects the change without restarting the app |

**Edge cases to manually test:**
- [ ] Temporarily rename one of `issues/qa`'s files to remove its `---` frontmatter block, Rescan, and confirm it just disappears from the board (no crash/error)
- [ ] Confirm the QA column shows this batch's issues (001-012) currently sitting in `issues/qa/`

---

## Visual QA — [006] Issue detail: view, edit, move, acceptance criteria

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Open detail view | Kanban board → click any issue card | Opens a detail view showing the rendered markdown body, an "Acceptance criteria" checklist (if the issue has one), a metadata panel (feature, status, tags, created date, file path, raw frontmatter preview), and the move/edit actions |
| 2 | Toggle acceptance criteria | In the detail view, click a checkbox in the Acceptance criteria list | The checkbox flips immediately; close and reopen the issue (or Rescan) and the checkbox state is unchanged — confirming it was written to the file |
| 3 | Move an issue | In the detail view, use the status picker dropdown to pick a different status, e.g. move a Backlog issue to Ready | Detail view's status updates; going back to the board, the issue now appears in the new column and no longer in the old one |
| 4 | Edit an issue | Click "Edit", change the title and/or tags, save | Detail view immediately reflects the new title/tags; the board's card for that issue also reflects the change |

**Edge cases to manually test:**
- [ ] Pick this very QA issue file (e.g. one of 001-012 in `issues/qa/`) and verify its acceptance-criteria checkboxes render and toggle correctly without corrupting the rest of the file
- [ ] Use "Move" on a test issue and confirm the file actually moved to the new status folder on disk (not just updated in-memory)
- [ ] Edit an issue's tags to include a value with special characters (e.g. a colon) and confirm the file's frontmatter remains valid YAML afterward

---

## Visual QA — [007] Announcements (project-scoped, generalized from Keep Track)

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Announcements pill visible | Select a project with "Has Announcements" enabled | "Announcements" pill appears in the page header pill switcher |
| 2 | Announcements list/create/edit UI | Announcements pill content | Shows existing create/edit dialogs (markdown write/preview tabs), a card list with type and draft/published badges — same UI shape as the old Keep Track announcements feature |
| 3 | Accent color | Throughout the Announcements UI | Uses the app's single purple accent color, not a distinct "Keep Track" color |
| 4 | Project without announcements | Select a project with "Has Announcements" disabled | No "Announcements" pill appears |

**Edge cases to manually test:**
- [ ] Create/edit/publish-toggle/delete an announcement for a project (requires `DEVCENTER_BACKEND_URL`/`CRM_SECRET` configured in Settings → Services and the shared backend reachable) — confirm each action updates the list and doesn't error
- [ ] If the backend isn't reachable, confirm the Announcements section shows a reasonable loading/error state rather than a crash

---

## Visual QA — [008] Bug Reports inbox & detail (resolve/delete)

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Bug Reports pill visible | Select a project with "Has Bug Reports" enabled | "Bug Reports" pill appears in the page header pill switcher |
| 2 | Inbox with severity filter | Bug Reports pill content | A list of reports with severity filter pills (info/warning/error/critical) that filter the visible list when clicked |
| 3 | Report detail | Click a report in the inbox | Shows the full message, stack trace, source, and timestamp |
| 4 | Resolve/delete | In the detail view, click Resolve and/or Delete (requires backend configured) | The report's resolved state updates, or it's removed from the list, after the action |
| 5 | Project without bug reports | Select a project with "Has Bug Reports" disabled | No "Bug Reports" pill appears |

**Edge cases to manually test:**
- [ ] Filter by a severity that has zero matching reports and confirm the list shows an appropriate empty state
- [ ] Resolve a report, then re-filter/reload and confirm its resolved state is reflected

---

## Visual QA — [009] Home: local Ollama chat

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Empty state | Home tab, no conversations yet | Shows a "Local assistant" intro, a row of suggested prompt chips, and the message composer at the bottom |
| 2 | Sending a message | Type a message and send (requires Ollama running at the configured `OLLAMA_BASE_URL`) | A user message bubble appears, followed by an assistant message that streams in token-by-token with a "generating…" indicator while it's incomplete |
| 3 | Markdown/code rendering | Ask the assistant something that returns a code block | The response renders markdown formatting and fenced code blocks in a distinct code-block style |
| 4 | Model switcher | Page header | Lists models available from the configured Ollama instance; selecting a different model is used for the next message |
| 5 | Conversation sidebar | Home tab sidebar | New conversations appear with relative timestamps (e.g. "2m", "1h", "Yesterday"); "New chat" starts a fresh empty conversation |
| 6 | Persistence | Send a message, fully restart the app | The conversation and its messages are still present in the sidebar/history after restart |

**Edge cases to manually test:**
- [ ] With no Ollama instance running, confirm sending a message fails gracefully (no crash) and the model switcher shows a reasonable empty/error state
- [ ] Click a suggested prompt chip in the empty state and confirm it starts a conversation with that prompt

---

## Visual QA — [010] Agent execution: "Run skill" full-takeover view

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Run skill from kanban | Kanban page header → "Run skill" button | Opens a skill picker dialog; choosing a skill starts a run and opens a full-takeover overlay covering the rail/sidebar/content |
| 2 | Run skill from issue detail | Issue detail view → "Run skill" button | Starts a `work-issue` run pre-populated with that issue's id (no picker shown), opening the same full-takeover overlay |
| 3 | Event stream rendering | Full-takeover overlay, while a run is active (requires `N8N_BASE_URL` reachable) | Thinking, tool-use, and tool-result events appear in the scrolling list as they arrive, with a live "writing…" indicator while the agent is working |
| 4 | Stop | Overlay header → "Stop" button | Run halts; status changes to "stopped" and the event stream stops updating |
| 5 | Run in background | Overlay footer → "Run in background" | Overlay closes but a persistent indicator/pill remains visible (e.g. near the rail) while the run continues |
| 6 | Reopen from background | Click the persistent indicator/pill | Reopens the full-takeover overlay showing the run's current state/events |
| 7 | View board when done | Let a run finish (or stop it), then click "View board when done" | Returns to the Kanban board for that run's project |

**Edge cases to manually test:**
- [ ] Start a run, send it to background, switch to a different tab/project, then reopen it via the indicator — confirm events captured while in the background are all shown
- [ ] Start a run with `N8N_BASE_URL` unreachable and confirm the overlay shows an error status rather than hanging indefinitely

---

## Visual QA — [011] Bug Report → Issue conversion (both paths)

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Convert to issue modal | Bug report detail view → "Convert to issue" | Opens a modal offering two options: "Write .md directly" and "Generate with Claude Code" |
| 2 | Write .md directly | Choose "Write .md directly" for a test bug report | A confirmation appears; switching to the project's Kanban board shows a new card in Backlog whose title is derived from the bug report's first line, with tags including the severity |
| 3 | Generate with Claude Code | Choose "Generate with Claude Code" for a test bug report | Opens the issue-010 full-takeover overlay, running the `create-issue-from-bug` skill with the bug's details as context |

**Edge cases to manually test:**
- [ ] Convert a bug report whose message has no stack trace and confirm the generated issue's body still reads sensibly without a stack trace section
- [ ] After "Write .md directly", confirm the new file actually exists under that project's `issues/backlog/` folder on disk

---

## Visual QA — [012] Cleanup: remove old tabs, screens, and dead color tokens

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Full app walkthrough | Home, Projects (all sections for at least one project with both toggles on), and Settings (Projects/Services/About) | Every screen matches the dark "Codex" design with the single accent + status/severity colors — no leftover old-shell colors, layouts, or labels from Portfolio/Keep Track/Time Tracker/Ari Connect/Minecraft |
| 2 | No orphaned navigation | Anywhere in the app | No way to reach a screen that references the old 5-tab structure or any of the removed features |

**Edge cases to manually test:**
- [ ] Open every per-project section pill (Kanban, Bug Reports, Announcements) at least once during the walkthrough to confirm none of them render leftover old-shell styling

---

## How to sign off

For each issue you visually verify:
- Approved → run `/qa-approve [issue number]`
- Something is wrong → run `/qa-reject [issue number] [what you saw]`

Issue 003 failed automated QA and is not included above — it needs the two flagged problems (hardcoded seed path, re-seed-on-delete) addressed before a visual pass.
