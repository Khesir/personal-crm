import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/data/datasource/ollama_datasource.dart';
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
}
