# Agent Mode — Reference

**Scope:** Kanban dock agent mode (`features/agent_run`). This is separate from the Home chat
Agent mode, which is currently disabled pending redesign (see `docs/handoffs/handoff-agent-mode-redesign.md`).

---

## Overview

Agent mode lets you trigger predefined skills against a project's local repository. The backend
executes the skill and streams back a structured event transcript. The Flutter app is purely a
streaming UI — it has no business logic about what the agent does, only how to display it.

---

## Architecture

```
SkillPickerDialog (UI)
  └── AgentRunController.start()
        └── AgentRunRepository
              └── AgentRunDatasource
                    └── POST /webhook/dev-command-center  (streaming)
                          → newline-delimited JSON events
```

### Key files

| File | Role |
|---|---|
| `features/agent_run/domain/model/agent_skill.dart` | Enum of all skills |
| `features/agent_run/domain/model/agent_event.dart` | Sealed event types |
| `features/agent_run/domain/controller/agent_run_controller.dart` | State machine + stream subscription |
| `features/agent_run/presentation/state/agent_run_state.dart` | State data + status enum |
| `features/agent_run/data/datasource/agent_run_datasource.dart` | HTTP POST → event stream |
| `features/agent_run/presentation/dialogs/skill_picker_dialog.dart` | Skill selection dialog |
| `features/agent_run/presentation/screen/agent_run_screen.dart` | Full-screen run view |
| `features/kanban/presentation/widget/agent_pane.dart` | Compact dock pane view |

---

## Skills

Defined in `AgentSkill`:

| ID | Label | Entry point |
|---|---|---|
| `create-issues` | Create issues | `SkillPickerDialog` |
| `work-issue` | Work issue | `SkillPickerDialog` |
| `create-issue-from-bug` | Create issue from bug | Not wired yet — intended for a direct trigger (e.g. from an issue card or detail view) |

`AgentSkill.kPickerSkills` is the curated subset shown in the dialog (currently the first two).
`createIssueFromBug` is defined but has no UI entry point yet.

---

## Event stream

The backend streams newline-delimited JSON. Each line maps to one of four sealed event types:

| Type | Fields | Rendered as |
|---|---|---|
| `AgentThinking` | `text` | `✻ <text>` in dim color |
| `AgentToolUse` | `tool`, `input` | `⏺ <tool> <input>` in accent color |
| `AgentToolResult` | `tool`, `output` | `⎿ <tool> result <output>` in secondary color |
| `AgentResult` | `summary`, `success` | `✓ / ✗ <summary>` in green/red |

`AgentResult` also drives the status transition: `success → done`, `!success → error`.

---

## Status lifecycle

```
idle → running → done
                → error
                → stopped   (via controller.stop())
```

The `AgentRunController` holds the active `StreamSubscription` and exposes:
- `start(skill, repoPath, projectName, context?)` — begins the run
- `stop()` — cancels the subscription, emits `stopped`
- `background()` / `foreground()` — flag for UI layering (doesn't pause the run)

---

## Two views of the same run

Both consume the same `AgentRunController` instance stored on `DockStateData`.

### Full-screen — `AgentRunScreen`

Shown while a run is active (or just completed). Contains:
- **Header:** skill label + project name + elapsed timer + Stop button (while running)
- **Transcript:** scrollable `ListView` of `_EventTile` widgets, auto-scrolls to bottom
- **Footer:** "Run in background" (while running) or "View board" (when finished)

### Dock pane — `AgentPane`

Compact terminal-styled view in the kanban dock. Three states:
1. **No controller** (`agentRunController == null`) — empty state message
2. **Controller exists, no events, not running** — idle prompt line with blinking cursor
3. **Events present or running** — transcript in monospace, same event rendering as full-screen but abbreviated

The pane header shows a pulsing dot + elapsed time only while `status == running`.

---

## Reopen pill (collapsed dock)

When the dock is collapsed, a floating `^` pill appears bottom-right. If an agent run is
`running`, the pill expands to show the skill label + elapsed timer. Otherwise it shows only
the `^` arrow. Tapping it reopens the dock.

---

## Backend contract

**Endpoint:** `POST /webhook/dev-command-center`

**Request body:**
```json
{
  "skill": "<skill-id>",
  "repo": "<absolute-path-to-repo>",
  "context": {}
}
```

**Response:** `Content-Type: application/octet-stream`, streaming newline-delimited JSON.

Each line is one event object. The shape must match one of the four event types above. The
`AgentRunDatasource` decodes `utf8 → LineSplitter → jsonDecode` and passes raw maps to
`AgentRunRepositoryImpl`, which constructs the typed `AgentEvent` objects.

---

## What's complete vs. not wired

| Item | Status |
|---|---|
| Streaming infrastructure (datasource → repository → controller) | Done |
| All four event types, parsing, and rendering | Done |
| `AgentRunScreen` full-screen view | Done |
| `AgentPane` dock view | Done |
| `SkillPickerDialog` with `createIssues` + `workIssue` | Done |
| Reopen pill with live run state | Done |
| `createIssueFromBug` skill trigger | **Not wired** — no UI entry point |
| Stop / background / foreground wiring in the kanban screen | Partially — `stop` is hooked in `AgentRunScreen`, `background`/`foreground` exist but no persistent backgrounding UI |
