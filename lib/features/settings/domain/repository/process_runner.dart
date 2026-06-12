import 'dart:io';

/// Abstraction over [Process.run], so hardware-detection logic that shells
/// out to `nvidia-smi`/`powershell` can be exercised with canned output in
/// tests.
abstract class ProcessRunner {
  Future<ProcessResult> run(String executable, List<String> args);
}
