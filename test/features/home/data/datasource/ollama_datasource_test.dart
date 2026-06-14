import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/data/datasource/ollama_datasource.dart';
import 'package:crm/features/home/domain/model/chat_message.dart';
import 'package:crm/features/home/domain/model/chat_stream_event.dart';
import 'package:crm/features/home/domain/model/tool_call.dart';
import 'package:crm/features/home/domain/model/tool_definition.dart';
import 'package:crm/features/home/domain/repository/chat_model_repository.dart';

/// A minimal [HttpClientAdapter] that returns a canned [ResponseBody] for
/// every request, computed by [handler]. Lets datasource tests exercise
/// NDJSON parsing and request-body construction without any real network
/// calls.
class _FakeAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;

  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(ResponseBody Function(RequestOptions options) handler) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:11434'));
  dio.httpClientAdapter = _FakeAdapter(handler);
  return dio;
}

void main() {
  group('OllamaDatasource.pullModel()', () {
    test('parses NDJSON progress lines and completes on {"status":"success"}', () async {
      final lines = [
        jsonEncode({'status': 'pulling manifest'}),
        jsonEncode({'status': 'pulling abc123', 'total': 1000, 'completed': 0}),
        jsonEncode({'status': 'pulling abc123', 'total': 1000, 'completed': 500}),
        jsonEncode({'status': 'pulling abc123', 'total': 1000, 'completed': 1000}),
        jsonEncode({'status': 'verifying sha256 digest'}),
        jsonEncode({'status': 'success'}),
      ];

      final dio = _dioWith((options) {
        expect(options.path, '/api/pull');
        expect(options.data, {'name': 'hf.co/TheBloke/Llama-2-7B-Chat-GGUF:Q4_K_M', 'stream': true});
        return ResponseBody.fromString(
          lines.join('\n'),
          200,
          headers: {Headers.contentTypeHeader: ['application/x-ndjson']},
        );
      });

      final progress = await OllamaDatasource(dio)
          .pullModel(name: 'hf.co/TheBloke/Llama-2-7B-Chat-GGUF:Q4_K_M')
          .toList();

      expect(progress, hasLength(6));
      expect(progress[0].status, 'pulling manifest');
      expect(progress[0].totalBytes, isNull);
      expect(progress[0].completedBytes, isNull);

      expect(progress[1].status, 'pulling abc123');
      expect(progress[1].totalBytes, 1000);
      expect(progress[1].completedBytes, 0);

      expect(progress[2].completedBytes, 500);
      expect(progress[3].completedBytes, 1000);

      expect(progress[4].status, 'verifying sha256 digest');

      expect(progress[5].status, 'success');
    });

    test('stops at the first {"status":"success"} line, ignoring anything after', () async {
      final lines = [
        jsonEncode({'status': 'pulling manifest'}),
        jsonEncode({'status': 'success'}),
        jsonEncode({'status': 'should not appear'}),
      ];

      final dio = _dioWith((options) {
        return ResponseBody.fromString(
          lines.join('\n'),
          200,
          headers: {Headers.contentTypeHeader: ['application/x-ndjson']},
        );
      });

      final progress = await OllamaDatasource(dio).pullModel(name: 'hf.co/foo/bar:Q4_K_M').toList();

      expect(progress.map((p) => p.status), ['pulling manifest', 'success']);
    });

    test('surfaces a mapped error message when the request fails', () async {
      final dio = _dioWith((options) {
        expect(options.path, '/api/pull');
        return ResponseBody.fromString(
          jsonEncode({'error': 'pull model manifest: file does not exist'}),
          404,
          headers: {Headers.contentTypeHeader: ['application/json']},
        );
      });

      final stream = OllamaDatasource(dio).pullModel(name: 'hf.co/missing/repo:Q4_K_M');

      await expectLater(
        stream,
        emitsError(isA<ChatRequestException>().having(
          (e) => e.message,
          'message',
          'pull model manifest: file does not exist',
        )),
      );
    });
  });

  group('OllamaDatasource.getModelCapabilities()', () {
    test('returns the capabilities array from POST /api/show', () async {
      final dio = _dioWith((options) {
        expect(options.path, '/api/show');
        expect(options.data, {'name': 'llama3.2'});
        return ResponseBody.fromString(
          jsonEncode({
            'capabilities': ['completion', 'tools'],
          }),
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        );
      });

      final capabilities = await OllamaDatasource(dio).getModelCapabilities('llama3.2');

      expect(capabilities, ['completion', 'tools']);
    });

    test('returns an empty list when capabilities is absent', () async {
      final dio = _dioWith((options) {
        return ResponseBody.fromString(
          jsonEncode({'modelfile': 'FROM llama3.2'}),
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        );
      });

      final capabilities = await OllamaDatasource(dio).getModelCapabilities('llama3.2');

      expect(capabilities, isEmpty);
    });
  });

  group('OllamaDatasource.streamChat()', () {
    test('omits the tools key when tools is empty', () async {
      final lines = [
        jsonEncode({
          'message': {'role': 'assistant', 'content': 'Hello'},
          'done': false,
        }),
        jsonEncode({
          'message': {'role': 'assistant', 'content': ''},
          'done': true,
        }),
      ];

      final dio = _dioWith((options) {
        expect(options.path, '/api/chat');
        expect(options.data['model'], 'llama3');
        expect((options.data as Map).containsKey('tools'), isFalse);
        return ResponseBody.fromString(
          lines.join('\n'),
          200,
          headers: {Headers.contentTypeHeader: ['application/x-ndjson']},
        );
      });

      final events = await OllamaDatasource(dio)
          .streamChat(
            model: 'llama3',
            messages: [const ChatMessage(role: ChatRole.user, content: 'hi')],
          )
          .toList();

      expect(events, [isA<ChatStreamTextDelta>()]);
      expect((events.single as ChatStreamTextDelta).text, 'Hello');
    });

    test('includes a tools array in Ollama function-calling shape when tools is non-empty', () async {
      final lines = [
        jsonEncode({
          'message': {'role': 'assistant', 'content': ''},
          'done': true,
        }),
      ];

      final dio = _dioWith((options) {
        expect(options.data['tools'], [
          {
            'type': 'function',
            'function': {
              'name': 'read_file',
              'description': 'Reads a file',
              'parameters': {
                'type': 'object',
                'properties': {
                  'path': {'type': 'string'},
                },
                'required': ['path'],
              },
            },
          },
        ]);
        return ResponseBody.fromString(
          lines.join('\n'),
          200,
          headers: {Headers.contentTypeHeader: ['application/x-ndjson']},
        );
      });

      await OllamaDatasource(dio)
          .streamChat(
            model: 'llama3',
            messages: [const ChatMessage(role: ChatRole.user, content: 'hi')],
            tools: const [
              ToolDefinition(
                name: 'read_file',
                description: 'Reads a file',
                parameters: {
                  'type': 'object',
                  'properties': {
                    'path': {'type': 'string'},
                  },
                  'required': ['path'],
                },
              ),
            ],
          )
          .toList();
    });

    test('parses message.tool_calls on the final chunk into a tool-calls-requested event', () async {
      final lines = [
        jsonEncode({
          'message': {'role': 'assistant', 'content': 'Sure, let me check.'},
          'done': false,
        }),
        jsonEncode({
          'message': {
            'role': 'assistant',
            'content': '',
            'tool_calls': [
              {
                'function': {
                  'name': 'read_file',
                  'arguments': {'path': 'foo.dart'},
                },
              },
            ],
          },
          'done': true,
        }),
      ];

      final dio = _dioWith((options) {
        return ResponseBody.fromString(
          lines.join('\n'),
          200,
          headers: {Headers.contentTypeHeader: ['application/x-ndjson']},
        );
      });

      final events = await OllamaDatasource(dio)
          .streamChat(
            model: 'llama3',
            messages: [const ChatMessage(role: ChatRole.user, content: 'read foo.dart')],
          )
          .toList();

      expect(events, hasLength(2));
      expect(events[0], isA<ChatStreamTextDelta>());
      expect((events[0] as ChatStreamTextDelta).text, 'Sure, let me check.');

      final toolCallsEvent = events[1] as ChatStreamToolCallsRequested;
      expect(toolCallsEvent.toolCalls, hasLength(1));
      expect(toolCallsEvent.toolCalls[0].id, 'call_0');
      expect(toolCallsEvent.toolCalls[0].name, 'read_file');
      expect(toolCallsEvent.toolCalls[0].arguments, {'path': 'foo.dart'});
    });

    test('serializes tool-role messages with role "tool"', () async {
      final lines = [
        jsonEncode({
          'message': {'role': 'assistant', 'content': 'Done'},
          'done': true,
        }),
      ];

      final dio = _dioWith((options) {
        expect(options.data['messages'], [
          {'role': 'user', 'content': 'read foo.dart'},
          {'role': 'assistant', 'content': ''},
          {'role': 'tool', 'content': 'file contents here'},
        ]);
        return ResponseBody.fromString(
          lines.join('\n'),
          200,
          headers: {Headers.contentTypeHeader: ['application/x-ndjson']},
        );
      });

      await OllamaDatasource(dio)
          .streamChat(
            model: 'llama3',
            messages: [
              const ChatMessage(role: ChatRole.user, content: 'read foo.dart'),
              const ChatMessage(role: ChatRole.assistant, content: ''),
              const ChatMessage(
                role: ChatRole.tool,
                content: 'file contents here',
                toolCallId: 'call_0',
                toolName: 'read_file',
              ),
            ],
          )
          .toList();
    });

    test('echoes an assistant message\'s tool_calls (with object arguments) ahead of the tool result', () async {
      final lines = [
        jsonEncode({
          'message': {'role': 'assistant', 'content': 'All done.'},
          'done': true,
        }),
      ];

      final dio = _dioWith((options) {
        expect(options.data['messages'], [
          {'role': 'user', 'content': 'read foo.dart'},
          {
            'role': 'assistant',
            'content': '',
            'tool_calls': [
              {
                'id': 'call_0',
                'type': 'function',
                'function': {
                  'name': 'read_file',
                  'arguments': {'path': 'foo.dart'},
                },
              },
            ],
          },
          {'role': 'tool', 'content': 'file contents here'},
        ]);
        return ResponseBody.fromString(
          lines.join('\n'),
          200,
          headers: {Headers.contentTypeHeader: ['application/x-ndjson']},
        );
      });

      await OllamaDatasource(dio)
          .streamChat(
            model: 'llama3',
            messages: [
              const ChatMessage(role: ChatRole.user, content: 'read foo.dart'),
              const ChatMessage(
                role: ChatRole.assistant,
                content: '',
                toolCalls: [
                  ToolCall(id: 'call_0', name: 'read_file', arguments: {'path': 'foo.dart'}),
                ],
              ),
              const ChatMessage(
                role: ChatRole.tool,
                content: 'file contents here',
                toolCallId: 'call_0',
                toolName: 'read_file',
              ),
            ],
          )
          .toList();
    });

    test('regression: response with no tool_calls emits only text-delta events', () async {
      final lines = [
        jsonEncode({
          'message': {'role': 'assistant', 'content': 'Hello '},
          'done': false,
        }),
        jsonEncode({
          'message': {'role': 'assistant', 'content': 'world'},
          'done': false,
        }),
        jsonEncode({
          'message': {'role': 'assistant', 'content': ''},
          'done': true,
        }),
      ];

      final dio = _dioWith((options) {
        return ResponseBody.fromString(
          lines.join('\n'),
          200,
          headers: {Headers.contentTypeHeader: ['application/x-ndjson']},
        );
      });

      final events = await OllamaDatasource(dio)
          .streamChat(
            model: 'llama3',
            messages: [const ChatMessage(role: ChatRole.user, content: 'hi')],
          )
          .toList();

      expect(events, hasLength(2));
      expect(events, everyElement(isA<ChatStreamTextDelta>()));
      expect((events[0] as ChatStreamTextDelta).text, 'Hello ');
      expect((events[1] as ChatStreamTextDelta).text, 'world');
    });
  });
}
