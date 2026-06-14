import '../model/tool_execution_result.dart';

/// Executes the `run_command` agent tool: a single shell command line,
/// scoped to the conversation's working project directory.
abstract class CommandExecutionRepository {
  /// Runs [command] in [workingDirectory] and returns a [ToolOutput]
  /// containing the exit code, stdout, and stderr, or a [ToolError] if the
  /// command times out.
  Future<ToolExecutionResult> run(String command, {required String workingDirectory});
}
