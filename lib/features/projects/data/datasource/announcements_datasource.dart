import 'package:dio/dio.dart';
import '../../domain/model/announcement.dart';

class AnnouncementsDatasource {
  final Dio _dio;
  final String _projectKey;

  AnnouncementsDatasource(this._dio, this._projectKey);

  String get _basePath => '/api/v1/projects/$_projectKey/announcements';

  Future<List<Announcement>> fetchAnnouncements() async {
    final response = await _dio.get<List<dynamic>>('$_basePath/admin');
    return (response.data as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Announcement.fromJson)
        .toList();
  }

  Future<void> createAnnouncement(
    String title,
    String body,
    AnnouncementType type, {
    bool published = true,
    String? ctaLabel,
    String? ctaUrl,
  }) async {
    await _dio.post(_basePath, data: {
      'title': title,
      'body': body,
      'type': type.value,
      'published': published,
      if (ctaLabel != null && ctaLabel.isNotEmpty) 'ctaLabel': ctaLabel,
      if (ctaUrl != null && ctaUrl.isNotEmpty) 'ctaUrl': ctaUrl,
    });
  }

  Future<void> updateAnnouncement(
    String id, {
    String? title,
    String? body,
    AnnouncementType? type,
    bool? published,
    String? ctaLabel,
    String? ctaUrl,
  }) async {
    await _dio.patch('$_basePath/$id', data: {
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (type != null) 'type': type.value,
      if (published != null) 'published': published,
      'ctaLabel': ctaLabel ?? '',
      'ctaUrl': ctaUrl ?? '',
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    await _dio.delete('$_basePath/$id');
  }
}
