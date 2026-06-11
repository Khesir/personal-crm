# Dev Workflow Command Center — App Specification

## Overview

A Flutter desktop/mobile app that serves as a personal dev ops command center. It centralizes project management, issue tracking, bug report triage, agent skill execution, and a local LLM chat interface — all in one place.

---

## Core Concepts

### What the app is

- A **kanban board** for every git repository you work on
- A **bug report inbox** that reads directly from each project's backend API
- An **agent execution panel** that triggers Claude Code skills via n8n
- A **local LLM chat** (Home tab) — a personal ChatGPT-style UI running on local models via Ollama

### What the app is not

- It does not host or run a backend
- It does not replace Claude Code — it triggers it
- It does not push to git or manage branches

---

## Architecture

### Three service layers

```
Flutter App
    │
    ├── Filesystem (direct read)
    │     └── ~/projects/<repo>/issues/   ← reads .md files, file watcher
    │
    ├── Project backends (HTTP GET)
    │     └── GET <project.bugReportEndpoint>/bug-reports
    │
    ├── n8n (HTTP POST)
    │     └── POST <n8nUrl>/webhook/run-skill
    │           └── n8n runs: claude <skill> --repo <path>  (subprocess)
    │
    └── Ollama (HTTP POST, direct)
          └── POST http://localhost:11434/api/chat  (streaming)
```

### n8n role

n8n is the automation layer between the app and Claude Code. The app never runs subprocesses directly. Instead:

1. App POSTs a skill command to n8n webhook
2. n8n executes `claude` CLI as a subprocess
3. n8n streams stdout back to the app via SSE or sends final result
4. Claude Code writes `.md` issue files to the repo filesystem
5. App's file watcher detects the new files and updates the kanban board

n8n can optionally be used to aggregate bug reports across multiple project backends or set up alerting rules, but the basic bug report flow works without it.

---

## Issue Folder Contract

Every project repository optionally contains an `issues/` folder. This is the single source of truth for the kanban board.

### Folder structure

```
~/projects/my-repo/
├── src/
├── README.md
└── issues/
    ├── backlog/
    │   ├── issue-001.md
    │   └── issue-002.md
    ├── ready/
    │   └── issue-003.md
    ├── inprogress/
    │   └── issue-004.md
    ├── qa/
    │   └── issue-005.md
    └── done/
        └── issue-006.md
```

### Folder = kanban column

| Folder | Status | Color |
|---|---|---|
| `backlog/` | Backlog | Gray |
| `ready/` | Ready | Blue |
| `inprogress/` | In Progress | Amber |
| `qa/` | QA | Coral/Orange |
| `done/` | Done | Teal/Green |

### Issue `.md` file format

Each file uses YAML frontmatter + markdown body:

```markdown
---
id: issue-004
title: Add OAuth login
feature: user-auth
status: inprogress
created_at: 2026-06-10
tags: [auth, backend]
---

## Description
Full markdown body — acceptance criteria, notes, subtasks, context.

## Acceptance criteria
- [ ] User can log in with Google
- [ ] Token stored securely
```

**Rules:**
- The **folder** is the authoritative status. The `status` frontmatter field is a convenience duplicate.
- Both must stay in sync. Claude Code's skill is responsible for writing both correctly.
- `id` is unique across the whole repo.
- `feature` groups issues by the feature being implemented.

### Who creates the issues/ folder

1. **Primary:** Claude Code skill — detects missing folder and scaffolds it as part of a skill run
2. **Fallback:** Flutter app — "Initialize issues folder" button in the project settings, creates empty subdirectories only, no `.md` files

---

## Data Models

### Project

```dart
class Project {
  final String id;
  final String name;
  final String localPath;          // e.g. /Users/you/projects/my-repo
  final String bugReportEndpoint;  // e.g. https://myapi.local/bug-reports
  final String? n8nWebhookUrl;     // optional override per project
}
```

### Issue

```dart
enum IssueStatus { backlog, ready, inprogress, qa, done }

class Issue {
  final String id;
  final String title;
  final String feature;
  final IssueStatus status;   // derived from folder name
  final DateTime createdAt;
  final List<String> tags;
  final String body;          // raw markdown
  final String filePath;      // absolute path on disk
}
```

### BugReport

```dart
enum BugSeverity { info, warning, error, critical }

class BugReport {
  final String id;
  final String project;       // maps to Project.name
  final BugSeverity severity;
  final String message;
  final String? stack;
  final DateTime timestamp;
  final String source;        // which service sent it
  final bool resolved;
}
```

### ChatMessage

```dart
enum ChatRole { user, assistant, system }

class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final String? model;        // which Ollama model responded
  final DateTime timestamp;
}
```

### Bug report API response shape

Each project backend must expose `GET /bug-reports` returning:

```json
[
  {
    "id": "br-001",
    "project": "my-repo",
    "severity": "error",
    "message": "NullPointerException in AuthService",
    "stack": "...",
    "timestamp": "2026-06-11T10:00:00Z",
    "source": "api-backend",
    "resolved": false
  }
]
```

---

## Flutter App Structure

### Navigation — 4 top-level tabs

| Tab | Icon | Description |
|---|---|---|
| Home | chat | Local LLM chat UI (Ollama) |
| Projects | layout-kanban | Repo list + kanban board per project |
| Bug Reports | bug | Inbox of bug reports per project |
| Settings | settings | Repos, endpoints, API keys |

### Folder structure

```
lib/
  main.dart
  app.dart                        # MaterialApp, routing, theme

  models/
    project.dart
    issue.dart
    bug_report.dart
    chat_message.dart

  services/
    issue_service.dart            # filesystem read/write/watch/scaffold
    bug_report_service.dart       # GET from project backend endpoint
    agent_service.dart            # POST to n8n, parse SSE stream
    ollama_service.dart           # POST to localhost:11434, token stream

  providers/                      # Riverpod
    projects_provider.dart
    issues_provider.dart
    bug_reports_provider.dart
    chat_provider.dart
    settings_provider.dart

  screens/
    home/
      home_screen.dart            # chat UI shell
      chat_bubble.dart            # user + assistant message bubbles
      model_switcher.dart         # dropdown to pick Ollama model

    projects/
      projects_screen.dart        # list of repos, tab per project
      kanban_board.dart           # 5-column board
      issue_card.dart             # kanban card widget
      issue_detail.dart           # full issue view with markdown body
      agent_panel.dart            # live skill execution stream viewer

    bug_reports/
      bug_reports_screen.dart     # inbox list
      bug_report_card.dart        # severity badge, message preview
      bug_report_detail.dart      # full report + action buttons

    settings/
      settings_screen.dart
      project_form.dart           # add/edit project (name, path, endpoint)

  widgets/
    markdown_viewer.dart          # renders .md body (flutter_markdown)
    agent_stream_event.dart       # single event row in agent panel
    severity_badge.dart           # color-coded severity pill
```

### Recommended packages

```yaml
dependencies:
  flutter_riverpod: ^2.x
  flutter_markdown: ^0.x
  watcher: ^1.x          # filesystem watch for issues/ folder
  yaml: ^3.x             # parse frontmatter
  http: ^1.x             # HTTP calls + streaming
  path: ^1.x             # filesystem path utilities
  shared_preferences: ^2.x  # persist project list + settings
  uuid: ^4.x             # generate issue IDs
```

---

## Screen Descriptions

### Home — Local LLM chat

- Chat bubble UI, identical feel to Claude/ChatGPT
- Model switcher dropdown (lists available Ollama models via `GET /api/tags`)
- Streams tokens in real time via `http` streaming response
- Conversation history kept in-memory per session
- No connection to project/issue data — standalone assistant
- Supported models: any model pulled in Ollama (Llama 3, Qwen, DeepSeek, Mistral, etc.)

### Projects — Kanban board

- Top: tab bar, one tab per registered project/repo
- Main area: 5-column kanban board (backlog → done)
- Each column reads from the corresponding `issues/<folder>/` directory
- Issue cards show: title, feature tag, severity/tag badges, created date
- Tap card → issue detail sheet with full markdown body rendered
- File watcher (`watcher` package) refreshes board automatically when Claude Code writes new `.md` files
- "Run skill" button → opens agent panel, POSTs to n8n, shows live stream
- "Initialize issues folder" button shown when `issues/` folder not found

### Agent panel (within Projects tab)

- Slide-up panel or side drawer while skill is running
- Shows Claude Code's stdout stream as structured events:
  - `thinking` — muted italic text, reasoning before acting
  - `tool_use` — monospace block showing tool name + input (bash, write_file, read_file)
  - `tool_result` — indented output of each tool call
  - `result` — final summary + done/error badge
- Stream delivered via SSE from n8n
- Panel stays open after completion so you can review what was done

### Bug Reports — Inbox

- Tab bar mirrors Projects (one per project)
- Polls `GET <bugReportEndpoint>` on tab open + manual refresh button
- Each bug report card shows: severity badge, message preview, timestamp, source service
- Tap → detail view with full stack trace
- Actions on each report:
  - **Dismiss** — mark resolved (POSTs back to backend if endpoint supports it)
  - **Convert to issue** → pre-fills issue draft, user edits, triggers Claude Code skill or saves `.md` directly
  - **Ask LLM** → sends report to Ollama/Claude for summary or diagnosis

### Settings

- Project list: add/edit/remove projects (name, local path, bug report endpoint)
- n8n base URL (global)
- Ollama base URL (default `http://localhost:11434`)
- Claude API key (for future direct Claude API use in assistant panel)
- Theme: light / dark / system

---

## Agent Execution Flow

```
User taps "Run skill" in Projects tab
  │
  ▼
App POSTs to n8n webhook:
{
  "skill": "create-issues",
  "repo": "/Users/you/projects/my-repo",
  "feature": "user-auth",
  "context": { ... }
}
  │
  ▼
n8n executes subprocess:
  claude --skill create-issues --repo /path --output-format stream-json
  │
  ▼
n8n reads stdout line by line (JSON events)
  │
  ▼
n8n forwards each event via SSE to app
  │
  ▼
App agent panel renders each event as it arrives
  │
  ▼
Claude Code writes .md files to issues/backlog/
  │
  ▼
App file watcher detects changes → refreshes kanban board
```

---

## Local LLM Chat Flow

```
User types message in Home tab
  │
  ▼
App POSTs to Ollama:
POST http://localhost:11434/api/chat
{
  "model": "llama3.2",
  "messages": [ ...conversationHistory ],
  "stream": true
}
  │
  ▼
Flutter reads chunked HTTP response with StreamBuilder
  │
  ▼
Each chunk appended to last assistant bubble in real time
  │
  ▼
On stream end, message finalized in conversation history
```

---

## Bug Report → Issue Conversion Flow

```
User opens bug report detail
  │
  ▼
Taps "Convert to issue"
  │
  ▼
App pre-fills issue draft form:
  - title: derived from bug message
  - feature: user selects
  - status: backlog (default)
  - body: formatted bug report + stack trace
  │
  ▼
User reviews and confirms
  │
  ▼
Option A: App writes .md directly to issues/backlog/<id>.md
Option B: App triggers Claude Code skill via n8n to generate
          a properly structured issue with more context
```

---

## Key Implementation Notes

1. **Status is derived from folder path**, not just frontmatter. Parse `filePath.split('/').reversed.skip(1).first` to get the column.

2. **File watcher refreshes are debounced** — Claude Code may write multiple files quickly. Debounce the watcher callback by ~500ms before re-scanning.

3. **Ollama model list** is fetched dynamically via `GET http://localhost:11434/api/tags` — don't hardcode model names.

4. **n8n SSE connection** should have a timeout and error state. Show "agent not reachable" if n8n is not running.

5. **Bug report polling** is on-demand (tab open + manual refresh), not background polling. No need for a background isolate.

6. **Issue IDs** are generated as `issue-<timestamp>` or `issue-<uuid-short>` by the app when converting bug reports directly. Claude Code generates its own IDs when running skills.

7. **Settings are persisted** via `shared_preferences`. Project list, endpoints, and URLs survive app restarts.

8. **The app is local-first** — it works fully offline for the kanban board. Only bug report fetching and n8n skill execution require network/local services to be running.

---

## What to Build First (suggested order)

1. App shell — 4-tab navigation, theme, routing
2. Models — `Project`, `Issue`, `BugReport`, `ChatMessage`
3. Settings screen — add/edit projects with local path + endpoint
4. `IssueService` — filesystem read, folder scaffold, file watcher
5. Projects screen — kanban board rendering from local filesystem
6. `OllamaService` + Home screen — streaming chat UI
7. `BugReportService` + Bug reports screen — GET + display
8. `AgentService` + n8n integration — skill trigger + SSE stream
9. Agent panel — live event stream viewer
10. Bug report → issue conversion flow
