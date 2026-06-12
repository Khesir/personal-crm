# PRD: Dev Command Center

**Status:** Draft
**Date:** 2026-06-11

---

## Problem Statement

Today the app ("Codex") is five unrelated mini-apps stitched together behind one shell: Portfolio, Keep Track, Time Tracker, Ari Connect, and Minecraft each have their own bespoke tabs, sidebars, and screens with no shared structure. Every time the developer wants to track work, file a bug, or post an announcement for one of these projects, the experience is different — and most of these apps have no kanban, no bug inbox, and no announcements at all.

Separately, the developer wants a single local hub for day-to-day dev work: a place to chat with a local LLM, see and triage bugs reported from their apps, manage a kanban-style backlog backed by plain markdown files in each repo, and kick off Claude Code skill runs against a project without leaving the app.

## Solution

Replace the five-tab shell with a single "Dev Command Center": a left icon rail (Home / Projects / Settings) plus a contextual sidebar, following the dark "Codex" design system from the `Dev Command Center.html` mockup.

- **Home** is a local-LLM chat (Ollama-backed), with conversation history, model switching, and streaming responses.
- **Projects** is a registry of repos (Portfolio, Keep Track, Time Tracker, Ari Connect, Minecraft, and `personal-crm` itself). Selecting a project shows its kanban board (from `issues/<status>/*.md` files in its local path) by default, with optional Bug Reports and Announcements sections toggleable per project, switched via a pill control in the page header.
- **Settings** manages the project registry and the service endpoints (n8n, Ollama, the shared backend, optional Claude API key).
- A "Run skill" action (from the kanban board, an issue, or a bug report) opens a full-takeover view streaming a Claude Code skill run via n8n.

Bug Reports and Announcements are served by the existing Keep Track backend, reworked to be project-scoped (`/api/v1/projects/{projectKey}/...`) instead of single-tenant.

This is a hard pivot: the old tabs, sidebars, and screens are deleted, not kept alongside the new ones.

---

## User Stories

### Shell & navigation

1. As a developer, I want a left icon rail with Home, Projects, and Settings, so I can quickly switch between the app's three top-level areas.
2. As a developer, I want the rail, sidebar, and content area to use the dark "Codex" design tokens (single accent color, status/severity colors), so the whole app feels like one cohesive tool instead of five disconnected mini-apps.
3. As a developer, when I open Projects, I want a sidebar listing all my registered projects, so I can pick which one I'm working on.
4. As a developer, when I select a project, I want a pill/segmented switcher in the page header showing only the sections enabled for that project (Kanban always, plus Bug Reports and/or Announcements if turned on).
5. As a developer, when I switch projects, I want the view to reset to that project's Kanban board by default.

### Projects registry

6. As a developer, I want to add a project with a name and a local filesystem path, so the app can find its `issues/` folder.
7. As a developer, I want a project's `projectKey` auto-derived (slugified) from its name when I create it, so I don't have to think about backend-scoping identifiers.
8. As a developer, I want to toggle "Has Bug Reports" and "Has Announcements" per project, so only relevant sections appear for that project.
9. As a developer, I want to edit a project's name, local path, and toggles later, and remove a project I no longer track.
10. As a developer, I want `personal-crm` itself registered as a project, so I can manage this app's own backlog inside the same tool.

### Kanban

11. As a developer, I want a 5-column kanban board (Backlog / Ready / In Progress / QA / Done) for the selected project, sourced from `issues/<status>/*.md` files in its local path.
12. As a developer, I want each issue card to show its title, feature tag, other tags, id, and date.
13. As a developer, I want to click an issue card to open a full detail view with the rendered markdown description and an acceptance-criteria checklist.
14. As a developer, I want to check/uncheck acceptance-criteria items from the detail view, with the change persisted back into the issue's markdown file.
15. As a developer, I want to move an issue to a different status via a "Move" action (a status picker, not drag-and-drop), which moves the file between `issues/<status>/` folders and updates its frontmatter.
16. As a developer, I want to edit an issue's title, body, feature, and tags from the detail view.
17. As a developer, I want a "Rescan" action that re-reads the `issues/` folder from disk, so changes made outside the app (by Claude Code, git pull, etc.) show up.
18. As a developer, I want to see an issue's frontmatter and file path in the detail view, so I can cross-reference with the filesystem.

### Bug Reports

19. As a developer, for projects with "Has Bug Reports" enabled, I want an inbox of bug reports from the shared backend, filterable by severity (info/warning/error/critical).
20. As a developer, I want to open a bug report and see its full message, stack trace, source, and timestamp.
21. As a developer, I want to mark a bug report resolved or delete it.
22. As a developer, I want to convert a bug report into a kanban issue, choosing either "write the `.md` file directly" (instant, local) or "generate with Claude Code" (an agent run with full bug context).

### Announcements

23. As a developer, for projects with "Has Announcements" enabled, I want an Announcements section reusing the existing create/edit/list UI (title, markdown body, type badge, CTA, published toggle), now scoped to that project.
24. As a developer, I want to create, edit, publish/unpublish, and delete announcements for a project via the shared backend.

### Home / local chat

25. As a developer, I want a Home tab with a ChatGPT-style chat backed by a local Ollama instance, so I can get help without sending data off-device.
26. As a developer, I want a sidebar of past conversations with relative timestamps and a "New chat" button.
27. As a developer, I want to switch the active model via a model switcher populated from Ollama's available models.
28. As a developer, I want streaming responses with a "generating…" indicator, and rendered code blocks/markdown in replies.
29. As a developer, I want an empty state with suggested prompts when I haven't started a conversation yet.
30. As a developer, I want my conversations persisted locally between app launches.

### Agent execution ("Run skill")

31. As a developer, I want a "Run skill" action on the kanban board and on an issue's detail view, so I can hand off work to Claude Code via n8n.
32. As a developer, I want a full-takeover view streaming the agent's thinking, tool calls, and results live as it works.
33. As a developer, I want to stop a running skill.
34. As a developer, I want to send a long-running skill run to the background and have a way back into it, so I can keep using the app while it works.
35. As a developer, when a skill run finishes, I want a quick way to jump back to the kanban board to see the new/updated issues.

### Settings

36. As a developer, I want a Settings → Projects screen with full CRUD over my registered projects.
37. As a developer, I want a Settings → Services screen to configure the n8n base URL, Ollama base URL, shared backend URL + secret, and an optional Claude API key.
38. As a developer, I want these service settings to persist across restarts using the existing `.env` + override mechanism.
39. As a developer, I do not want a light/system theme switcher in Settings, since the whole app is dark-only by design.

### Cleanup

40. As a developer, I want the old Portfolio, Keep Track, Time Tracker, Ari Connect, and Minecraft tabs, sidebars, and screens fully removed, so the codebase only contains the new pivot's code paths.
41. As a developer, I want the five per-tab accent colors replaced by the design's single accent + status/severity token set, applied consistently across all new screens.

---

## Implementation Decisions

### Global shell & navigation

- `AppTab` is reduced to three values: `home`, `projects`, `settings` (replaces the current 5-tab enum). The horizontal `AppTabBar` is replaced by a vertical icon rail (`AppRail`) on the left edge, matching `.cc-rail` in the design (icons for Home/Projects at top, Settings pinned to the bottom).
- `AppSidebar` becomes contextual based on `selectedTab`:
  - `home` → conversation list (from the chat feature's controller) + "New chat" button
  - `projects` → list of registered projects (from `ProjectsController`)
  - `settings` → static section list: Projects / Services / About
- A new `ProjectSection` enum (`kanban`, `bugReports`, `announcements`) drives the pill/segmented switcher (`.cc-seg`) shown in a project's page header. Only sections enabled for the selected project (`hasBugReports`/`hasAnnouncements`) are rendered as pills; `kanban` is always present.
- `ShellStateData` and `ShellController` are reshaped (adapted from the existing `StreamState`-based pattern):

  ```dart
  enum AppTab { home, projects, settings }
  enum ProjectSection { kanban, bugReports, announcements }

  class ShellStateData {
    final AppTab selectedTab;
    final String? selectedProjectId;
    final ProjectSection selectedProjectSection;
  }

  class ShellController extends StreamState<ShellStateData> {
    void selectTab(AppTab tab);                 // switching to `projects` does not change selectedProjectId
    void selectProject(String projectId);       // resets selectedProjectSection to ProjectSection.kanban
    void selectProjectSection(ProjectSection s); // no-op if section not enabled for current project
  }
  ```

- `kTabSections`/`kTabSectionGroups` and the old per-tab `AppSection` enum (13 values) are removed entirely; section navigation within Projects is handled by `ProjectSection` + the pill switcher, not the sidebar.

### Visual design system

- `AppColors` is reworked to match the design's CSS custom properties, replacing the 5 per-tab accents with a single accent pair plus status/severity scales:
  - Backgrounds: `background` (`#0C0C0E`, frame), `titlebarBackground`/rail background (`#1A1A1D`), `surface` (`#0E0E10`, sidebar/content), `surfaceElevated` (`#161619`, cards), `surfaceRaised` (`#1C1C20`, inputs/raised cards)
  - Borders: `border` (white @ 7%), `borderStrong` (white @ 13%)
  - Text: `textPrimary` (`#EDEDEE`), `textSecondary` (`#9A9AA2`), `textTertiary` (`#65656D`), `textFaint` (`#46464D`)
  - Accent: `accent` (`#8B7FF5`), `accentLight` (`#A99DFF`), `accentBg` (accent @ ~16%)
  - Status (Kanban): `statusBacklog` (`#8A8A93`), `statusReady` (`#5B8DEF`), `statusInProgress` (`#E0A23C`), `statusQa` (`#F0816A`), `statusDone` (`#3FB98F`)
  - Severity (Bug Reports): `severityInfo` (`#5B8DEF`), `severityWarning` (`#E0A23C`), `severityError` (`#F0816A`), `severityCritical` (`#E5484D`)
  - Existing general-purpose `success`/`warning`/`error`/`info` semantic colors are kept for non-domain UI feedback (snackbars, validation), separate from the status/severity tokens above.
- `AppStyling` typography switches font families from DM Sans/DM Mono to IBM Plex Sans / JetBrains Mono (both available via the existing `google_fonts` dependency — no new package). The existing type scale (`displayLg/displayMd/headingLg/headingMd/bodyLg/bodySm/label/mono/monoSm`) is retained; add `pageTitle` (24px/700) and `pageSub` (13px/400) to match `.cc-page-title`/`.cc-page-sub`.
- `ThemeData` stays `Brightness.dark`; no light/system theme is implemented.
- The app/window title remains "Codex" (the design's "Command Center" titlebar text was the mockup's working title for this redesign, not a rebrand).

### Projects registry

- `Project` entity: `{ id, name, localPath, projectKey, hasBugReports, hasAnnouncements }`.
- `id` and `projectKey` are the same value: a slug derived from `name` at creation time (lowercase, non-alphanumeric runs collapsed to `-`, trimmed). If the slug collides with an existing project's id, a numeric suffix (`-2`, `-3`, …) is appended. Once set, `id`/`projectKey` never changes — renaming a project later does not re-slug it, so existing backend-scoped data (bug reports, announcements) stays associated.
- `ProjectsRepository` (abstract): `fetchAll()`, `add(Project)`, `update(Project)`, `remove(String id)`. `ProjectsRepositoryImpl` persists the list as JSON in `shared_preferences` (consistent with existing config/override usage — no new local DB).
- `ProjectsController extends StreamState<AsyncState<List<Project>>>`: `load()`, `addProject(name, localPath, {hasBugReports, hasAnnouncements})` (derives id/projectKey), `updateProject(...)`, `removeProject(id)`.

### Kanban (Issues)

- `Issue` entity and `IssueStatus` enum follow `docs/dev-workflow-app-spec.md`: `Issue { id, title, feature, status, createdAt, tags, body, filePath }`, `IssueStatus { backlog, ready, inprogress, qa, done }` — these map 1:1 to `issues/<status>/` folder names and to the design's `STATUS` labels/colors.
- `IssuesRepository` (abstract): `listIssues(localPath)`, `createIssue(localPath, Issue)`, `updateIssue(Issue, {title?, body?, feature?, tags?})`, `moveIssue(Issue, IssueStatus newStatus)`. The filesystem implementation reads `{localPath}/issues/{backlog,ready,inprogress,qa,done}/*.md`, parsing YAML frontmatter (new `package:yaml` dependency) and the markdown body separately.
- `moveIssue` rewrites the `status:` frontmatter field and moves the file to the corresponding folder.
- Acceptance-criteria checkboxes (`- [ ]` / `- [x]` lines under an "Acceptance criteria" heading in the body) are toggled in place by index and the body is rewritten to disk via `updateIssue`.
- `IssuesController extends StreamState<AsyncState<List<Issue>>>`: `load(localPath)`, `move(issue, newStatus)`, `update(issue, ...)`, `create(localPath, issue)`.
- UI follows `screen-projects.jsx`: 5-column board (`KanbanColumn`/`IssueCard`) and `IssueDetailScreen` (rendered markdown via the existing `flutter_markdown_plus` dependency, acceptance criteria, frontmatter panel, Edit/Move/Run skill actions). "Move" is a dropdown of target statuses, not drag-and-drop.

### Bug Reports

- `BugReport` entity and `BugSeverity` enum follow the spec: `BugReport { id, project, severity, message, stack, timestamp, source, resolved }`, `BugSeverity { info, warning, error, critical }` — matching the design's `SEV` map.
- `BugReportsRepository` (abstract): `fetchAll(projectKey)`, `setResolved(projectKey, id, bool)`, `delete(projectKey, id)`. HTTP impl calls the shared backend (see API contract below).
- `BugReportsController extends StreamState<AsyncState<List<BugReport>>>`: `load(projectKey)`, `resolve(id)`, `delete(id)`.
- UI follows `screen-bugs.jsx`: `BugInboxScreen` (severity filter pills + list), `BugDetailScreen` (message, stack trace, resolve/delete), `BugConvertScreen` (modal with two paths):
  - "Write `.md` directly" → builds an `Issue` from the bug report (title from the message's first line, body includes the message + stack trace, tags include the severity) and calls `IssuesRepository.createIssue(localPath, issue)` into `issues/backlog/`.
  - "Generate with Claude Code" → calls `AgentRunController.start(skill: 'create-issue-from-bug', project, context: { bugReportId, message, stack, severity })`.

### Announcements

- The existing `Announcement` model and `AnnouncementType` enum (unchanged field set: `id, title, body, type, published, ctaLabel?, ctaUrl?, publishedAt?, createdAt`) move out of the Keep Track feature into the Projects feature, since they're now a per-project concept.
- `AnnouncementsRepository`/`AnnouncementsRepositoryImpl` keep the same CRUD shape as today's `keep_track` datasource (fetch/create/update/delete), but URLs become project-scoped (see API contract below) and the repository is constructed per-project (with `projectKey` baked in via a `ScopeScreen`-style DI scope when the Announcements section is opened).
- `AnnouncementsController` and the entire `announcements_section.dart` UI (header, create/edit dialogs, markdown editor with write/preview tabs, card list with type/draft badges) are reused as-is, with `AppColors.accentKeepTrack` references replaced by `AppColors.accent`.

### Home / local chat

- `ChatConversation { id, title, createdAt, updatedAt, messages }`, `ChatMessage { role, content, streaming }` (`role` = user/assistant).
- `OllamaRepository` (abstract): `listModels()` (`GET {ollamaBaseUrl}/api/tags`), `streamChat({model, messages})` (`POST {ollamaBaseUrl}/api/chat` with `stream: true`, consuming the NDJSON response stream via Dio's streamed `ResponseType` — no new HTTP/SSE dependency).
- `ChatController extends StreamState<ChatStateData>` manages the conversation list, the active conversation, and appends streamed assistant tokens to the last message as they arrive.
- Conversations are persisted as JSON in `shared_preferences` (same rationale as the project registry — avoids introducing a local database for what is expected to be a modest amount of data).
- UI follows `screen-home.jsx`: sidebar conversation list with relative timestamps + "New chat", `ModelSwitcher` dropdown (populated from `listModels()`), `Composer`, `UserMsg`/`BotMsg`/`CodeBlock` rendering via `flutter_markdown_plus`, and the empty state with suggested prompts.

### Agent execution ("Run skill")

- `AgentEvent` is a sealed class with variants `AgentThinking(text)`, `AgentToolUse(tool, input)`, `AgentToolResult(tool, output)`, `AgentResult(summary, success)` — corresponding to the `thinking`/`tool_use`/`tool_result`/`result` event types described in `docs/dev-workflow-app-spec.md`.
- `AgentRunRepository` (abstract): `run({skill, repoPath, context})` returns a `Stream<AgentEvent>`, POSTing to `{n8nBaseUrl}/webhook/dev-command-center` with body `{ skill, repo: repoPath, context }` and parsing the streamed NDJSON response into `AgentEvent`s.
- `AgentRunController extends StreamState<AgentRunStateData>` (`AgentRunStateData { events, status }`, `status` = running/done/error/stopped): `start(...)`, `stop()`.
- `AgentRunScreen` is a full-takeover overlay following `screen-agent.jsx`: header (skill name, project, elapsed time, Stop), scrolling event list (`EvThinking`/`EvTool` widgets) with a live "writing…" indicator, and a footer with "Run in background" / "View board when done".
- Skill identifiers are a fixed list defined in code for V1 (e.g. `create-issues`, `work-issue`, `create-issue-from-bug`) — not dynamically discovered from n8n. Trigger points: kanban page header "Run skill" (skill picker), issue detail "Run skill" (pre-selects `work-issue` with `issueId` context), bug-report convert modal (pre-selects `create-issue-from-bug`).
- "Run in background" dismisses the takeover overlay while keeping `AgentRunController` alive (kept registered in `DiContainer` for the duration of the run); a small persistent indicator (e.g. a pill near the rail) shows while a run is active and reopens `AgentRunScreen` when tapped.

### Settings

- **Projects** card: full CRUD list over `Project` (via `ProjectsController`) — Add/Edit dialog with Name, Local path (text field + directory picker via the existing `file_picker` dependency), "Has Bug Reports" toggle, "Has Announcements" toggle. The derived `projectKey`/`id` is shown read-only.
- **Services** card: text fields for `N8N_BASE_URL`, `OLLAMA_BASE_URL`, `DEVCENTER_BACKEND_URL` (renamed from `KEEP_TRACK_BASE_URL`), `CRM_SECRET`, and an optional `CLAUDE_API_KEY` — persisted via the existing `env_override_` SharedPreferences mechanism in `main.dart`, same as current env overrides.
- **About**: minimal static info (app name "Codex", version) — no new functionality beyond what's shown in the design's sidebar item.
- The Appearance card (Light/Dark/System) from the design is dropped entirely.

### Backend & external service contracts

- **Shared backend** (reworked Keep Track backend, accessed via `BaseApi.create(baseUrl: DEVCENTER_BACKEND_URL, crmSecret: CRM_SECRET)`, auth via existing `x-crm-secret` header):
  - `GET /api/v1/projects/{projectKey}/announcements/admin` → `List<Announcement>`
  - `POST /api/v1/projects/{projectKey}/announcements`
  - `PATCH /api/v1/projects/{projectKey}/announcements/{id}`
  - `DELETE /api/v1/projects/{projectKey}/announcements/{id}`
  - `GET /api/v1/projects/{projectKey}/bug-reports` → `List<BugReport>`
  - `PATCH /api/v1/projects/{projectKey}/bug-reports/{id}` (`{ resolved: bool }`)
  - `DELETE /api/v1/projects/{projectKey}/bug-reports/{id}`
  - `POST /api/v1/projects/{projectKey}/bug-reports` — ingest endpoint called by *other* apps (e.g. Keep Track mobile) to report bugs; not called by this client, documented here for contract completeness.
  - The backend implementation itself is a separate service/codebase; this PRD specifies the contract the Flutter client is built against.
- **n8n**: `POST {n8nBaseUrl}/webhook/dev-command-center` with `{ skill, repo, context }`, response is a streamed NDJSON sequence of `{ type: 'thinking' | 'tool_use' | 'tool_result' | 'result', ... }` events.
- **Ollama**: standard local API — `GET {ollamaBaseUrl}/api/tags`, `POST {ollamaBaseUrl}/api/chat` with `{ model, messages, stream: true }`.

### New dependencies

- `package:yaml` — parsing `issues/<status>/*.md` frontmatter. No other new dependencies are required; markdown rendering (`flutter_markdown_plus`), file picking (`file_picker`), HTTP/streaming (`dio`), persistence (`shared_preferences`), fonts (`google_fonts`), env config (`flutter_dotenv`), and window chrome (`window_manager`) are all already present.

### Removed code

- `lib/features/portfolio`, `lib/features/time_tracker`, `lib/features/ari_connect`, `lib/features/minecraft` — deleted entirely.
- Within `lib/features/keep_track`: releases, analytics, and support (controllers, datasources, sections, state, and the `VERCEL_*`/`LEMON_SQUEEZY_*` env var reads) are deleted. Only the announcement model/UI survives, generalized and moved into the new `projects` feature as described above.
- The 13-value `AppSection` enum, `kTabSections`, `kTabSectionGroups`, and the old `AppTabBar` widget are deleted.
- The 5 per-tab `AppColors` accents (`accentPortfolio`, `accentKeepTrack`, `accentTimeTracker`, `accentAriConnect`, `accentMinecraft`) are deleted.

---

## Testing Decisions

- **Seam**: controller-level unit tests against fake repositories. Each feature exposes an abstract repository interface (HTTP/filesystem/Ollama/n8n/persistence) with a real implementation and a hand-written fake for tests — extending the shape already present in `KeepTrackRepository`/`KeepTrackRepositoryImpl`, even though that pattern is currently untested.
- A good test constructs the relevant `StreamState` controller with a fake repository, drives it through its public methods, and asserts the sequence of emitted `AsyncState<T>` values (or `ShellStateData`/`AgentRunStateData`) via `controller.stream`/`controller.state`. Tests should not reach into private widget state or assert on styling/markup — only on emitted state and repository calls recorded by the fake.
- Controllers to cover: `ShellController`, `ProjectsController`, `IssuesController`, `BugReportsController`, `AnnouncementsController`, `ChatController`, `AgentRunController`.
- New fakes needed: `FakeProjectsRepository`, `FakeIssuesRepository`, `FakeBugReportsRepository`, `FakeAnnouncementsRepository`, `FakeOllamaRepository`, `FakeAgentRunRepository` (the latter can emit a canned `Stream<AgentEvent>` to test `AgentRunController`'s state transitions across thinking/tool/result events and stop/background behavior).
- Out of scope for testing: widget tests, golden/pixel tests against the design mockup, and integration tests against a real backend, filesystem, Ollama instance, or n8n instance.

---

## Out of Scope

- Implementing the reworked shared backend service itself — only its API contract is specified here as a dependency for the Flutter client.
- Defining the n8n workflows or the underlying `claude` CLI skill scripts — only the client-side request/response contract is specified.
- Light and "System" theme support — the app remains dark-only.
- Drag-and-drop reordering on the kanban board (status changes go through the "Move" picker).
- Live filesystem watching of `issues/` — refresh is manual via "Rescan".
- Real-time notifications/polling for new bug reports — refresh is manual.
- Renaming, deleting, or exporting chat conversations beyond create + list.
- Multi-user accounts or auth beyond the existing shared `x-crm-secret`.
- Mobile or responsive layouts — desktop only, existing window sizing (1200×760, min 960×600) is unchanged.
- Dynamic skill discovery for "Run skill" — the skill list is fixed in code for V1.
- Visual regression / golden-image testing against the design mockup.

---

## Further Notes

- Source design: the `Dev Command Center.html` mockup bundle (frame/shell primitives, `screen-home.jsx`, `screen-projects.jsx`, `screen-agent.jsx`, `screen-bugs.jsx`, `screen-settings.jsx`) is the visual reference for all new screens; its CSS custom properties are the source for the `AppColors` values above.
- Suggested build order, given dependencies between pieces:
  1. Theme tokens (`AppColors`/`AppStyling`) + shell rewrite (`AppRail`, contextual `AppSidebar`, `ShellController`/`ShellStateData`) with placeholder content areas — gets the app into a buildable, navigable state quickly.
  2. Projects registry + Settings → Projects/Services.
  3. Kanban (core dev-workflow value, no backend dependency).
  4. Announcements (mostly a move + re-parameterization of existing code — fast win).
  5. Bug Reports (depends on the shared backend rework landing).
  6. Home / Ollama chat.
  7. Agent execution / "Run skill" (depends on the n8n contract above).
  8. Final cleanup pass: delete the old features and dead color tokens.
- Renaming `KEEP_TRACK_BASE_URL` to `DEVCENTER_BACKEND_URL` requires a one-line manual update to the local `.env` file; low risk since it's not committed.
- Once this lands, `personal-crm`'s own `issues/` folder (created as part of registering it as a project) becomes the place to track follow-up work for this app itself, including any future ADR documenting this pivot in `docs/adr/`.
