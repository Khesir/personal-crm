import 'dart:io';

import '../../domain/repository/process_runner.dart';

/// Real [ProcessRunner] backed by [Process.run].
class IoProcessRunner implements ProcessRunner {
  @override
  Future<ProcessResult> run(
    String executable,
    List<String> args, {
    bool runInShell = false,
  }) {
    return Process.run(executable, args, runInShell: runInShell);
  }
}
