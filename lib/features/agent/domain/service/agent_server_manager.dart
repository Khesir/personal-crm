import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AgentServerManager {
  static const int _port = 8765;
  static const Duration _pollInterval = Duration(milliseconds: 500);
  static const Duration _startTimeout = Duration(seconds: 15);

  Process? _process;
  bool _serverReady = false;
  bool _serverFailed = false;

  bool get isReady => _serverReady;
  bool get hasFailed => _serverFailed;

  Future<void> initialize() async {
    if (await _isAlreadyRunning()) {
      _serverReady = true;
      return;
    }
    await _spawnAndWait();
  }

  Future<void> shutdown() async {
    try {
      final client = HttpClient();
      final req = await client.post('localhost', _port, '/shutdown');
      await req.close();
      client.close();
    } catch (_) {}
    _process?.kill();
    _process = null;
  }

  Future<bool> _isAlreadyRunning() async {
    final pidFile = _pidFilePath();
    if (pidFile == null || !File(pidFile).existsSync()) return false;
    return _pollHealth(timeout: const Duration(seconds: 2));
  }

  Future<void> _spawnAndWait() async {
    final executable = _executablePath();
    if (executable == null) {
      _serverFailed = true;
      return;
    }

    try {
      _process = await Process.start(
        executable.first,
        executable.sublist(1),
        mode: ProcessStartMode.detachedWithStdio,
      );
    } catch (_) {
      _serverFailed = true;
      return;
    }

    if (kDebugMode) {
      _forwardLogs(_process!.stdout, 'agent');
      _forwardLogs(_process!.stderr, 'agent:err');
    }

    final ready = await _pollHealth(timeout: _startTimeout);
    if (ready) {
      _serverReady = true;
    } else {
      _serverFailed = true;
      _process?.kill();
      _process = null;
    }
  }

  Future<bool> _pollHealth({required Duration timeout}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await _checkHealth()) return true;
      await Future.delayed(_pollInterval);
    }
    return false;
  }

  Future<bool> _checkHealth() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 1);
      final req = await client.get('localhost', _port, '/health');
      final res = await req.close();
      client.close();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _forwardLogs(Stream<List<int>> source, String tag) {
    source.transform(utf8.decoder).transform(const LineSplitter()).listen(
      (line) => debugPrint('[$tag] $line'),
    );
  }

  String? _pidFilePath() {
    final appData = Platform.environment['APPDATA'];
    if (appData == null) return null;
    return '$appData\\Avyn\\agent\\agent.pid';
  }

  List<String>? _executablePath() {
    if (kDebugMode) {
      var dir = Directory.current;
      for (var i = 0; i < 3; i++) {
        final candidate = File('${dir.path}/agent/main.py');
        if (candidate.existsSync()) return ['python', '-u', candidate.path];
        dir = dir.parent;
      }
      return null;
    }
    final exePath = '${File(Platform.resolvedExecutable).parent.path}\\avyn-agent.exe';
    return [exePath];
  }
}
