import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/agent/domain/model/agent_chat_message.dart';
import 'package:crm/features/agent/domain/model/agent_event.dart';
import 'package:crm/features/agent/domain/model/agent_models_result.dart';
import 'package:crm/features/agent/domain/model/agent_server_status.dart';
import 'package:crm/features/agent/domain/model/agent_session_summary.dart';
import 'package:crm/features/agent/domain/model/agent_status.dart';
import 'package:crm/features/agent/domain/repository/agent_repository.dart';
import 'package:crm/features/agent/domain/controller/agent_controller.dart';

class FakeAgentRepository extends AgentRepository {
  final List<AgentEvent> events;
  List<AgentSessionSummary> sessions = [];
  Map<String, List<AgentChatMessage>> messagesBySession = {};
  AgentModelsResult modelsResult = const AgentModelsResult(provider: 'ollama', models: []);
  Map<String, dynamic> config = {'provider': 'ollama', 'model': 'llama3'};
  final List<String> deletedSessionIds = [];
  final List<Map<String, dynamic>> setConfigCalls = [];

  FakeAgentRepository(this.events);

  @override
  Stream<AgentEvent> chat({
    required String? sessionId,
    required String message,
    String? localPath,
  }) async* {
    for (final event in events) {
      yield event;
    }
  }

  @override
  Future<List<AgentSessionSummary>> listSessions() async => sessions;

  @override
  Future<List<AgentChatMessage>> getSessionMessages(String sessionId) async =>
      messagesBySession[sessionId] ?? [];

  @override
  Future<void> deleteSession(String sessionId) async {
    deletedSessionIds.add(sessionId);
    sessions = sessions.where((s) => s.id != sessionId).toList();
  }

  @override
  Future<AgentModelsResult> listModels() async => modelsResult;

  @override
  Future<Map<String, dynamic>> getConfig() async => config;

  @override
  Future<void> setConfig(Map<String, dynamic> newConfig) async {
    setConfigCalls.add(newConfig);
    config = newConfig;
  }
}

void main() {
  test('starts idle', () {
    final controller = AgentController(FakeAgentRepository([]));
    expect(controller.state.status, AgentStatus.idle);
    expect(controller.state.events, isEmpty);
  });

  test('transitions to running then done on success', () async {
    final repo = FakeAgentRepository([
      const AgentTextEvent('hello'),
      const AgentDoneEvent(sessionId: 'abc', success: true),
    ]);
    final controller = AgentController(repo);

    final statuses = <AgentStatus>[];
    final sub = controller.stream.listen((s) => statuses.add(s.status));

    await controller.sendMessage('test');
    await sub.cancel();

    expect(statuses, contains(AgentStatus.running));
    expect(controller.state.status, AgentStatus.done);
    expect(controller.state.sessionId, 'abc');
  });

  test('appends events as stream emits', () async {
    final repo = FakeAgentRepository([
      const AgentTextEvent('word1'),
      const AgentTextEvent('word2'),
      const AgentDoneEvent(success: true),
    ]);
    final controller = AgentController(repo);

    await controller.sendMessage('test');

    final textEvents = controller.state.events.whereType<AgentTextEvent>().toList();
    expect(textEvents.length, 2);
    expect(textEvents[0].text, 'word1');
    expect(textEvents[1].text, 'word2');
  });

  test('does not re-enter running state while already running', () async {
    var callCount = 0;
    final repo = _CountingRepo(() {
      callCount++;
      return Stream.fromIterable([const AgentDoneEvent(success: true)]);
    });
    final controller = AgentController(repo);

    final f1 = controller.sendMessage('a');
    controller.sendMessage('b');
    await f1;

    expect(callCount, 1);
  });

  test('sets status to error on repository exception', () async {
    final repo = _ThrowingRepo();
    final controller = AgentController(repo);

    await controller.sendMessage('test');

    expect(controller.state.status, AgentStatus.error);
    expect(controller.state.events.last, isA<AgentErrorEvent>());
  });

  test('setServerStatus transitions serverStatus correctly', () {
    final controller = AgentController(FakeAgentRepository([]));
    expect(controller.state.serverStatus, AgentServerStatus.unknown);

    controller.setServerStatus(AgentServerStatus.starting);
    expect(controller.state.serverStatus, AgentServerStatus.starting);

    controller.setServerStatus(AgentServerStatus.ready);
    expect(controller.state.serverStatus, AgentServerStatus.ready);

    controller.setServerStatus(AgentServerStatus.failed);
    expect(controller.state.serverStatus, AgentServerStatus.failed);
  });

  test('setWorkingProject sets name and path', () {
    final controller = AgentController(FakeAgentRepository([]));
    controller.setWorkingProject('MyApp', '/home/user/myapp');
    expect(controller.state.workingProjectName, 'MyApp');
    expect(controller.state.localPath, '/home/user/myapp');
  });

  test('setWorkingProject(null, null) clears project', () {
    final controller = AgentController(FakeAgentRepository([]));
    controller.setWorkingProject('MyApp', '/home/user/myapp');
    controller.setWorkingProject(null, null);
    expect(controller.state.workingProjectName, isNull);
    expect(controller.state.localPath, isNull);
  });

  test('reset clears events and status but keeps sessionId', () async {
    final repo = FakeAgentRepository([
      const AgentDoneEvent(sessionId: 'sess1', success: true),
    ]);
    final controller = AgentController(repo);
    await controller.sendMessage('test');

    controller.reset();

    expect(controller.state.events, isEmpty);
    expect(controller.state.status, AgentStatus.idle);
    expect(controller.state.sessionId, 'sess1');
  });

  test('sendMessage refreshes sessions when a new session is created', () async {
    final repo = FakeAgentRepository([
      const AgentDoneEvent(sessionId: 'new-session', success: true),
    ]);
    repo.sessions = [
      AgentSessionSummary(
        id: 'new-session',
        title: 'test',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    ];
    final controller = AgentController(repo);

    await controller.sendMessage('test');

    expect(controller.state.sessions.map((s) => s.id), contains('new-session'));
  });

  test('loadSessions populates state.sessions and clears sessionsLoading', () async {
    final repo = FakeAgentRepository([]);
    repo.sessions = [
      AgentSessionSummary(
        id: 's1',
        title: 'Hello',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    ];
    final controller = AgentController(repo);

    await controller.loadSessions();

    expect(controller.state.sessions.length, 1);
    expect(controller.state.sessions.first.id, 's1');
    expect(controller.state.sessionsLoading, isFalse);
  });

  test('newChat clears sessionId, events, and status — unlike reset()', () async {
    final repo = FakeAgentRepository([
      const AgentDoneEvent(sessionId: 'sess1', success: true),
    ]);
    final controller = AgentController(repo);
    await controller.sendMessage('test');
    expect(controller.state.sessionId, 'sess1');

    controller.newChat();

    expect(controller.state.sessionId, isNull);
    expect(controller.state.events, isEmpty);
    expect(controller.state.status, AgentStatus.idle);
  });

  test('resumeSession maps history into events with correct user/assistant distinction', () async {
    final repo = FakeAgentRepository([]);
    repo.messagesBySession['s1'] = [
      const AgentChatMessage(role: AgentChatRole.user, content: 'Hi'),
      const AgentChatMessage(role: AgentChatRole.assistant, content: 'Hello there'),
    ];
    final controller = AgentController(repo);

    await controller.resumeSession('s1');

    expect(controller.state.sessionId, 's1');
    expect(controller.state.resumingSession, isFalse);
    expect(controller.state.events[0], isA<AgentUserMessageEvent>());
    expect((controller.state.events[0] as AgentUserMessageEvent).text, 'Hi');
    expect(controller.state.events[1], isA<AgentTextEvent>());
    expect((controller.state.events[1] as AgentTextEvent).text, 'Hello there');
  });

  test('deleteSession removes the session from state.sessions', () async {
    final repo = FakeAgentRepository([]);
    repo.sessions = [
      AgentSessionSummary(id: 's1', title: 'a', createdAt: DateTime(2026), updatedAt: DateTime(2026)),
      AgentSessionSummary(id: 's2', title: 'b', createdAt: DateTime(2026), updatedAt: DateTime(2026)),
    ];
    final controller = AgentController(repo);
    await controller.loadSessions();

    await controller.deleteSession('s1');

    expect(controller.state.sessions.map((s) => s.id), ['s2']);
    expect(repo.deletedSessionIds, ['s1']);
  });

  test('deleteSession calls newChat() when deleting the currently active session', () async {
    final repo = FakeAgentRepository([
      const AgentDoneEvent(sessionId: 's1', success: true),
    ]);
    repo.sessions = [
      AgentSessionSummary(id: 's1', title: 'a', createdAt: DateTime(2026), updatedAt: DateTime(2026)),
    ];
    final controller = AgentController(repo);
    await controller.sendMessage('test');
    expect(controller.state.sessionId, 's1');

    await controller.deleteSession('s1');

    expect(controller.state.sessionId, isNull);
    expect(controller.state.events, isEmpty);
  });

  test('deleteSession does NOT reset state when deleting a different session', () async {
    final repo = FakeAgentRepository([
      const AgentDoneEvent(sessionId: 's1', success: true),
    ]);
    repo.sessions = [
      AgentSessionSummary(id: 's1', title: 'a', createdAt: DateTime(2026), updatedAt: DateTime(2026)),
      AgentSessionSummary(id: 's2', title: 'b', createdAt: DateTime(2026), updatedAt: DateTime(2026)),
    ];
    final controller = AgentController(repo);
    await controller.sendMessage('test');

    await controller.deleteSession('s2');

    expect(controller.state.sessionId, 's1');
    expect(controller.state.events, isNotEmpty);
  });

  test('loadModels populates modelsResult and defaults selectedModel to the first model', () async {
    final repo = FakeAgentRepository([]);
    repo.modelsResult = const AgentModelsResult(
      provider: 'ollama',
      models: [
        AgentModelInfo(name: 'llama3.2', parameterSize: '3.2B'),
        AgentModelInfo(name: 'qwen2.5:3b', parameterSize: '3.1B'),
      ],
    );
    final controller = AgentController(repo);

    await controller.loadModels();

    expect(controller.state.modelsResult?.provider, 'ollama');
    expect(controller.state.selectedModel, 'llama3.2');
  });

  test('selectModel updates selectedModel without affecting other state', () async {
    final repo = FakeAgentRepository([]);
    final controller = AgentController(repo);
    controller.setWorkingProject('MyApp', '/home/user/myapp');

    await controller.selectModel('qwen2.5:3b');

    expect(controller.state.selectedModel, 'qwen2.5:3b');
    expect(controller.state.workingProjectName, 'MyApp');
    expect(repo.setConfigCalls.single['model'], 'qwen2.5:3b');
  });
}

class _CountingRepo extends AgentRepository {
  final Stream<AgentEvent> Function() factory;
  _CountingRepo(this.factory);

  @override
  Stream<AgentEvent> chat({
    required String? sessionId,
    required String message,
    String? localPath,
  }) =>
      factory();

  @override
  Future<List<AgentSessionSummary>> listSessions() async => [];

  @override
  Future<List<AgentChatMessage>> getSessionMessages(String sessionId) async => [];

  @override
  Future<void> deleteSession(String sessionId) async {}

  @override
  Future<AgentModelsResult> listModels() async =>
      const AgentModelsResult(provider: 'ollama', models: []);

  @override
  Future<Map<String, dynamic>> getConfig() async => {};

  @override
  Future<void> setConfig(Map<String, dynamic> config) async {}
}

class _ThrowingRepo extends AgentRepository {
  @override
  Stream<AgentEvent> chat({
    required String? sessionId,
    required String message,
    String? localPath,
  }) =>
      Stream.error(Exception('connection refused'));

  @override
  Future<List<AgentSessionSummary>> listSessions() async => [];

  @override
  Future<List<AgentChatMessage>> getSessionMessages(String sessionId) async => [];

  @override
  Future<void> deleteSession(String sessionId) async {}

  @override
  Future<AgentModelsResult> listModels() async =>
      const AgentModelsResult(provider: 'ollama', models: []);

  @override
  Future<Map<String, dynamic>> getConfig() async => {};

  @override
  Future<void> setConfig(Map<String, dynamic> config) async {}
}
