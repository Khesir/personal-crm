import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/data/datasource/anthropic_datasource.dart';
import 'package:crm/features/home/domain/model/chat_message.dart';
import 'package:crm/features/home/domain/model/chat_stream_event.dart';
import 'package:crm/features/home/domain/model/tool_call.dart';
import 'package:crm/features/home/domain/model/tool_definition.dart';
import 'package:crm/features/home/domain/repository/chat_model_repository.dart';

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
  final dio = Dio(BaseOptions(baseUrl: 'https://api.anthropic.com'));
  dio.httpClientAdapter = _FakeAdapter(handler);
  return dio;
}

const _anthropicSse = '''
event: message_start
data: {"type":"message_start","message":{"id":"msg_1","model":"claude-3-5-sonnet-20241022"}}

event: content_block_start
data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":" world"}}

event: content_block_stop
data: {"type":"content_block_stop","index":0}

event: message_delta
data: {"type":"message_delta","delta":{"stop_reason":"end_turn"}}

event: message_stop
data: {"type":"message_stop"}

''';

void main() {
  group('AnthropicDatasource', () {
    test('listModels() returns model ids from the {data: [...]} response shape', () async {
      final dio = _dioWith((options) {
        expect(options.path, '/v1/models');
        return ResponseBody.fromString(
          jsonEncode({
            'data': [
              {'id': 'claude-3-5-sonnet-20241022'},
              {'id': 'claude-3-opus-20240229'},
            ],
          }),
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        );
      });

      final models = await AnthropicDatasource(dio).listModels();

      expect(models, ['claude-3-5-sonnet-20241022', 'claude-3-opus-20240229']);
    });

    test('streamChat() emits text deltas from content_block_delta events and stops at message_stop', () async {
      final dio = _dioWith((options) {
        expect(options.path, '/v1/messages');
        return ResponseBody.fromString(
          _anthropicSse,
          200,
          headers: {Headers.contentTypeHeader: ['text/event-stream']},
        );
      });

      final events = await AnthropicDatasource(dio)
          .streamChat(model: 'claude-3-5-sonnet-20241022', messages: const [
        ChatMessage(role: ChatRole.user, content: 'Hi'),
      ]).toList();

      expect(events, [
        isA<ChatStreamTextDelta>().having((e) => e.text, 'text', 'Hello'),
        isA<ChatStreamTextDelta>().having((e) => e.text, 'text', ' world'),
      ]);
    });

    test('streamChat() sends model, max_tokens, stream and the conversation messages', () async {
      late Map<String, dynamic> sentBody;
      final dio = _dioWith((options) {
        sentBody = options.data as Map<String, dynamic>;
        return ResponseBody.fromString(
          _anthropicSse,
          200,
          headers: {Headers.contentTypeHeader: ['text/event-stream']},
        );
      });

      await AnthropicDatasource(dio).streamChat(model: 'claude-3-5-sonnet-20241022', messages: const [
        ChatMessage(role: ChatRole.user, content: 'Hi'),
        ChatMessage(role: ChatRole.assistant, content: 'Hello!'),
      ]).toList();

      expect(sentBody['model'], 'claude-3-5-sonnet-20241022');
      expect(sentBody['max_tokens'], 4096);
      expect(sentBody['stream'], true);
      expect(sentBody['messages'], [
        {'role': 'user', 'content': 'Hi'},
        {'role': 'assistant', 'content': 'Hello!'},
      ]);
      expect(sentBody.containsKey('system'), isFalse);
    });

    test('streamChat() surfaces the provider\'s error message when the request fails', () async {
      final dio = _dioWith((options) {
        expect(options.path, '/v1/messages');
        return ResponseBody.fromString(
          jsonEncode({
            'type': 'error',
            'error': {
              'type': 'invalid_request_error',
              'message':
                  'Your credit balance is too low to access the Anthropic API. Please go to Plans & Billing to upgrade or purchase credits.',
            },
          }),
          400,
          headers: {Headers.contentTypeHeader: ['application/json']},
        );
      });

      final stream = AnthropicDatasource(dio).streamChat(model: 'claude-fable-5', messages: const [
        ChatMessage(role: ChatRole.user, content: 'Hi'),
      ]);

      await expectLater(
        stream,
        emitsError(isA<ChatRequestException>().having(
          (e) => e.message,
          'message',
          'Your credit balance is too low to access the Anthropic API. Please go to Plans & Billing to upgrade or purchase credits.',
        )),
      );
    });

    test('streamChat() moves system-role messages into a top-level system field', () async {
      late Map<String, dynamic> sentBody;
      final dio = _dioWith((options) {
        sentBody = options.data as Map<String, dynamic>;
        return ResponseBody.fromString(
          _anthropicSse,
          200,
          headers: {Headers.contentTypeHeader: ['text/event-stream']},
        );
      });

      await AnthropicDatasource(dio).streamChat(model: 'claude-3-5-sonnet-20241022', messages: const [
        ChatMessage(role: ChatRole.system, content: 'Be concise.'),
        ChatMessage(role: ChatRole.user, content: 'Hi'),
      ]).toList();

      expect(sentBody['system'], 'Be concise.');
      expect(sentBody['messages'], [
        {'role': 'user', 'content': 'Hi'},
      ]);
    });

    test('streamChat() omits the tools key when tools is empty', () async {
      late Map<String, dynamic> sentBody;
      final dio = _dioWith((options) {
        sentBody = options.data as Map<String, dynamic>;
        return ResponseBody.fromString(
          _anthropicSse,
          200,
          headers: {Headers.contentTypeHeader: ['text/event-stream']},
        );
      });

      await AnthropicDatasource(dio).streamChat(model: 'claude-3-5-sonnet-20241022', messages: const [
        ChatMessage(role: ChatRole.user, content: 'Hi'),
      ]).toList();

      expect(sentBody.containsKey('tools'), isFalse);
    });

    test('streamChat() includes a tools array in Anthropic input_schema shape when tools is non-empty', () async {
      late Map<String, dynamic> sentBody;
      final dio = _dioWith((options) {
        sentBody = options.data as Map<String, dynamic>;
        return ResponseBody.fromString(
          _anthropicSse,
          200,
          headers: {Headers.contentTypeHeader: ['text/event-stream']},
        );
      });

      await AnthropicDatasource(dio).streamChat(
        model: 'claude-3-5-sonnet-20241022',
        messages: const [ChatMessage(role: ChatRole.user, content: 'Hi')],
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
      ).toList();

      expect(sentBody['tools'], [
        {
          'name': 'read_file',
          'description': 'Reads a file',
          'input_schema': {
            'type': 'object',
            'properties': {
              'path': {'type': 'string'},
            },
            'required': ['path'],
          },
        },
      ]);
    });

    test('streamChat() parses tool_use content blocks into a tool-calls-requested event', () async {
      const sse = '''
event: content_block_start
data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Let me check."}}

event: content_block_stop
data: {"type":"content_block_stop","index":0}

event: content_block_start
data: {"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"toolu_01ABC","name":"read_file","input":{}}}

event: content_block_delta
data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\\"path\\": \\""}}

event: content_block_delta
data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"foo.dart\\"}"}}

event: content_block_stop
data: {"type":"content_block_stop","index":1}

event: message_stop
data: {"type":"message_stop"}

''';

      final dio = _dioWith((options) {
        return ResponseBody.fromString(
          sse,
          200,
          headers: {Headers.contentTypeHeader: ['text/event-stream']},
        );
      });

      final events = await AnthropicDatasource(dio).streamChat(
        model: 'claude-3-5-sonnet-20241022',
        messages: const [ChatMessage(role: ChatRole.user, content: 'read foo.dart')],
      ).toList();

      expect(events, hasLength(2));
      expect((events[0] as ChatStreamTextDelta).text, 'Let me check.');

      final toolCallsEvent = events[1] as ChatStreamToolCallsRequested;
      expect(toolCallsEvent.toolCalls, hasLength(1));
      expect(toolCallsEvent.toolCalls[0].id, 'toolu_01ABC');
      expect(toolCallsEvent.toolCalls[0].name, 'read_file');
      expect(toolCallsEvent.toolCalls[0].arguments, {'path': 'foo.dart'});
    });

    test('streamChat() regression: text_delta-only SSE emits only text-delta events', () async {
      final dio = _dioWith((options) {
        return ResponseBody.fromString(
          _anthropicSse,
          200,
          headers: {Headers.contentTypeHeader: ['text/event-stream']},
        );
      });

      final events = await AnthropicDatasource(dio).streamChat(
        model: 'claude-3-5-sonnet-20241022',
        messages: const [ChatMessage(role: ChatRole.user, content: 'Hi')],
      ).toList();

      expect(events, everyElement(isA<ChatStreamTextDelta>()));
      expect(events.whereType<ChatStreamToolCallsRequested>(), isEmpty);
    });

    test('streamChat() serializes tool-role messages as user messages with tool_result blocks', () async {
      late Map<String, dynamic> sentBody;
      final dio = _dioWith((options) {
        sentBody = options.data as Map<String, dynamic>;
        return ResponseBody.fromString(
          _anthropicSse,
          200,
          headers: {Headers.contentTypeHeader: ['text/event-stream']},
        );
      });

      await AnthropicDatasource(dio).streamChat(
        model: 'claude-3-5-sonnet-20241022',
        messages: const [
          ChatMessage(role: ChatRole.user, content: 'read foo.dart'),
          ChatMessage(
            role: ChatRole.assistant,
            content: '',
            toolCalls: [
              ToolCall(id: 'toolu_01ABC', name: 'read_file', arguments: {'path': 'foo.dart'}),
            ],
          ),
          ChatMessage(
            role: ChatRole.tool,
            content: 'file contents here',
            toolCallId: 'toolu_01ABC',
            toolName: 'read_file',
          ),
        ],
      ).toList();

      expect(sentBody['messages'], [
        {'role': 'user', 'content': 'read foo.dart'},
        {
          'role': 'assistant',
          'content': [
            {
              'type': 'tool_use',
              'id': 'toolu_01ABC',
              'name': 'read_file',
              'input': {'path': 'foo.dart'},
            },
          ],
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'tool_result',
              'tool_use_id': 'toolu_01ABC',
              'content': 'file contents here',
            },
          ],
        },
      ]);
    });

    test('streamChat() combines consecutive tool-role messages into one user message', () async {
      late Map<String, dynamic> sentBody;
      final dio = _dioWith((options) {
        sentBody = options.data as Map<String, dynamic>;
        return ResponseBody.fromString(
          _anthropicSse,
          200,
          headers: {Headers.contentTypeHeader: ['text/event-stream']},
        );
      });

      await AnthropicDatasource(dio).streamChat(
        model: 'claude-3-5-sonnet-20241022',
        messages: const [
          ChatMessage(
            role: ChatRole.assistant,
            content: '',
            toolCalls: [
              ToolCall(id: 'toolu_01', name: 'read_file', arguments: {'path': 'a.dart'}),
              ToolCall(id: 'toolu_02', name: 'read_file', arguments: {'path': 'b.dart'}),
            ],
          ),
          ChatMessage(role: ChatRole.tool, content: 'a contents', toolCallId: 'toolu_01', toolName: 'read_file'),
          ChatMessage(role: ChatRole.tool, content: 'b contents', toolCallId: 'toolu_02', toolName: 'read_file'),
        ],
      ).toList();

      final messages = sentBody['messages'] as List<dynamic>;
      expect(messages, hasLength(2));
      final toolResultMessage = messages[1] as Map<String, dynamic>;
      expect(toolResultMessage['role'], 'user');
      expect(toolResultMessage['content'], [
        {'type': 'tool_result', 'tool_use_id': 'toolu_01', 'content': 'a contents'},
        {'type': 'tool_result', 'tool_use_id': 'toolu_02', 'content': 'b contents'},
      ]);
    });
  });
}
