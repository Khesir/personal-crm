import 'dart:async';

import 'package:crm/features/settings/domain/repository/process_runner.dart';

import '../../domain/model/agent_loop_constants.dart';
import '../../domain/model/tool_execution_result.dart';
import '../../domain/repository/command_execution_repository.dart';

/// Runs `run_command` shell commands via [ProcessRunner.runWithTimeout],
/// killing the process and returning a [ToolError] if [kRunCommandTimeout]
/// is exceeded.
class CommandExecutionRepositoryImpl implements CommandExecutionRepository {
  final ProcessRunner processRunner;

  const CommandExecutionRepositoryImpl(this.processRunner);

  @override
  Future<ToolExecutionResult> run(String command, {required String workingDirectory}) async {
    try {
      final result = await processRunner.runWithTimeout(
        command,
        const [],
        workingDirectory: workingDirectory,
        timeout: kRunCommandTimeout,
        runInShell: true,
      );
      return ToolOutput(
        'Exit code: ${result.exitCode}\n\nstdout:\n${result.stdout}\n\nstderr:\n${result.stderr}',
      );
    } on TimeoutException {
      return ToolError('Command timed out after ${kRunCommandTimeout.inSeconds}s: $command');
    }
  }
}
