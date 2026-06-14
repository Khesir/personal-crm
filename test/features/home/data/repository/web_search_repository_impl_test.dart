import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/data/datasource/searxng_datasource.dart';
import 'package:crm/features/home/data/repository/web_search_repository_impl.dart';
import 'package:crm/features/home/domain/model/tool_execution_result.dart';

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
  group('WebSearchRepositoryImpl.search()', () {
    test('returns a ToolOutput listing each result\'s title, url, and snippet', () async {
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

      final repository = WebSearchRepositoryImpl(SearxngDatasource(dio, baseUrl: 'http://localhost:8080'));
      final result = await repository.search('flutter news');

      expect(result, isA<ToolOutput>());
      final text = (result as ToolOutput).text;
      expect(text, contains('Title 1'));
      expect(text, contains('https://example.com/1'));
      expect(text, contains('Snippet 1'));
      expect(text, contains('Title 2'));
      expect(text, contains('https://example.com/2'));
      expect(text, contains('Snippet 2'));
    });

    test('caps results to count', () async {
      final dio = _dioWith((options) {
        return ResponseBody.fromString(
          jsonEncode({
            'results': [
              {'title': 'Title 1', 'url': 'https://example.com/1', 'content': 'Snippet 1'},
              {'title': 'Title 2', 'url': 'https://example.com/2', 'content': 'Snippet 2'},
              {'title': 'Title 3', 'url': 'https://example.com/3', 'content': 'Snippet 3'},
            ],
          }),
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        );
      });

      final repository = WebSearchRepositoryImpl(SearxngDatasource(dio, baseUrl: 'http://localhost:8080'));
      final result = await repository.search('flutter news', count: 1);

      final text = (result as ToolOutput).text;
      expect(text, contains('Title 1'));
      expect(text, isNot(contains('Title 2')));
      expect(text, isNot(contains('Title 3')));
    });

    test('returns ToolOutput("No results found.") when results is empty', () async {
      final dio = _dioWith((options) {
        return ResponseBody.fromString(
          jsonEncode({'results': []}),
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        );
      });

      final repository = WebSearchRepositoryImpl(SearxngDatasource(dio, baseUrl: 'http://localhost:8080'));
      final result = await repository.search('flutter news');

      expect(result, isA<ToolOutput>());
      expect((result as ToolOutput).text, 'No results found.');
    });

    test('returns a ToolError when the request fails', () async {
      final dio = _dioWith((options) {
        throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
      });

      final repository = WebSearchRepositoryImpl(SearxngDatasource(dio, baseUrl: 'http://localhost:8080'));
      final result = await repository.search('flutter news');

      expect(result, isA<ToolError>());
    });
  });
}
