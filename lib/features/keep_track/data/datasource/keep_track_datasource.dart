import 'package:dio/dio.dart';
import '../../presentation/state/keep_track_state.dart';

const _v1 = '/api/v1';

class KeepTrackDatasource {
  final Dio _dio;

  KeepTrackDatasource(this._dio);

  Future<List<Announcement>> fetchAnnouncements() async {
    final response = await _dio.get<List<dynamic>>('$_v1/announcements/admin');
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
    await _dio.post('$_v1/announcements', data: {
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
    await _dio.patch('$_v1/announcements/$id', data: {
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (type != null) 'type': type.value,
      if (published != null) 'published': published,
      'ctaLabel': ctaLabel ?? '',
      'ctaUrl': ctaUrl ?? '',
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    await _dio.delete('$_v1/announcements/$id');
  }

  Future<List<AppRelease>> fetchReleases() async {
    final response = await _dio.get<List<dynamic>>('$_v1/releases/admin');
    return (response.data as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(AppRelease.fromJson)
        .toList();
  }

  Future<AppRelease> createRelease(
    String version,
    String title,
    String body,
    ReleasePlatforms platforms,
  ) async {
    final response = await _dio.post('$_v1/releases', data: {
      'version': version,
      'title': title,
      'body': body,
      'published': true,
      'platforms': {
        'windows': platforms.windows.toJson(),
        'android': platforms.android.toJson(),
        'macos': platforms.macos.toJson(),
        'ios': platforms.ios.toJson(),
      },
    });
    return AppRelease.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAllReleases() async {
    await _dio.delete('$_v1/releases/all');
  }

  Future<String> uploadReleaseFile({
    required String platform,
    required List<int> bytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await _dio.post(
      '$_v1/releases/upload',
      data: formData,
      queryParameters: {'platform': platform},
    );
    return response.data['url'] as String;
  }

  Future<AppRelease> updatePlatformField({
    required String id,
    required String platform,
    required Map<String, dynamic> fields,
  }) async {
    final response = await _dio.patch(
      '$_v1/releases/$id/platforms/$platform',
      data: fields,
    );
    return AppRelease.fromJson(response.data as Map<String, dynamic>);
  }
}
