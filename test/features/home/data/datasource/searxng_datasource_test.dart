import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/data/datasource/searxng_datasource.dart';

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
  final dio = Dio();
  dio.httpClientAdapter = _FakeAdapter(handler);
  return dio;
}

void main() {
  group('SearxngDatasource.search()', () {
    test('requests format=json with the query and language=en', () async {
      final dio = _dioWith((options) {
        expect(options.path, 'http://localhost:8080/search');
        expect(options.queryParameters, {
          'format': 'json',
          'q': 'flutter news',
          'language': 'en',
        });
        return ResponseBody.fromString(
          jsonEncode({'results': []}),
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        );
      });

      final datasource = SearxngDatasource(dio, baseUrl: 'http://localhost:8080');
      await datasource.search('flutter news');
    });

    test('returns the results array', () async {
      final dio = _dioWith((options) {
        return ResponseBody.fromString(
          jsonEncode({
            'results': [
              {'title': 'Title 1', 'url': 'https://example.com/1', 'content': 'Snippet 1'},
              {'title': 'Title 2', 'url': 'https://example.com/2', 'content': 'Snippet 2'},
            ],
          }),
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        );
      });

      final datasource = SearxngDatasource(dio, baseUrl: 'http://localhost:8080');
      final results = await datasource.search('flutter news');

      expect(results, [
        {'title': 'Title 1', 'url': 'https://example.com/1', 'content': 'Snippet 1'},
        {'title': 'Title 2', 'url': 'https://example.com/2', 'content': 'Snippet 2'},
      ]);
    });

    test('returns an empty list when results is missing', () async {
      final dio = _dioWith((options) {
        return ResponseBody.fromString(
          jsonEncode({'query': 'flutter news'}),
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        );
      });

      final datasource = SearxngDatasource(dio, baseUrl: 'http://localhost:8080');
      final results = await datasource.search('flutter news');

      expect(results, isEmpty);
    });
  });
}
