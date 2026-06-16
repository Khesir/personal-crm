import 'dart:typed_data';

class ShellOption {
  final String label;
  final String executable;
  final List<String> arguments;
  final Map<String, String> extraEnv;

  const ShellOption({
    required this.label,
    required this.executable,
    this.arguments = const [],
    this.extraEnv = const {},
  });
}

/// Abstraction over a PTY-backed shell process, so the terminal session
/// controller can be exercised without a real `flutter_pty` process.
abstract class TerminalSession {
  /// Raw output bytes produced by the shell.
  Stream<Uint8List> get output;

  /// Writes [data] to the shell's stdin.
  void write(Uint8List data);

  /// Resizes the underlying pseudo-terminal.
  void resize(int cols, int rows);

  /// Terminates the shell process.
  void kill();
}
