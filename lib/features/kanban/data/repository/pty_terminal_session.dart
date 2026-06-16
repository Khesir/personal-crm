import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_pty/flutter_pty.dart';

import '../../domain/repository/terminal_session.dart';

/// Real [TerminalSession] backed by [Pty], spawning the platform's default
/// shell in [workingDirectory].
class PtyTerminalSession implements TerminalSession {
  final Pty _pty;

  PtyTerminalSession({
    required String workingDirectory,
    String? shellExecutable,
    List<String> shellArguments = const [],
    Map<String, String> extraEnv = const {},
  }) : _pty = _start(
          executable: shellExecutable ?? _defaultShellExecutable(),
          arguments: shellArguments,
          workingDirectory: workingDirectory,
          extraEnv: extraEnv,
        );

  static Pty _start({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    required Map<String, String> extraEnv,
  }) {
    final env = {
      ...Platform.environment,
      'TERM': 'xterm-256color',
      'COLORTERM': 'truecolor',
      ...extraEnv,
    };
    // flutter_pty does not quote the executable path in CreateProcessW's
    // lpCommandLine, so paths with spaces get split. Route through cmd.exe
    // which does its own quoting when passed as a /c argument.
    if (Platform.isWindows && executable.contains(' ') && arguments.isEmpty) {
      return Pty.start(
        'cmd.exe',
        arguments: ['/c', '"$executable"'],
        workingDirectory: workingDirectory,
        environment: env,
      );
    }
    return Pty.start(
      executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      environment: env,
    );
  }

  static String _defaultShellExecutable() {
    if (Platform.isWindows) {
      const pwsh = r'C:\Program Files\PowerShell\7\pwsh.exe';
      if (File(pwsh).existsSync()) return pwsh;
      return 'cmd.exe';
    }
    return Platform.environment['SHELL'] ?? '/bin/bash';
  }

  static List<ShellOption> availableShells() {
    if (!Platform.isWindows) {
      return [ShellOption(label: 'bash', executable: Platform.environment['SHELL'] ?? '/bin/bash')];
    }
    final shells = <ShellOption>[];
    const pwsh = r'C:\Program Files\PowerShell\7\pwsh.exe';
    if (File(pwsh).existsSync()) shells.add(ShellOption(label: 'pwsh', executable: pwsh));
    // Use bare 'wsl.exe' — full path with backslashes gets mangled by flutter_pty.
    // wsl.exe is always in System32 which is in PATH.
    if (File(r'C:\Windows\System32\wsl.exe').existsSync()) {
      shells.add(const ShellOption(label: 'bash (WSL)', executable: 'wsl.exe'));
    }
    final gitBash = _buildGitBashOption();
    if (gitBash != null) shells.add(gitBash);
    shells.add(const ShellOption(label: 'cmd', executable: 'cmd.exe'));
    return shells;
  }

  static ShellOption? _buildGitBashOption() {
    final gitBinDir = _gitBinDir();
    if (gitBinDir == null) return null;
    final fullPath = '$gitBinDir\\bash.exe';
    if (!File(fullPath).existsSync()) return null;

    const gitBashEnv = {
      'MSYSTEM': 'MINGW64',
      'CHERE_INVOKING': '1',
    };

    // If no spaces, pass the full path directly with login flags.
    if (!fullPath.contains(' ')) {
      return ShellOption(
        label: 'bash (Git)',
        executable: fullPath,
        arguments: const ['--login', '-i'],
        extraEnv: gitBashEnv,
      );
    }

    // Try 8.3 short path (no spaces, no wrapper needed).
    final short = _shortPath(fullPath);
    if (short != null) {
      return ShellOption(
        label: 'bash (Git)',
        executable: short,
        arguments: const ['--login', '-i'],
        extraEnv: gitBashEnv,
      );
    }

    // flutter_pty doesn't quote paths in CreateProcessW's lpCommandLine, so
    // spaces break the path. Route through cmd.exe which quotes properly.
    return ShellOption(
      label: 'bash (Git)',
      executable: 'cmd.exe',
      arguments: ['/c', '"$fullPath" --login -i'],
      extraEnv: gitBashEnv,
    );
  }

  static String? _gitBinDir() {
    // 1. Well-known short paths (no spaces).
    for (final dir in [r'C:\PROGRA~1\Git\bin', r'C:\PROGRA~2\Git\bin']) {
      if (Directory(dir).existsSync()) return dir;
    }
    // 2. Detect from PATH: look for …\Git\cmd, step up to …\Git\bin.
    final pathEnv = Platform.environment['PATH'] ?? '';
    for (final dir in pathEnv.split(';')) {
      if (dir.toLowerCase().endsWith(r'\git\cmd')) {
        final bin = '${dir.substring(0, dir.length - 4)}\\bin';
        if (Directory(bin).existsSync()) return bin;
      }
    }
    return null;
  }

  // Uses cmd's %~sI modifier to get an 8.3 path without spaces.
  // Returns null if 8.3 names are disabled on the volume.
  static String? _shortPath(String longPath) {
    if (!longPath.contains(' ')) return longPath;
    try {
      final result = Process.runSync(
        'cmd', ['/c', 'for %I in ("$longPath") do @echo %~sI'],
      );
      if (result.exitCode == 0) {
        final short = (result.stdout as String).trim();
        if (short.isNotEmpty && !short.contains(' ') && short != longPath) {
          return short;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Stream<Uint8List> get output => _pty.output;

  @override
  void write(Uint8List data) => _pty.write(data);

  @override
  void resize(int cols, int rows) => _pty.resize(rows, cols);

  @override
  void kill() => _pty.kill();
}
