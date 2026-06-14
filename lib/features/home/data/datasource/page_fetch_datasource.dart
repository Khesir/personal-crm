import 'package:dio/dio.dart';

/// Matches `<script>`/`<style>` elements including their content, so their
/// (non-readable) contents are dropped entirely rather than left behind once
/// the tags themselves are stripped.
final _scriptOrStyleRegex = RegExp(
  r'<(script|style)\b[^>]*>.*?</\1>',
  caseSensitive: false,
  dotAll: true,
);

final _tagRegex = RegExp('<[^>]+>');
final _horizontalWhitespaceRegex = RegExp(r'[ \t\f\v]+');

class PageFetchDatasource {
  final Dio _dio;

  PageFetchDatasource(this._dio);

  /// `GET`s [url] and strips its HTML response down to readable text.
  Future<String> fetchText(String url) async {
    final response = await _dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    );
    return _htmlToText(response.data ?? '');
  }

  String _htmlToText(String html) {
    var text = html.replaceAll(_scriptOrStyleRegex, '');
    text = text.replaceAll(_tagRegex, '\n');
    text = _decodeEntities(text);
    text = text.replaceAll(_horizontalWhitespaceRegex, ' ');
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty);
    return lines.join('\n');
  }

  String _decodeEntities(String text) {
    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'");
  }
}
