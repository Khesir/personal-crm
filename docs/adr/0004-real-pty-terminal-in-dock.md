# 4. Use a real PTY (flutter_pty + xterm) for the dock's Terminal pane

## Status

Accepted

## Context

The dock's Terminal pane (issue 004) currently only renders the `AgentEvent`
transcript of an `AgentRunController` run — it isn't a terminal at all, and
is only useful while a skill is running. The follow-up round for the dock
wants Terminal to be a genuinely usable shell: type a command, run it,
interact with it, scoped to the working project's directory. The only
process-execution primitive in the app today is `ProcessRunner`
(`run`/`runWithTimeout`), which is one-shot/non-interactive — it can't back a
real shell session (no live stdin, no long-running processes, no Ctrl+C).

## Decision

Add `flutter_pty` (spawns a real PTY-backed process, ConPTY on Windows) and
`xterm` (terminal emulator widget that renders the PTY's output and forwards
keystrokes) as new dependencies. The dock's Terminal pane becomes this real
interactive shell. The old `AgentEvent` transcript view is kept as a separate
"Agent" pane (read-only, independent lifecycle from pane visibility) rather
than being replaced.

## Consequences

### Positive

- Terminal becomes useful standalone (run `flutter pub get`, `git status`,
  etc.) without requiring a skill/agent run.
- `xterm`/`flutter_pty` are a known, designed-to-work-together pairing —
  avoids hand-rolling ANSI parsing or process I/O plumbing.

### Negative / Risks

- First app capability that gives the UI a real interactive shell scoped to
  a project's working directory — arbitrary commands the user types execute
  with the app's permissions, no sandboxing beyond what the OS shell itself
  provides.
- Two new native-backed dependencies (desktop-only); no PTY equivalent exists
  for mobile/web, so this pane is desktop-only by construction.

## Alternatives Considered

- **Extend `ProcessRunner`** — keep one-shot command execution, render each
  command's captured output as a block in the Terminal pane. Rejected: no
  live streaming, no long-running processes (`flutter run`, watchers), no
  Ctrl+C — doesn't meet "type a command and use it like a terminal".
