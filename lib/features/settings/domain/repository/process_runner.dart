import 'dart:io';

/// Abstraction over [Process.run]/[Process.start], so hardware-detection
/// logic that shells out to `nvidia-smi`/`powershell`, and agent-mode
/// command execution, can be exercised with canned output in tests.
abstract class ProcessRunner {
  Future<ProcessResult> run(
    String executable,
    List<String> args, {
    bool runInShell = false,
  });

  /// Runs [executable] with [args] in [workingDirectory], capturing
  /// stdout/stderr/exit code. If the process hasn't completed within
  /// [timeout], it is killed and a [TimeoutException] is thrown.
  Future<ProcessResult> runWithTimeout(
    String executable,
    List<String> args, {
    required String workingDirectory,
    required Duration timeout,
    bool runInShell = false,
  });
}
