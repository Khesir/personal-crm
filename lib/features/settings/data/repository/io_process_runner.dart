import 'dart:async';
import 'dart:io';

import '../../domain/repository/process_runner.dart';

/// Real [ProcessRunner] backed by [Process.run]/[Process.start].
class IoProcessRunner implements ProcessRunner {
  @override
  Future<ProcessResult> run(
    String executable,
    List<String> args, {
    bool runInShell = false,
  }) {
    return Process.run(executable, args, runInShell: runInShell);
  }

  @override
  Future<ProcessResult> runWithTimeout(
    String executable,
    List<String> args, {
    required String workingDirectory,
    required Duration timeout,
    bool runInShell = false,
  }) async {
    final process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
      runInShell: runInShell,
    );

    final stdoutFuture = process.stdout.transform(const SystemEncoding().decoder).join();
    final stderrFuture = process.stderr.transform(const SystemEncoding().decoder).join();

    final exitCode = await process.exitCode.timeout(timeout, onTimeout: () {
      process.kill();
      throw TimeoutException('Process timed out after $timeout', timeout);
    });

    final stdout = await stdoutFuture;
    final stderr = await stderrFuture;
    return ProcessResult(process.pid, exitCode, stdout, stderr);
  }
}
