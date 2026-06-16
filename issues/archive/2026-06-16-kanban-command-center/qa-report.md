# QA Report

_Date: 2026-06-15_

---

## Automated QA Results

| Issue | Title | Build | Tests Pass | Test Quality | Lint | Code Review | Result |
|-------|-------|-------|------------|--------------|------|-------------|--------|
| [001](qa/001-dock-shell.md) | Dock shell | ⚠️ | ✅ | ✅ | ✅ | ⚠️ | Fail |
| [002](qa/002-kanban-drag-and-drop.md) | Drag-and-drop kanban cards | ⚠️ | ✅ | ✅ | ✅ | ✅ | Pass |
| [003](qa/003-inline-quick-add.md) | Inline quick-add | ⚠️ | ✅ | ✅ | ✅ | ✅ | Pass |
| [004](qa/004-terminal-pane.md) | Terminal pane | ⚠️ | ✅ | ✅ | ✅ | ⚠️ | Pass |
| [005](qa/005-chat-pane.md) | Chat pane | ⚠️ | ✅ | ✅ | ✅ | ✅ | Pass |
| [006](qa/006-kanban-visual-refresh.md) | Kanban visual refresh | ⚠️ | ✅ | n/a (no tests required) | ✅ | ✅ | Pass |
| [007](qa/007-issues-watching.md) | Issues watching | ⚠️ | ✅ | ✅ | ✅ | ⚠️ | Pass |

**Build (⚠️ across the board):** `flutter pub get`, `flutter test` (409/409 passing), and `flutter analyze` (clean — only 2 pre-existing `deprecated_member_use` infos unrelated to this batch) all succeeded. `flutter build windows --debug` compiled in ~15s with no compiler errors, but the final CMake install/copy step failed (`MSB3073` on `INSTALL.vcxproj`) because a running instance of `crm.exe` was holding the output binary locked. This is an environment issue (close the running app and rebuild), not a code defect — no Dart/C++ compile errors were produced against any of this batch's files.

---

## Issues with automated failures

### 001 — Dock shell

One problem, not blocking the rest of the batch:

- **Reopen pill doesn't show the active task or elapsed time.** The acceptance criteria call for the collapsed dock's "reopen" pill to show the active task name and elapsed time when a run is active, falling back to placeholder text only when no run is active. The current pill always renders the static placeholder ("No active task · 0:00") regardless of whether an agent run is active — it isn't wired to the dock's `agentRunController` state at all, so it never reflects a real running task or ticks an elapsed timer. The underlying `AgentRunController` already exposes `skill` and `startedAt`, so the data needed to do this is available.

This is a single, self-contained gap (one widget, one piece of missing wiring) and doesn't block verifying the rest of 001's criteria.

### 004 — Terminal pane / 007 — Issues watching (code review notes, non-blocking)

- `lib/features/kanban/presentation/state/dock_state.dart` and `lib/features/kanban/presentation/widget/terminal_pane.dart` each carry a dartdoc-style (`///`) class comment. The rest of this codebase (and this project's standing convention) avoids docstrings/dartdoc unless explicitly requested — flagging for consistency, not a functional issue.
- **007 "Just updated" badge clearing**: the acceptance criteria say the badge clears "on the next reload cycle **or** after a short timeout." The implementation only clears `changedIds` on the next watcher-triggered reload — there's no independent timeout that clears the badge if no further file change triggers a reload. In practice this means a "Just updated" badge could persist indefinitely if the watched files don't change again. Worth confirming during visual QA whether this matches the intended UX, or whether a timeout-based clear is still expected.

---

## Visual QA Checklist

## Visual QA — 001 Dock shell

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Dock placement | Projects > Kanban board | A dock panel is anchored to the bottom of the board, below the columns, matching `kanban-redesign.html`'s layout |
| 2 | Resize handle | Top edge of the dock | Hovering shows a resize cursor; dragging up/down resizes the dock height, stopping at a sensible minimum (thin bar) and maximum (doesn't overwhelm the board) |
| 3 | Collapse / reopen | Collapse button in the dock's tabbar (top-right) | Clicking it shrinks the dock to a thin bar; a floating pill appears in the bottom-right showing "No active task · 0:00" (or similar) and an up-arrow |
| 4 | Reopen pill behavior **(known gap, see automated findings)** | Floating pill, bottom-right, while dock is collapsed | Currently always shows static "No active task · 0:00" even if a skill is running — confirm whether this is acceptable for this slice or should block sign-off |
| 5 | Reopen on tap | Floating pill | Clicking the pill restores the dock to its previous height/mode |
| 6 | Mode toggle | Tabbar, terminal/chat/split icons | Clicking each icon switches the dock body to Terminal-only, Chat-only, or a split "Both" view; the selected icon is visually highlighted (accent background) |
| 7 | Split divider | Between Terminal and Chat panes in "Both" mode | A thin vertical divider can be dragged left/right to resize the two panes; each pane stops shrinking below a minimum width (~280px) |
| 8 | Session persistence | Change height/mode/split, switch to another project section (e.g. Bug Reports) and back to Kanban | Dock height, mode, and split fraction are preserved (no reset) |

**Edge cases to manually test:**
- [ ] Drag the resize handle past the min/max height repeatedly — dock should clamp smoothly without jitter or overflow errors
- [ ] Switch to "Terminal only" then "Chat only" then back to "Both" — split divider position should be remembered
- [ ] Collapse the dock while in "Both" mode, then reopen — mode should be restored to "Both"

---

## Visual QA — 002 Drag-and-drop kanban cards

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Drag lift styling | Pick up any card on the Kanban board and start dragging | The dragged card lifts with a shadow and a slight scale/rotation, per `.card.lifted` in the mockup |
| 2 | Drop placeholder | Drag a card over a different column | A dashed/highlighted placeholder box appears in the target column showing where the card will land |
| 3 | Successful move | Drop a card onto a different column | The card moves to the target column, the source column's count decreases by 1, and the target column's count increases by 1, immediately |
| 4 | Same-column drag | Drag a card and drop it back in its original column | Card returns to its original position; no error, no duplicate |
| 5 | Failure handling | (Hard to trigger manually — induce by making the issue file read-only or removing its folder before dropping) | Card snaps back to its original column and a SnackBar shows "Failed to move issue: ..." |

**Edge cases to manually test:**
- [ ] Drag a card from a column with many cards into an empty column — placeholder and "No issues" text should not overlap awkwardly
- [ ] Rapidly drag a card back and forth between two columns — no visual glitches or duplicate cards

---

## Visual QA — 003 Inline quick-add

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | "+" control | Each column header, next to the issue count badge | A small "+" icon button, styled per `.col-add` in the mockup |
| 2 | Opening quick-add | Click "+" on any column | An inline text input appears at the top of that column's card list, focused, with hint text and "Enter to create · Esc to cancel" |
| 3 | Creating an issue | Type a title and press Enter | A new card appears immediately at the top of that column with the typed title; the column's count increases by 1 |
| 4 | Cancel via Esc | Open quick-add, type nothing, press Esc | Input closes, no card created |
| 5 | Cancel via blur | Open quick-add, type nothing, click elsewhere | Input closes, no card created |
| 6 | File placement | After creating via quick-add on e.g. "Ready", check `issues/ready/` on disk | A new `.md` file exists in the matching status folder with generated `id`/`created_at` frontmatter |

**Edge cases to manually test:**
- [ ] Open quick-add, type a title, then click away (blur) with non-empty text — confirm whether it creates the issue or cancels (verify against the intended behavior — spec only requires Esc/blur-while-empty to cancel)
- [ ] Quick-add on an empty column — input + "No issues" placement should not overlap

---

## Visual QA — 004 Terminal pane

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Terminal styling | Dock, Terminal mode (or left side of "Both") | Monospace font, near-black background, ANSI-style colored text (green/cyan/yellow/red spans), matching `kanban-redesign.html`'s `.terminal-pane` |
| 2 | Empty state | Open a project that has never had a skill run, Terminal pane | Shows a message like "No agent runs yet for <project>. Run a skill from the board to see its transcript here." |
| 3 | Idle prompt | After a run finishes (or stops) with no events | Shows `➜ <project-name>` with a blinking text cursor |
| 4 | Live transcript | Click "Run skill" on the Kanban board, pick a skill | Dock auto-expands (if collapsed) and switches to a mode showing the Terminal pane; thinking/tool-use/tool-result/result lines stream in and the view auto-scrolls to follow |
| 5 | Bug Reports unaffected | Go to Bug Reports, trigger "Generate issue from bug" (or similar Claude Code action) | Still opens the full-screen `AgentRunScreen` overlay, not the dock |

**Edge cases to manually test:**
- [ ] Start a skill run while the dock is in "Chat only" mode — dock should switch to "Both" (not stay Chat-only)
- [ ] Start a skill run while the dock is collapsed — dock should auto-expand
- [ ] Let a long transcript run — confirm no overflow/clipping in the terminal pane

---

## Visual QA — 005 Chat pane

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Chat pane content | Dock, Chat mode (or right side of "Both") | Renders the same Avyn conversation as the Home tab, with cleaner styling per `kanban-redesign.html`'s `.chat-pane` |
| 2 | Model switcher | Pane header (top of the chat pane) | One model-switcher dropdown is visible in the header |
| 3 | Composer has no model badge | Bottom of the chat pane, message composer | No model name chip/badge appears next to the send button |
| 4 | Home tab composer | Home tab chat | Same as above — no model badge in the composer; header switcher still present |
| 5 | Send/receive | Type a message in the dock's Chat pane and send it | Message appears as a user bubble, assistant response streams in identically to the Home tab |
| 6 | Project scoping | Open the dock's Chat pane for two different projects | Conversation reflects `workingProjectId` scoping consistent with the Home tab's behavior |

**Edge cases to manually test:**
- [ ] Switch models via the header dropdown while in the dock's Chat pane — confirm it applies to the conversation the same way it does on the Home tab
- [ ] Resize the dock to a narrow width in "Both" mode — chat pane should remain usable (no overflow) down to its minimum width

---

## Visual QA — 006 Kanban visual refresh

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Column header | Each Kanban column | Status-colored dot (Backlog=gray, Ready=blue, In Progress=amber, QA=coral, Done=green), column name, and a pill-styled issue count badge, spacing matching `kanban-redesign.html` |
| 2 | Card styling | Any issue card | Card background, border, and corner radius match `.card` in the mockup; title uses the larger body style |
| 3 | Card feature row | Below the title on each card | Feature label with a small tag/label icon, muted color |
| 4 | Tags | Cards with tags | Each tag renders as a small pill (`surfaceRaised` background, secondary text) |
| 5 | Card footer | Bottom of each card | Issue ID (left) and created date (right), both in a faint/tertiary monospace style |
| 6 | Status dot colors | Compare each column's dot color against `kanban-redesign.html` | Colors should visually match the mockup's column accent colors |

**Edge cases to manually test:**
- [ ] Compare side-by-side with `kanban-redesign.html` open in a browser for color/spacing fidelity
- [ ] Confirm drag, quick-add, and tap-to-open-issue still all work after the styling pass (regression check)

---

## Visual QA — 007 Issues watching

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | Watch pill | Kanban board header, next to the archive dropdown | A pill reading "Watching issues/" with a pulsing dot, plus "· synced Xs ago" that increments over time |
| 2 | Rescan button | Next to the watch pill | A small icon-only button (refresh icon), no text label, with a "Rescan now" tooltip |
| 3 | Live update via filesystem | Externally edit/move/add a `.md` file under `issues/<status>/` while the board is open | Within ~1s of the 500ms debounce, the board reloads automatically and "synced Xs ago" resets to "synced just now" |
| 4 | "Just updated" badge | After an external file change triggers a reload | The affected card shows a "Just updated" badge above its title |
| 5 | Badge clearing **(see automated finding re: timeout)** | Wait without making further file changes after a "Just updated" badge appears | Confirm whether the badge should clear after a short timeout even with no further reload — currently it only clears on the *next* reload |
| 6 | Watcher unavailable fallback | (Hard to trigger manually — would require an unsupported path/platform) | If watching fails to start, the pill should indicate "Watching unavailable" and Rescan should still work |

**Edge cases to manually test:**
- [ ] Make several rapid file edits within the 500ms debounce window — should result in a single reload, not multiple
- [ ] Switch to an archived board view (read-only) — watch pill/rescan should not appear (archive view doesn't use the watcher)

---

## How to sign off

For each issue you visually verify:
- Approved → run `/qa-approve [issue number]`
- Something is wrong → run `/qa-reject [issue number] [what you saw]`

Note: issue 001 has an automated-QA finding (reopen pill not wired to active-run state) that should be addressed or explicitly accepted before sign-off, independent of the visual checklist above.
