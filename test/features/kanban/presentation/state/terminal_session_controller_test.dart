import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/kanban/domain/repository/terminal_session.dart';
import 'package:crm/features/kanban/presentation/state/terminal_session_controller.dart';

class FakeTerminalSession implements TerminalSession {
  final String workingDirectory;
  final _outputController = StreamController<Uint8List>.broadcast();
  final List<Uint8List> written = [];
  bool killed = false;

  FakeTerminalSession({required this.workingDirectory});

  @override
  Stream<Uint8List> get output => _outputController.stream;

  @override
  void write(Uint8List data) => written.add(data);

  @override
  void resize(int cols, int rows) {}

  @override
  void kill() => killed = true;
}

void main() {
  group('TerminalSessionController', () {
    late List<FakeTerminalSession> createdSessions;
    late TerminalSessionController controller;

    setUp(() {
      createdSessions = [];
      controller = TerminalSessionController(
        workingDirectory: '/repo/project-a',
        sessionFactory: ({required workingDirectory, String? shellExecutable, List<String> shellArguments = const [], Map<String, String> extraEnv = const {}}) {
          final session = FakeTerminalSession(workingDirectory: workingDirectory);
          createdSessions.add(session);
          return session;
        },
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('starts with no sessions and no active tab', () {
      expect(controller.state.tabs, isEmpty);
      expect(controller.state.activeTabId, isNull);
      expect(controller.state.activeTab, isNull);
    });

    test('createSession adds a tab and makes it active', () {
      final tab = controller.createSession();

      expect(controller.state.tabs, hasLength(1));
      expect(controller.state.activeTabId, tab.id);
      expect(controller.state.activeTab, tab);
    });

    test('new sessions use the project localPath as their working directory', () {
      controller.createSession();

      expect(createdSessions, hasLength(1));
      expect(createdSessions.first.workingDirectory, '/repo/project-a');
    });

    test('createSession can create multiple tabs, each backed by its own session', () {
      final first = controller.createSession();
      final second = controller.createSession();

      expect(controller.state.tabs, hasLength(2));
      expect(first.id, isNot(second.id));
      expect(controller.state.activeTabId, second.id);
      expect(createdSessions, hasLength(2));
    });

    test('switchTab changes the active tab', () {
      final first = controller.createSession();
      final second = controller.createSession();

      controller.switchTab(first.id);

      expect(controller.state.activeTabId, first.id);
      expect(controller.state.activeTab, first);
      expect(second.id, isNotNull);
    });

    test('switchTab is a no-op for an unknown tab id', () {
      final first = controller.createSession();

      controller.switchTab('does-not-exist');

      expect(controller.state.activeTabId, first.id);
    });

    test('dispose kills all sessions', () {
      controller.createSession();
      controller.createSession();

      controller.dispose();

      expect(createdSessions.every((session) => session.killed), isTrue);
    });
  });
}
