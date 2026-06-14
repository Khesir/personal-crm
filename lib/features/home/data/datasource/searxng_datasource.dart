import 'package:dio/dio.dart';

class SearxngDatasource {
  final Dio _dio;
  final String baseUrl;

  SearxngDatasource(this._dio, {required this.baseUrl});

  /// Queries `GET {baseUrl}/search?format=json&q=...&language=en` and
  /// returns the raw `results` array, each entry shaped like
  /// `{"title": ..., "url": ..., "content": ...}`.
  Future<List<Map<String, dynamic>>> search(String query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$baseUrl/search',
      queryParameters: {
        'format': 'json',
        'q': query,
        'language': 'en',
      },
    );
    final results = response.data?['results'] as List<dynamic>? ?? [];
    return results.cast<Map<String, dynamic>>();
  }
}
