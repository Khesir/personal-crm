import '../model/tool_call.dart';
import '../model/tool_execution_result.dart';

/// Executes the v1 fixed file-tool set (`read_file`, `list_dir`, `grep`,
/// `write_file`, `edit_file`) against the filesystem, enforcing that reads
/// stay within the working project or a trusted/registered reference
/// project, and writes stay within the working project.
abstract class AgentToolRepository {
  /// Executes [call] and returns its result.
  ///
  /// - [workingProjectPath]: the conversation's working project root.
  ///   Relative `path` arguments resolve against this.
  /// - [trustedReferenceProjectPaths]: reference project roots the user has
  ///   already approved read access to for this conversation.
  /// - [registeredProjectPaths]: every registered project's local path,
  ///   mapped to its project id (including the working project). Used to
  ///   distinguish a path under a *registered but untrusted* reference
  ///   project (-> [ToolReferenceConfirmationNeeded]) from a path outside
  ///   all known project roots (-> [ToolError]).
  Future<ToolExecutionResult> execute(
    ToolCall call, {
    required String workingProjectPath,
    required List<String> trustedReferenceProjectPaths,
    required Map<String, String> registeredProjectPaths,
  });

  /// Applies a previously-returned [ToolWriteProposal] to disk — creating
  /// the file ([WriteFileCreation]) or replacing the matched text
  /// ([EditFileChange]) at [ToolWriteProposal.path] — and returns a
  /// [ToolOutput] confirming what was written, or a [ToolError] if the
  /// write fails (e.g. the file changed on disk since the proposal was
  /// made).
  Future<ToolExecutionResult> applyWrite(ToolWriteProposal proposal);
}
