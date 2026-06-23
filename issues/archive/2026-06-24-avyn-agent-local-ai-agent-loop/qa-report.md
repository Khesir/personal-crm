# QA Report

_Date: 2026-06-22_

---

## Automated QA Results

| Issue | Title | Build | Tests Pass | Test Quality | Lint | Code Review | Result |
|-------|-------|-------|------------|--------------|------|-------------|--------|
| [001](qa/001-delete-agent-run-simplify-dock.md) | Delete agent_run + simplify dock | ✅ | ✅ | ✅ | ✅ | ⚠️ | Pass (with note) |
| [002](qa/002-python-agent-server-scaffold.md) | Python agent server scaffold | ✅ | ❌ | ⚠️ | n/a | ⚠️ | Fail |
| [003](qa/003-llm-provider-abstraction.md) | LLM provider abstraction | ✅ | ✅ | ✅ | n/a | ✅ | Pass |
| [004](qa/004-basic-agent-loop-sse-streaming.md) | Basic agent loop + SSE streaming | ✅ | ✅ | ✅ | n/a | ✅ | Pass |
| [005](qa/005-flutter-agent-feature-controller-chatpane.md) | Flutter AgentController + ChatPane | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [006](qa/006-brain-injection.md) | Brain injection into system prompt | ✅ | ✅ | ✅ | n/a | ⚠️ | Pass (with note) |
| [007](qa/007-session-persistence.md) | Session persistence (SQLite) | ✅ | ✅ | ✅ | n/a | ✅ | Pass |
| [008](qa/008-web-search-web-fetch-tools.md) | web_search + web_fetch tools | ✅ | ✅ | ✅ | n/a | ✅ | Pass |
| [009](qa/009-shell-file-tools.md) | shell + file_read + file_write tools | ✅ | ✅ | ✅ | n/a | ✅ | Pass |
| [010](qa/010-memory-tools.md) | memory_read + memory_write tools | ✅ | ✅ | ✅ | n/a | ⚠️ | Pass (with note) |
| [011](qa/011-working-project-context-flutter.md) | Working project context in ChatPane | ✅ | ✅ | ✅ | ✅ | ✅ | Pass |
| [012](qa/012-deep-research-pipeline.md) | Deep research pipeline | ✅ | ✅ | ⚠️ | n/a | ✅ | Pass (with note) |
| [013](qa/013-server-lifecycle-flutter.md) | Server lifecycle (spawn/PID/reconnect) | ✅ | ✅ | ❌ | ✅ | ⚠️ | Fail |
| [014](qa/014-system-tray.md) | System tray | ✅ | ✅ | ❌ | ✅ | ⚠️ | Fail |
| [015](qa/015-chromadb-vector-memory.md) | ChromaDB vector memory | ✅ | ✅ | ✅ | n/a | ✅ | Pass |
| [016](qa/016-llm-provider-settings-ui.md) | LLM provider + port settings UI | ✅ | ✅ | ❌ | ✅ | ❌ | Fail |
| [017](qa/017-pyinstaller-packaging.md) | PyInstaller packaging | — | n/a (HITL) | n/a | n/a | ✅ | Needs HITL |

---

## Issues with automated failures

### 002 — Python agent server scaffold

**One problem, but it poisons the whole automated test run.** The `/shutdown` endpoint, when triggered, sends a termination signal to its own process to stop the server cleanly. That's correct behaviour for the real running server, but the test for this endpoint exercises the FastAPI app in-process (no separate server process is spawned for the test) — so the same termination signal kills the test runner itself partway through the assertion. Running the full automated test suite for the agent server in one invocation never completes; everything after this test silently never runs.

This was invisible to the implementer because the test passes when run alone or as the last item in its file, but corrupts the run whenever the rest of the suite is collected alongside it (the default `pytest` invocation). I verified the rest of the suite (46 tests across 9 other files) all pass once this one test is excluded — so the underlying tool/loop/session/research/vector behaviour is sound. The shutdown test itself needs to verify the shutdown behaviour without actually terminating the process running the test.

Not blocking any other issue's verification — I was able to assess all other issues by excluding this one test.

### 013 — Server lifecycle (spawn/PID/reconnect)

**Tests required: Yes, but the actual behaviours described are not exercised.** The issue explicitly calls for tests asserting: reconnect-without-spawn on a live PID, spawn-on-dead-PID, error-state-after-15s-timeout, and shutdown-called-on-clean-close. The only test present instantiates the manager and checks its two default flags are false — none of the four required scenarios are exercised.

This isn't just a missing-test gap — the manager talks directly to `HttpClient`, `Process.start`, and the filesystem with no injected seam, so the required scenarios cannot be tested without either refactoring for testability or spinning up a real process/server in tests. As-is, none of issue 013's acceptance criteria are verified by the test suite; they're only verified by reading the implementation, which does look behaviourally reasonable (health-check polling correctly distinguishes a live server from a stale PID file).

### 014 — System tray

**Tests required: Yes, but the test reimplements the logic under test rather than exercising it.** The issue asks for tests asserting that closing the window while a loop is active triggers minimize-to-tray (not quit), and that closing with no loop triggers shutdown. The actual test never calls the app's exit handler — it independently recomputes `status == AgentStatus.running` inline and asserts that boolean, which will always pass regardless of whether the real exit handler is wired correctly. The one assertion that does exercise production code (`stop()` resets status) is fine, but it isn't what the issue asked to verify.

Net effect: the close-to-tray vs. close-to-quit behaviour described in the acceptance criteria has no real automated coverage. The implementation reads correctly on inspection, but this needs the visual QA pass (already flagged below) to actually confirm it, since the automated tests don't.

### 016 — LLM provider + port settings UI

**Two independent problems — flag separately.**

1. **Tests required: Yes, but only the "server unreachable" fallback path is exercised.** The issue asks for tests confirming fields render with values from the current config, that saving posts the correct payload, and that changing the port shows the restart note. None of these are tested — the single test only confirms the "agent server not running" message appears, which is also the *only* state reachable in the test environment, because the settings UI talks straight to the agent server over HTTP with no fake/mock seam.

2. **Architecture rule violation, not just a test gap.** This codebase's hard rule is that the presentation layer must never make backend requests directly — all requests flow through a Controller into a Repository. This settings screen skips that entirely: the State class instantiates an HTTP datasource itself and calls it directly, with no Controller or Repository in between. That's why it can't be tested without a live server, and it's inconsistent with how every other settings section in this codebase is built.

These two problems are related (the architecture violation is why the test gap exists) but I'd treat the architecture issue as the one to fix — fixing it resolves the testability problem too.

---

## Notes that aren't blocking, but worth a second pass

- **001 — scope creep + dead code.** The issue's scope only covers `agent_run`, `agent_pane.dart`, `DockPane`, and `dock_state.dart`. The actual change also rewrites `bug_reports_section.dart`, removing the "Generate issue with Claude Code" conversion path entirely (only "write directly" remains) and is not mentioned anywhere in the issue. The dialog this used to open, `bug_convert_dialog.dart`, is left on disk and is no longer referenced anywhere in the app — dead code. Worth confirming this removal was intentional, and if so, deleting the now-unused dialog file.
- **006 / 010 — Brain injection and memory tools are implemented but unreachable from the running app.** Both are fully implemented and tested on the Python side (files written to a temp dir, asserted against directly), but nothing on the Flutter side ever sends `brain_path` or `brain_files` in a `/chat` request — `AgentController` and `AgentDatasource` (issue 005) have no fields for either. In the real app, every chat request always sends `brain_path: null`, so Brain injection never actually triggers and `memory_read`/`memory_write` always return their "no brain_path" error path. Each issue's own automated tests pass because they exercise the Python server directly with a path supplied by the test, so this gap won't surface there — it only shows up end-to-end. No Flutter-side issue currently exists to wire this through.
- **012 — minor test-quality smell.** `test_manage_research_done` throws a `RuntimeWarning: coroutine '_run_pipeline' was never awaited` — a background pipeline task is started and never cleaned up/awaited in that test. Doesn't fail the test, but indicates a dangling task that could leak between tests if the suite grows.

---

## Visual QA Checklist

## Visual QA — 013 Server lifecycle (Flutter spawns, PID check, reconnect)

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Launch the app with no agent server already running | App startup | Chat pane briefly shows a "starting" state, then becomes usable once the agent server is healthy |
| 2 | Launch the app a second time while the first instance (and its agent server) is still running | App startup | Second launch reconnects to the existing agent server — no second agent process appears in Task Manager |
| 3 | Rename/remove the agent executable so it can't start, then launch | App startup | After ~15 seconds, the chat pane shows a clear error state instead of hanging |
| 4 | Quit the app normally with no chat in progress | App close | The agent process exits along with the app — no orphaned process left in Task Manager |

**Edge cases to manually test:**
- [ ] Kill the agent process manually (Task Manager) while the app is open, then send a chat message — confirm the app's behavior (reconnect, error, or restart) is sensible, not a silent hang
- [ ] Quickly close and relaunch the app twice in a row — confirm only one agent process is ever running

## Visual QA — 014 System tray

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Start a chat message that's still in progress, then click the window close button | Main window | Window hides instead of closing; a tray icon for Avyn appears in the Windows system tray |
| 2 | Hover over the tray icon the first time this happens | System tray | Tooltip reads something like "Avyn is still running in the background" |
| 3 | Right-click the tray icon while a chat is running | System tray | Menu shows "Open Avyn", "Agent: Running" (greyed out, not clickable), "Stop agent", "Quit" |
| 4 | Right-click the tray icon while idle (no chat running) | System tray | Menu shows "Open Avyn", "Agent: Idle" (greyed out), "Quit" — no "Stop agent" item |
| 5 | Click "Open Avyn" from the tray menu | System tray | Main window reappears and is focused |
| 6 | Click "Stop agent" while a chat is mid-stream | System tray | The in-progress chat stops/cancels; tray menu updates to "Agent: Idle" shortly after |
| 7 | Click "Quit" while a chat is running | System tray | App fully exits (no window, no tray icon) and the agent process is gone from Task Manager |
| 8 | Close the window with no chat running (no prior tray interaction) | Main window | App exits normally — no minimize-to-tray, no lingering tray icon |

**Edge cases to manually test:**
- [ ] Close to tray, then quit from the tray menu — confirm the agent process is actually terminated, not left running
- [ ] Minimize to tray twice in the same session — confirm the "still running" tooltip hint doesn't repeat/spam on the second time

## Visual QA — 016 LLM provider + port settings UI

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Open Settings with the agent server running | Settings → Agent section | Provider dropdown, model field, and port field are pre-filled with the current config; API key field only appears for OpenAI/Anthropic |
| 2 | Open Settings with the agent server NOT running | Settings → Agent section | A message like "Agent server not running" is shown instead of the form |
| 3 | Change the provider dropdown from Ollama to OpenAI | Settings → Agent section | API key field appears; for Anthropic it also appears; switching back to Ollama hides it again |
| 4 | Change the port field value and look below it | Settings → Agent section | A note appears stating the port change takes effect on next server restart |
| 5 | Change provider/model and click Save | Settings → Agent section | Save button shows a brief loading state; after saving, sending a new chat message uses the newly selected provider without restarting the app |

**Edge cases to manually test:**
- [ ] Enter a non-numeric port value — confirm the field rejects non-digit input rather than crashing or silently sending garbage
- [ ] Save with an empty API key while Anthropic/OpenAI is selected — confirm the resulting behavior is sensible (saved as empty vs. blocked)

## Visual QA — 017 PyInstaller packaging (HITL — manual acceptance gate)

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Run the build script on a machine with Python + PyInstaller installed | `agent/build.ps1` | Produces `agent/dist/avyn-agent.exe` without errors |
| 2 | Copy just the `.exe` to a clean Windows machine/VM with no Python installed | Clean VM | `.exe` starts without complaining about missing Python or DLLs |
| 3 | Hit `GET /health` against the running `.exe` | Clean VM | Returns `{"status": "ok"}` |
| 4 | Configure a real LLM provider and send a `/chat` request | Clean VM | Streams back a real response end-to-end |
| 5 | Check `%APPDATA%\Avyn\agent\agent.pid` while the `.exe` is running | Clean VM | File exists and contains the `.exe`'s PID |

**Edge cases to manually test:**
- [ ] Confirm `agent/dist/` and `agent/build/` are git-ignored and the `.exe` was not accidentally committed

---

## How to sign off

For each issue you visually verify:
- Approved → run `/qa-approve [issue number]`
- Something is wrong → run `/qa-reject [issue number] [what you saw]`
