import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/data/datasource/page_fetch_datasource.dart';

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
  group('PageFetchDatasource.fetchText()', () {
    test('GETs the given url', () async {
      final dio = _dioWith((options) {
        expect(options.uri.toString(), 'https://example.com/article');
        return _htmlResponse('<html><body><p>Hello</p></body></html>');
      });

      final datasource = PageFetchDatasource(dio);
      await datasource.fetchText('https://example.com/article');
    });

    test('strips tags, scripts, and styles down to readable text', () async {
      final dio = _dioWith((options) {
        return _htmlResponse('''
          <html>
            <head>
              <style>body { color: red; }</style>
              <script>console.log("hi");</script>
              <title>My Page</title>
            </head>
            <body>
              <h1>Heading</h1>
              <p>First paragraph.</p>
              <p>Second &amp; third &lt;item&gt;.</p>
            </body>
          </html>
        ''');
      });

      final datasource = PageFetchDatasource(dio);
      final text = await datasource.fetchText('https://example.com/article');

      expect(text, contains('Heading'));
      expect(text, contains('First paragraph.'));
      expect(text, contains('Second & third <item>.'));
      expect(text, isNot(contains('console.log')));
      expect(text, isNot(contains('color: red')));
    });

    test('returns an empty string for an empty body', () async {
      final dio = _dioWith((options) {
        return _htmlResponse('');
      });

      final datasource = PageFetchDatasource(dio);
      final text = await datasource.fetchText('https://example.com/empty');

      expect(text, isEmpty);
    });

    test('throws when the request returns a non-2xx response', () async {
      final dio = _dioWith((options) {
        return _htmlResponse('<html><body>Not found</body></html>', 404);
      });

      final datasource = PageFetchDatasource(dio);

      expect(() => datasource.fetchText('https://example.com/missing'), throwsA(isA<DioException>()));
    });
  });
}
