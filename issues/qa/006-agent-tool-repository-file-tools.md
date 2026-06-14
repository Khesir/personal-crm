---
id: issue-006
title: "AgentToolRepository: file tools (read_file, list_dir, grep, write_file, edit_file) with path-boundary enforcement"
feature: home-chat-agent-mode
status: qa
created_at: 2026-06-14
tags: [afk, p1]
---

# [006] AgentToolRepository: file tools (read_file, list_dir, grep, write_file, edit_file) with path-boundary enforcement

**Type:** AFK
**Priority:** P1
**Blocked by:** 004
**User stories covered:** 4, 5, 6, 7, 8, 16, 27, 28

---

## What to build

A new `AgentToolRepository` (domain interface + impl, following the existing repository pattern) that
executes the v1 fixed tool set against the filesystem, with path-boundary enforcement. No model/provider/UI
wiring in this issue — that's issue 008 (agent loop).

- Tool set (each defined once as a `ToolDefinition` constant, per PRD's "Tool set" section):
  - `read_file(path)` — returns file contents.
  - `list_dir(path)` — returns directory entries (files/folders).
  - `grep(pattern, path?)` — searches file contents under `path` (defaults to project root) for `pattern`.
  - `write_file(path, content)` — creates a new file with `content`; errors if `path` already exists.
  - `edit_file(path, old_text, new_text)` — replaces `old_text` with `new_text`; errors unless `old_text`
    matches **exactly once** in the file.
- `AgentToolRepository.execute(ToolCall call, { required String workingProjectPath, required List<String>
  trustedReferenceProjectPaths })` returns a `ToolExecutionResult`, one of:
  - `ToolOutput(text)` — successful read-only result, or a successfully-applied write (used when an
    already-approved write/edit is executed by the caller).
  - `ToolWriteProposal(path, preview)` — for `write_file`/`edit_file`: `preview` is either the new file's
    content (creation) or an old/new text pair (edit), for rendering a diff. Execution is **not** performed
    until the caller explicitly applies it.
  - `ToolReferenceConfirmationNeeded(projectId, path)` — the resolved path falls under a registered project
    that isn't the working project and isn't yet in `trustedReferenceProjectPaths`.
  - `ToolError(message)` — file not found, ambiguous/missing `edit_file` match, path outside all known
    projects, permission error, etc.
- **Path resolution**: relative paths resolve against `workingProjectPath`. A resolved path is permitted for
  reads if it falls under `workingProjectPath` or any path in `trustedReferenceProjectPaths`/registered
  project paths passed in; permitted for writes only if it falls under `workingProjectPath`. Anything else →
  `ToolError` (access denied).

---

## Acceptance criteria

- [ ] `ToolDefinition` constants for all 5 tools exist with correct JSON Schema `parameters`.
- [ ] `read_file`, `list_dir`, `grep` happy paths return `ToolOutput` with correct content for files/dirs
  under the working project.
- [ ] `write_file` on a new path returns a `ToolWriteProposal` with the file's content as preview; on an
  existing path returns `ToolError`.
- [ ] `edit_file` with exactly one match of `old_text` returns a `ToolWriteProposal` with an old/new text
  diff preview; zero matches or multiple matches returns `ToolError`.
- [ ] Reads succeed for paths under the working project AND under a path in `trustedReferenceProjectPaths`.
- [ ] A read for a path under a *registered but untrusted* reference project returns
  `ToolReferenceConfirmationNeeded(projectId, path)`.
- [ ] `write_file`/`edit_file` targeting a path outside the working project (including reference projects)
  returns `ToolError` — never a proposal.
- [ ] A path outside all known project roots returns `ToolError` for any tool.

---

## Tests required

Yes — pure Dart tests using `Directory.systemTemp.createTemp()` as fake working/reference project roots,
alongside the new repository (per PRD testing decisions): cover each of the 5 tools' happy paths,
`edit_file`'s zero/multiple-match error, and path-boundary enforcement (working project read/write, reference
project read-only, outside-all-projects denied). No Flutter or network dependencies.

---

## Notes

- Depends on 004 for the `ToolCall` type passed into `execute()`.
- `run_command`/process execution is explicitly out of scope (story 30) — do not add a 6th tool.
- See PRD section "New module: agent tool execution" for the exact result-type shapes.

---

## Log

_Updated as work progresses._

- Implemented `ToolDefinition` constants for all 5 v1 tools in
  `lib/features/home/domain/model/agent_tools.dart` (`kReadFileTool`, `kListDirTool`, `kGrepTool`,
  `kWriteFileTool`, `kEditFileTool`, plus `kAgentTools` list), and sealed result types
  (`ToolOutput`, `ToolWriteProposal`/`ToolWritePreview` (`WriteFileCreation`, `EditFileChange`),
  `ToolReferenceConfirmationNeeded`, `ToolError`) in
  `lib/features/home/domain/model/tool_execution_result.dart`.
- `AgentToolRepository.execute(call, {required workingProjectPath, required
  trustedReferenceProjectPaths, required registeredProjectPaths})` —
  `registeredProjectPaths` is `Map<String, String>` mapping each registered project's `localPath`
  to its project id (including the working project), added to disambiguate "registered but
  untrusted reference project" (`ToolReferenceConfirmationNeeded`) from "outside all known
  project roots" (`ToolError`) per the acceptance criteria. `grep`'s `pattern` is treated as a
  literal substring (via `RegExp.escape`), searched recursively under `path` (default
  `workingProjectPath`); unreadable/binary files are skipped.
- Implementation in `lib/features/home/data/repository/agent_tool_repository_impl.dart`. Tests in
  `test/features/home/data/repository/agent_tool_repository_impl_test.dart` (18 tests, pure Dart
  against `Directory.systemTemp.createTemp()`) cover all 5 tools' happy paths, write/edit
  existing-path and zero/multiple-match errors, and the working/trusted-reference/untrusted-
  reference/unknown-path boundary matrix. `flutter test` (18/18 passing) and `flutter analyze`
  (no issues) both clean.
