/// The outcome of [AgentToolRepository.execute] for a single [ToolCall].
sealed class ToolExecutionResult {
  const ToolExecutionResult();
}

/// A successful read-only result, or the real output of a write/edit that
/// has already been approved and applied.
class ToolOutput extends ToolExecutionResult {
  final String text;

  const ToolOutput(this.text);
}

/// A `write_file`/`edit_file` call awaiting user approval before anything is
/// written to disk.
class ToolWriteProposal extends ToolExecutionResult {
  final String path;
  final ToolWritePreview preview;

  const ToolWriteProposal(this.path, this.preview);
}

/// What a pending write/edit will do, for rendering a preview/diff.
sealed class ToolWritePreview {
  const ToolWritePreview();
}

/// `write_file`: the full content of the file that would be created.
class WriteFileCreation extends ToolWritePreview {
  final String content;

  const WriteFileCreation(this.content);
}

/// `edit_file`: the single old/new text pair that would be applied.
class EditFileChange extends ToolWritePreview {
  final String oldText;
  final String newText;

  const EditFileChange(this.oldText, this.newText);
}

/// `run_command`: the shell command line that would be run, and the working
/// directory it would run in.
class CommandExecution extends ToolWritePreview {
  final String command;
  final String cwd;

  const CommandExecution(this.command, this.cwd);
}

/// The resolved path falls under a registered project that isn't the working
/// project and isn't yet trusted for this conversation.
class ToolReferenceConfirmationNeeded extends ToolExecutionResult {
  final String projectId;
  final String path;

  const ToolReferenceConfirmationNeeded(this.projectId, this.path);
}

/// The tool call failed: file not found, ambiguous/missing `edit_file`
/// match, path outside all known projects, permission error, etc.
class ToolError extends ToolExecutionResult {
  final String message;

  const ToolError(this.message);
}
