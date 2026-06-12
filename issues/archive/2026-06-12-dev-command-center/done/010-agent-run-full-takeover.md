---
id: issue-010
title: "Agent execution: \"Run skill\" full-takeover view"
feature: agent-run
status: done
created_at: 2026-06-11
tags: [afk, p2]
---

# [010] Agent execution: "Run skill" full-takeover view

**Type:** AFK
**Priority:** P2
**Blocked by:** 002, 005, 006

---

## What to build

A full-takeover view that streams a Claude Code skill run (triggered via n8n) live, per `screen-agent.jsx`,
plus the ability to send it to the background and resume it later.

```
sealed class AgentEvent
  AgentThinking(text)
  AgentToolUse(tool, input)
  AgentToolResult(tool, output)
  AgentResult(summary, success)
```

Modules:

- `AgentRunRepository` (abstract): `run({skill, repoPath, context}) -> Stream<AgentEvent>`, POSTing to
  `{N8N_BASE_URL}/webhook/dev-command-center` with `{ skill, repo: repoPath, context }` and parsing the
  streamed NDJSON response.
- `AgentRunController extends StreamState<AgentRunStateData>` (`{ events, status }`, where status is
  `running | done | error | stopped`): `start(...)`, `stop()`.

UI (per `screen-agent.jsx`):

- `AgentRunScreen`: full-takeover overlay with header (skill name, project, elapsed time, Stop button),
  scrolling event list (`EvThinking`, `EvTool` for tool-use/tool-result) with a live "writing…" indicator,
  and a footer with "Run in background" / "View board when done".
- "Run in background": dismisses the overlay while keeping `AgentRunController` alive (registered in
  `DiContainer` for the run's duration); a persistent indicator/pill reopens the overlay.

Trigger points, using a fixed, code-defined skill list (e.g. `create-issues`, `work-issue`):

- Kanban page header "Run skill" → opens a skill picker, then starts the run.
- Issue detail "Run skill" → pre-selects `work-issue` with that issue's id as context.

---

## Acceptance criteria

- [ ] "Run skill" from the kanban header opens the picker, then the full-takeover view streaming events as
      they arrive.
- [ ] "Run skill" from issue detail starts a `work-issue` run pre-populated with that issue's context.
- [ ] Thinking/tool-use/tool-result/result events render per the design as they stream in.
- [ ] "Stop" halts the run and updates status to `stopped`.
- [ ] "Run in background" dismisses the overlay while the run continues; the persistent indicator reopens
      it.
- [ ] "View board when done" returns to the kanban board.

---

## Tests required

Yes — `AgentRunController` unit tests with `FakeAgentRunRepository` emitting a canned `Stream<AgentEvent>`:
state transitions across thinking/tool/result events, stop, and background/foreground toggling.

---

## Notes

- Full end-to-end verification requires an n8n workflow at `N8N_BASE_URL/webhook/dev-command-center` that
  streams the documented event shape; automated tests use the fake stream.
- The skill list is fixed in code for V1 — no dynamic discovery from n8n.

---

## Log

- Wired `AgentRunScreen`/`AgentRunIndicator` into `AppShellScreen` as a `Stack`-based full-takeover overlay
  (covers rail + sidebar + content), with `_activeAgentRun`/`_showAgentRunOverlay` state and handlers for
  start/run-in-background/foreground/view-board (the latter clears the controller and routes back to
  `AppTab.projects` + `ProjectSection.kanban` for the run's project).
- Added a "Run skill" button to the kanban header (`_ProjectsContent`, gated to `ProjectSection.kanban`)
  that opens `SkillPickerDialog` then starts a run, and a "Run skill" button to `IssueDetailSection`'s
  `_DetailHeader` that starts `AgentSkill.workIssue` with `{'issueId': issue.id}` directly (no picker). A
  `RunSkillCallback` typedef threads the callback through `_ContentArea` → `_ProjectsPlaceholder` →
  `_ProjectsContent` → `_ProjectSectionContent`/`_KanbanOrDetail`/`IssueDetailSection`.
- Per "Testing Decisions", no new widget tests were added (UI wiring is human-QA territory). Verified
  `flutter analyze` (0 errors; 6 pre-existing infos/warnings in unrelated `keep_track`/`projects`/`settings`
  files) and `flutter test` (68/68 passing, including all 8 `AgentRunController` tests).
- QA approved by user on 2026-06-12 (full end-to-end verification requires a live n8n
  `webhook/dev-command-center` workflow, deferred per external dependency).
