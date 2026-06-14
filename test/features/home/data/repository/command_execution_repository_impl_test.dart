import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/data/repository/command_execution_repository_impl.dart';
import 'package:crm/features/home/domain/model/agent_loop_constants.dart';
import 'package:crm/features/home/domain/model/tool_execution_result.dart';
import 'package:crm/features/settings/domain/repository/process_runner.dart';

/// Fake [ProcessRunner] that returns a canned [ProcessResult] from
/// [runWithTimeout], or throws a [TimeoutException] if [timesOut] is true.
class FakeProcessRunner implements ProcessRunner {
  final ProcessResult result;
  final bool timesOut;

  String? lastExecutable;
  String? lastWorkingDirectory;
  Duration? lastTimeout;

  FakeProcessRunner(this.result, {this.timesOut = false});

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> args, {
    bool runInShell = false,
  }) async {
    return result;
  }

  @override
  Future<ProcessResult> runWithTimeout(
    String executable,
    List<String> args, {
    required String workingDirectory,
    required Duration timeout,
    bool runInShell = false,
  }) async {
    lastExecutable = executable;
    lastWorkingDirectory = workingDirectory;
    lastTimeout = timeout;
    if (timesOut) {
      throw TimeoutException('timed out');
    }
    return result;
  }
}

void main() {
  group('CommandExecutionRepositoryImpl', () {
    test('returns a ToolOutput with exit code, stdout, and stderr on success', () async {
      final runner = FakeProcessRunner(ProcessResult(0, 0, 'ok\n', ''));
      final repository = CommandExecutionRepositoryImpl(runner);

      final result = await repository.run('echo ok', workingDirectory: '/work/crm');

      expect(runner.lastExecutable, 'echo ok');
      expect(runner.lastWorkingDirectory, '/work/crm');
      expect(runner.lastTimeout, kRunCommandTimeout);
      expect(result, isA<ToolOutput>());
      expect((result as ToolOutput).text, 'Exit code: 0\n\nstdout:\nok\n\n\nstderr:\n');
    });

    test('returns a ToolError when the command times out', () async {
      final runner = FakeProcessRunner(ProcessResult(0, 0, '', ''), timesOut: true);
      final repository = CommandExecutionRepositoryImpl(runner);

      final result = await repository.run('sleep 100', workingDirectory: '/work/crm');

      expect(result, isA<ToolError>());
      expect((result as ToolError).message,
          'Command timed out after ${kRunCommandTimeout.inSeconds}s: sleep 100');
    });
  });
}
