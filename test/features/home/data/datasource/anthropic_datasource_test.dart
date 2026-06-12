import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/data/datasource/anthropic_datasource.dart';
import 'package:crm/features/home/domain/model/chat_message.dart';
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

      final chunks = await AnthropicDatasource(dio)
          .streamChat(model: 'claude-3-5-sonnet-20241022', messages: const [
        ChatMessage(role: ChatRole.user, content: 'Hi'),
      ]).toList();

      expect(chunks, ['Hello', ' world']);
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
  });
}
