import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/settings/data/datasource/huggingface_datasource.dart';

/// A minimal [HttpClientAdapter] that returns a canned [ResponseBody] for
/// every request, computed by [handler]. Mirrors
/// `anthropic_datasource_test.dart`'s fake-adapter pattern.
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
  final dio = Dio(BaseOptions(baseUrl: 'https://huggingface.co'));
  dio.httpClientAdapter = _FakeAdapter(handler);
  return dio;
}

/// Canned `GET /api/models` response: one repo with a parseable param count
/// and two recognized-quant `.gguf` siblings, one repo with no parseable
/// param count (skipped), and one repo with a parseable param count but no
/// recognized-quant `.gguf` siblings (skipped).
final _modelsJson = jsonEncode([
  {
    'id': 'TheBloke/Llama-2-7B-Chat-GGUF',
    'config': {
      'max_position_embeddings': 4096,
    },
    'siblings': [
      {'rfilename': 'llama-2-7b-chat.Q4_K_M.gguf', 'size': 4081004224},
      {'rfilename': 'llama-2-7b-chat.Q8_0.gguf', 'size': 7160794624},
      {'rfilename': 'README.md'},
    ],
  },
  {
    'id': 'sentence-transformers/all-MiniLM-L6-v2',
    'siblings': [
      {'rfilename': 'model.safetensors', 'size': 90000000},
    ],
  },
  {
    'id': 'someorg/Mystery-13B-NoGGUF',
    'siblings': [
      {'rfilename': 'model.safetensors', 'size': 26000000000},
      {'rfilename': 'unrecognized-quant.gguf', 'size': 1000},
    ],
  },
]);

void main() {
  group('HuggingFaceDatasource', () {
    test('searchModels() returns one result per recognized-quant .gguf sibling, skipping unparseable repos',
        () async {
      final dio = _dioWith((options) {
        expect(options.path, '/api/models');
        return ResponseBody.fromString(
          _modelsJson,
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        );
      });

      final results = await HuggingFaceDatasource(dio).searchModels();

      expect(results, hasLength(2));

      final q4 = results.firstWhere((r) => r.quant == 'Q4_K_M');
      expect(q4.repoId, 'TheBloke/Llama-2-7B-Chat-GGUF');
      expect(q4.displayName, 'Llama-2-7B-Chat-GGUF');
      expect(q4.paramsBillions, 7.0);
      expect(q4.fileSizeBytes, 4081004224);
      expect(q4.contextLength, 4096);

      final q8 = results.firstWhere((r) => r.quant == 'Q8_0');
      expect(q8.repoId, 'TheBloke/Llama-2-7B-Chat-GGUF');
      expect(q8.paramsBillions, 7.0);
      expect(q8.fileSizeBytes, 7160794624);
      expect(q8.contextLength, 4096);

      // The embedding model (no parseable param count) and the
      // no-recognized-quant repo are both excluded.
      expect(results.any((r) => r.repoId.contains('MiniLM')), isFalse);
      expect(results.any((r) => r.repoId.contains('Mystery')), isFalse);
    });

    test('omits the search query param when query is null or empty', () async {
      RequestOptions? captured;
      final dio = _dioWith((options) {
        captured = options;
        return ResponseBody.fromString(
          jsonEncode([]),
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        );
      });

      final datasource = HuggingFaceDatasource(dio);

      await datasource.searchModels();
      expect(captured!.queryParameters.containsKey('search'), isFalse);

      await datasource.searchModels(query: '');
      expect(captured!.queryParameters.containsKey('search'), isFalse);
    });

    test('includes the search query param when query is provided', () async {
      RequestOptions? captured;
      final dio = _dioWith((options) {
        captured = options;
        return ResponseBody.fromString(
          jsonEncode([]),
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        );
      });

      await HuggingFaceDatasource(dio).searchModels(query: 'llama');

      expect(captured!.queryParameters['search'], 'llama');
      expect(captured!.queryParameters['filter'], 'gguf');
      expect(captured!.queryParameters['sort'], 'downloads');
      expect(captured!.queryParameters['direction'], '-1');
      expect(captured!.queryParameters['limit'], '30');
      expect(captured!.queryParameters['full'], 'true');
    });
  });
}
