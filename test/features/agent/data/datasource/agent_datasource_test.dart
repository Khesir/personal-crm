import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/agent/data/datasource/agent_datasource.dart';
import 'package:crm/features/agent/domain/model/agent_event.dart';

void main() {
  late AgentDatasource ds;

  setUp(() => ds = AgentDatasource());

  test('parses text event', () {
    final event = ds.parseBlock('data: {"type":"text","text":"hello"}');
    expect(event, isA<AgentTextEvent>());
    expect((event as AgentTextEvent).text, 'hello');
  });

  test('parses thinking event', () {
    final event = ds.parseBlock('data: {"type":"thinking","text":"reasoning..."}');
    expect(event, isA<AgentThinkingEvent>());
    expect((event as AgentThinkingEvent).text, 'reasoning...');
  });

  test('parses tool_call event', () {
    final event = ds.parseBlock('data: {"type":"tool_call","tool":"read_file","input":{"path":"/tmp/x"}}');
    expect(event, isA<AgentToolCallEvent>());
    final e = event as AgentToolCallEvent;
    expect(e.tool, 'read_file');
    expect(e.input['path'], '/tmp/x');
  });

  test('parses tool_result event', () {
    final event = ds.parseBlock('data: {"type":"tool_result","tool":"read_file","output":"contents"}');
    expect(event, isA<AgentToolResultEvent>());
    final e = event as AgentToolResultEvent;
    expect(e.tool, 'read_file');
    expect(e.output, 'contents');
  });

  test('parses done event', () {
    final event = ds.parseBlock('data: {"type":"done","session_id":"abc123","success":true}');
    expect(event, isA<AgentDoneEvent>());
    final e = event as AgentDoneEvent;
    expect(e.sessionId, 'abc123');
    expect(e.success, true);
  });

  test('parses error event', () {
    final event = ds.parseBlock('data: {"type":"error","message":"something went wrong"}');
    expect(event, isA<AgentErrorEvent>());
    expect((event as AgentErrorEvent).message, 'something went wrong');
  });

  test('returns null for unknown type', () {
    final event = ds.parseBlock('data: {"type":"unknown"}');
    expect(event, isNull);
  });

  test('returns null for empty block', () {
    final event = ds.parseBlock('');
    expect(event, isNull);
  });

  test('returns null for block without data line', () {
    final event = ds.parseBlock('event: ping\n');
    expect(event, isNull);
  });

  test('parses multi-line SSE block (event + data lines)', () {
    final block = 'event: message\ndata: {"type":"text","text":"multi"}';
    final event = ds.parseBlock(block);
    expect(event, isA<AgentTextEvent>());
    expect((event as AgentTextEvent).text, 'multi');
  });

  group('REST methods against a real local HTTP server', () {
    late HttpServer server;
    late AgentDatasource restDs;
    String? lastPath;
    String? lastMethod;
    String? lastBody;
    dynamic Function(String path)? respond;

    setUp(() async {
      server = await HttpServer.bind('localhost', 0);
      restDs = AgentDatasource(port: server.port);
      server.listen((request) async {
        lastPath = request.uri.path;
        lastMethod = request.method;
        lastBody = await utf8.decoder.bind(request).join();
        final result = respond?.call(request.uri.path);
        if (result is _NotFound) {
          request.response.statusCode = 404;
          await request.response.close();
          return;
        }
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(result));
        await request.response.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('listSessions parses the sessions list from a real response', () async {
      respond = (_) => [
            {'id': 's1', 'title': 'Hello', 'created_at': '2026-01-01T00:00:00Z', 'updated_at': '2026-01-01T00:00:00Z'},
          ];
      final sessions = await restDs.listSessions();
      expect(lastPath, '/sessions');
      expect(sessions.single['id'], 's1');
    });

    test('getSessionMessages parses the messages list', () async {
      respond = (_) => {
            'messages': [
              {'role': 'user', 'content': 'Hi'},
              {'role': 'assistant', 'content': 'Hello'},
            ],
          };
      final messages = await restDs.getSessionMessages('s1');
      expect(lastPath, '/sessions/s1/messages');
      expect(messages.length, 2);
      expect(messages[0]['role'], 'user');
    });

    test('getSessionMessages throws AgentSessionNotFoundException on 404', () async {
      respond = (_) => const _NotFound();
      expect(
        () => restDs.getSessionMessages('missing'),
        throwsA(isA<AgentSessionNotFoundException>()),
      );
    });

    test('deleteSession sends DELETE to the right path', () async {
      respond = (_) => {'status': 'deleted'};
      await restDs.deleteSession('s1');
      expect(lastMethod, 'DELETE');
      expect(lastPath, '/sessions/s1');
    });

    test('listModels parses provider+models', () async {
      respond = (_) => {
            'provider': 'ollama',
            'models': [
              {'name': 'llama3.2', 'parameter_size': '3.2B'},
            ],
          };
      final result = await restDs.listModels();
      expect(lastPath, '/models');
      expect(result['provider'], 'ollama');
      expect((result['models'] as List).single['name'], 'llama3.2');
    });

    test('getConfig parses the config map', () async {
      respond = (_) => {'provider': 'ollama', 'model': 'llama3'};
      final config = await restDs.getConfig();
      expect(lastPath, '/config');
      expect(config['provider'], 'ollama');
    });

    test('setConfig POSTs the config body', () async {
      respond = (_) => {'status': 'ok'};
      await restDs.setConfig({'provider': 'ollama', 'model': 'qwen2.5:3b'});
      expect(lastMethod, 'POST');
      expect(lastPath, '/config');
      expect(jsonDecode(lastBody!)['model'], 'qwen2.5:3b');
    });
  });
}

class _NotFound {
  const _NotFound();
}
