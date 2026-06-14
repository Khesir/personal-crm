import '../../domain/model/tool_call.dart';
import '../../domain/model/tool_execution_result.dart';

/// Tool names whose calls can be left pending as a [ToolWriteProposal] for
/// user approval. All other tools execute immediately in the agent loop.
const _writeToolNames = {'write_file', 'edit_file'};

/// Whether [toolName] is a `write_file`/`edit_file` call — the only tools
/// that can produce a [ToolWriteProposal] pending approval.
bool isWriteOrEditTool(String toolName) => _writeToolNames.contains(toolName);

/// A short, one-line summary of [call] for a step card's collapsed state.
///
/// `read_file`/`list_dir`/`write_file`/`edit_file` show the `path` argument;
/// `grep` shows the `pattern` argument; `web_search` shows the `query`
/// argument; `run_command` shows the `command` argument; `fetch_page` shows
/// the `url` argument.
String toolCallSummary(ToolCall call) {
  switch (call.name) {
    case 'grep':
      final pattern = call.arguments['pattern'] as String?;
      return pattern ?? '';
    case 'web_search':
      final query = call.arguments['query'] as String?;
      return query ?? '';
    case 'run_command':
      final command = call.arguments['command'] as String?;
      return command ?? '';
    case 'fetch_page':
      final url = call.arguments['url'] as String?;
      return url ?? '';
    default:
      final path = call.arguments['path'] as String?;
      return path ?? '';
  }
}

/// Builds the [ToolWritePreview] for a pending `write_file`/`edit_file`
/// [call] directly from its persisted [ToolCall.arguments] — no repository
/// call needed, since the proposal's shape is fully determined by the
/// requested arguments.
///
/// Returns `null` for tools other than `write_file`/`edit_file`.
ToolWritePreview? toolCallWritePreview(ToolCall call) {
  switch (call.name) {
    case 'write_file':
      final content = call.arguments['content'] as String? ?? '';
      return WriteFileCreation(content);
    case 'edit_file':
      final oldText = call.arguments['old_text'] as String? ?? '';
      final newText = call.arguments['new_text'] as String? ?? '';
      return EditFileChange(oldText, newText);
    default:
      return null;
  }
}
