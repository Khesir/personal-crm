import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/data/datasource/page_fetch_datasource.dart';
import 'package:crm/features/home/data/repository/fetch_page_repository_impl.dart';
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

ResponseBody _htmlResponse(String html, [int statusCode = 200]) {
  return ResponseBody.fromString(
    html,
    statusCode,
    headers: {Headers.contentTypeHeader: ['text/html']},
  );
}

void main() {
  group('FetchPageRepositoryImpl.fetch()', () {
    test('returns a ToolOutput with the page\'s readable text', () async {
      final dio = _dioWith((options) {
        return _htmlResponse('<html><body><p>Hello world</p></body></html>');
      });

      final repository = FetchPageRepositoryImpl(PageFetchDatasource(dio));
      final result = await repository.fetch('https://example.com/article');

      expect(result, isA<ToolOutput>());
      expect((result as ToolOutput).text, contains('Hello world'));
    });

    test('returns a ToolOutput with a "no readable content" message for an empty page', () async {
      final dio = _dioWith((options) {
        return _htmlResponse('<html><body></body></html>');
      });

      final repository = FetchPageRepositoryImpl(PageFetchDatasource(dio));
      final result = await repository.fetch('https://example.com/empty');

      expect(result, isA<ToolOutput>());
      expect((result as ToolOutput).text, contains('No readable content'));
      expect(result.text, contains('https://example.com/empty'));
    });

    test('returns a ToolError when the request fails', () async {
      final dio = _dioWith((options) {
        throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
      });

      final repository = FetchPageRepositoryImpl(PageFetchDatasource(dio));
      final result = await repository.fetch('https://example.com/article');

      expect(result, isA<ToolError>());
    });

    test('returns a ToolError when the response is a non-2xx status', () async {
      final dio = _dioWith((options) {
        return _htmlResponse('<html><body>Not found</body></html>', 404);
      });

      final repository = FetchPageRepositoryImpl(PageFetchDatasource(dio));
      final result = await repository.fetch('https://example.com/missing');

      expect(result, isA<ToolError>());
    });
  });
}
