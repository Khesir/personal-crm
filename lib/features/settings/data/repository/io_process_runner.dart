import 'dart:io';

import '../../domain/repository/process_runner.dart';

/// Real [ProcessRunner] backed by [Process.run].
class IoProcessRunner implements ProcessRunner {
  @override
  Future<ProcessResult> run(String executable, List<String> args) {
    return Process.run(executable, args);
  }
}
