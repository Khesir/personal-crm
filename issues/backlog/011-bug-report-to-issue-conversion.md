# [011] Bug Report → Issue conversion (both paths)

**Type:** AFK
**Priority:** P3
**Blocked by:** 006, 008, 010

---

## What to build

The "Convert to issue" flow from a bug report's detail view, per `screen-bugs.jsx`'s `BugConvertScreen`,
offering two paths:

1. **Write `.md` directly** — builds an `Issue` from the bug report (title from the message's first line,
   body includes the message and stack trace, tags include the severity) and calls
   `IssuesRepository.createIssue(localPath, issue)` to write it into `issues/backlog/`.
2. **Generate with Claude Code** — calls `AgentRunController.start(skill: 'create-issue-from-bug', project,
   context: { bugReportId, message, stack, severity })`, opening the full-takeover view from 010.

`create-issue-from-bug` is added to the fixed skill list introduced in 010.

---

## Acceptance criteria

- [ ] From a bug report's detail view, "Convert to issue" opens the modal with both options.
- [ ] "Write `.md` directly" creates a new file in `issues/backlog/` with frontmatter/body derived from the
      bug report, visible on the kanban board afterward.
- [ ] "Generate with Claude Code" starts an agent run with `skill: 'create-issue-from-bug'` and the bug's
      context, using the full-takeover view from 010.

---

## Tests required

Yes — unit tests for the bug-report → `Issue` field mapping (title/body/tags derivation), using
`FakeIssuesRepository` to assert `createIssue` is called with the expected `Issue`.

---

## Notes

- Adds `create-issue-from-bug` to the fixed skill list introduced in 010.
