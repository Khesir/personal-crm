import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/data/datasource/openai_compatible_datasource.dart';
import 'package:crm/features/home/domain/model/chat_message.dart';
import 'package:crm/features/home/domain/model/chat_stream_event.dart';
import 'package:crm/features/home/domain/model/tool_call.dart';
import 'package:crm/features/home/domain/model/tool_definition.dart';

/// A minimal [HttpClientAdapter] that returns a canned [ResponseBody] for
/// every request, computed by [handler]. Lets datasource tests exercise SSE
/// parsing and request-body construction without any real network calls.
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
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:1234'));
  dio.httpClientAdapter = _FakeAdapter(handler);
  return dio;
}

String _sseFrom(List<Map<String, dynamic>> chunks) {
  return '${chunks.map((c) => 'data: ${jsonEncode(c)}').join('\n\n')}\n\ndata: [DONE]\n\n';
}

void main() {
  group('OpenAiCompatibleDatasource.streamChat()', () {
    test('omits the tools key when tools is empty', () async {
      final body = _sseFrom([
        {
          'choices': [
            {'delta': {'content': 'Hello'}, 'finish_reason': null},
          ],
        },
        {
          'choices': [
            {'delta': {}, 'finish_reason': 'stop'},
          ],
        },
      ]);

      final dio = _dioWith((options) {
        expect(options.path, '/v1/chat/completions');
        expect((options.data as Map).containsKey('tools'), isFalse);
        return ResponseBody.fromString(
          body,
          200,
          headers: {Headers.contentTypeHeader: ['text/event-stream']},
        );
      });

      final events = await OpenAiCompatibleDatasource(dio)
          .streamChat(
            model: 'local-model',
            messages: [const ChatMessage(role: ChatRole.user, content: 'hi')],
          )
          .toList();

      expect(events, [isA<ChatStreamTextDelta>()]);
      expect((events.single as ChatStreamTextDelta).text, 'Hello');
    });

    test('includes a tools array in OpenAI function-calling shape when tools is non-empty', () async {
      final body = _sseFrom([
        {
          'choices': [
            {'delta': {}, 'finish_reason': 'stop'},
          ],
        },
      ]);

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
          body,
          200,
          headers: {Headers.contentTypeHeader: ['text/event-stream']},
        );
      });

      await OpenAiCompatibleDatasource(dio)
          .streamChat(
            model: 'local-model',
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

    test('reassembles multi-chunk delta.tool_calls fragments into a tool-calls-requested event', () async {
      final body = _sseFrom([
        {
          'choices': [
            {
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'id': 'call_abc123',
                    'type': 'function',
                    'function': {'name': 'read_file', 'arguments': ''},
                  },
                ],
              },
              'finish_reason': null,
            },
          ],
        },
        {
          'choices': [
            {
              'delta': {
                'tool_calls': [
                  {'index': 0, 'function': {'arguments': '{"path":'}},
                ],
              },
              'finish_reason': null,
            },
          ],
        },
        {
          'choices': [
            {
              'delta': {
                'tool_calls': [
                  {'index': 0, 'function': {'arguments': '"foo.dart"}'}},
                ],
              },
              'finish_reason': null,
            },
          ],
        },
        {
          'choices': [
            {'delta': {}, 'finish_reason': 'tool_calls'},
          ],
        },
      ]);

      final dio = _dioWith((options) {
        return ResponseBody.fromString(
          body,
          200,
          headers: {Headers.contentTypeHeader: ['text/event-stream']},
        );
      });

      final events = await OpenAiCompatibleDatasource(dio)
          .streamChat(
            model: 'local-model',
            messages: [const ChatMessage(role: ChatRole.user, content: 'read foo.dart')],
          )
          .toList();

      expect(events, hasLength(1));
      final toolCallsEvent = events.single as ChatStreamToolCallsRequested;
      expect(toolCallsEvent.toolCalls, hasLength(1));
      expect(toolCallsEvent.toolCalls[0].id, 'call_abc123');
      expect(toolCallsEvent.toolCalls[0].name, 'read_file');
      expect(toolCallsEvent.toolCalls[0].arguments, {'path': 'foo.dart'});
    });

    test('emits text deltas before the accumulated tool-calls-requested event', () async {
      final body = _sseFrom([
        {
          'choices': [
            {'delta': {'content': 'Sure, '}, 'finish_reason': null},
          ],
        },
        {
          'choices': [
            {'delta': {'content': 'let me check.'}, 'finish_reason': null},
          ],
        },
        {
          'choices': [
            {
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'id': 'call_0',
                    'type': 'function',
                    'function': {'name': 'read_file', 'arguments': '{"path":"foo.dart"}'},
                  },
                ],
              },
              'finish_reason': null,
            },
          ],
        },
        {
          'choices': [
            {'delta': {}, 'finish_reason': 'tool_calls'},
          ],
        },
      ]);

      final dio = _dioWith((options) {
        return ResponseBody.fromString(
          body,
          200,
          headers: {Headers.contentTypeHeader: ['text/event-stream']},
        );
      });

      final events = await OpenAiCompatibleDatasource(dio)
          .streamChat(
            model: 'local-model',
            messages: [const ChatMessage(role: ChatRole.user, content: 'read foo.dart')],
          )
          .toList();

      expect(events, hasLength(3));
      expect(events[0], isA<ChatStreamTextDelta>());
      expect((events[0] as ChatStreamTextDelta).text, 'Sure, ');
      expect(events[1], isA<ChatStreamTextDelta>());
      expect((events[1] as ChatStreamTextDelta).text, 'let me check.');
      final toolCallsEvent = events[2] as ChatStreamToolCallsRequested;
      expect(toolCallsEvent.toolCalls[0].name, 'read_file');
      expect(toolCallsEvent.toolCalls[0].arguments, {'path': 'foo.dart'});
    });

    test('serializes tool-role messages as {role: "tool", tool_call_id, content}', () async {
      final body = _sseFrom([
        {
          'choices': [
            {'delta': {'content': 'Done'}, 'finish_reason': 'stop'},
          ],
        },
      ]);

      final dio = _dioWith((options) {
        expect(options.data['messages'], [
          {'role': 'user', 'content': 'read foo.dart'},
          {'role': 'assistant', 'content': ''},
          {'role': 'tool', 'tool_call_id': 'call_0', 'content': 'file contents here'},
        ]);
        return ResponseBody.fromString(
          body,
          200,
          headers: {Headers.contentTypeHeader: ['text/event-stream']},
        );
      });

      await OpenAiCompatibleDatasource(dio)
          .streamChat(
            model: 'local-model',
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

    test('echoes an assistant message\'s tool_calls (with stringified arguments) ahead of the tool result', () async {
      final body = _sseFrom([
        {
          'choices': [
            {'delta': {'content': 'All done.'}, 'finish_reason': 'stop'},
          ],
        },
      ]);

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
                'function': {'name': 'read_file', 'arguments': '{"path":"foo.dart"}'},
              },
            ],
          },
          {'role': 'tool', 'tool_call_id': 'call_0', 'content': 'file contents here'},
        ]);
        return ResponseBody.fromString(
          body,
          200,
          headers: {Headers.contentTypeHeader: ['text/event-stream']},
        );
      });

      await OpenAiCompatibleDatasource(dio)
          .streamChat(
            model: 'local-model',
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

    test('regression: finish_reason "stop" with no tool_calls emits only text-delta events', () async {
      final body = _sseFrom([
        {
          'choices': [
            {'delta': {'content': 'Hello '}, 'finish_reason': null},
          ],
        },
        {
          'choices': [
            {'delta': {'content': 'world'}, 'finish_reason': null},
          ],
        },
        {
          'choices': [
            {'delta': {}, 'finish_reason': 'stop'},
          ],
        },
      ]);

      final dio = _dioWith((options) {
        return ResponseBody.fromString(
          body,
          200,
          headers: {Headers.contentTypeHeader: ['text/event-stream']},
        );
      });

      final events = await OpenAiCompatibleDatasource(dio)
          .streamChat(
            model: 'local-model',
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
