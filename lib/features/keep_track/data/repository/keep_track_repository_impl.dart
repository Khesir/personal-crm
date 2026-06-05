import '../../domain/repository/keep_track_repository.dart';
import '../../presentation/state/keep_track_state.dart';
import '../datasource/keep_track_datasource.dart';

class KeepTrackRepositoryImpl implements KeepTrackRepository {
  final KeepTrackDatasource _datasource;

  KeepTrackRepositoryImpl(this._datasource);

  @override
  Future<List<Announcement>> fetchAnnouncements() =>
      _datasource.fetchAnnouncements();

  @override
  Future<void> createAnnouncement(String title, String body, AnnouncementType type, {bool published = true, String? ctaLabel, String? ctaUrl}) =>
      _datasource.createAnnouncement(title, body, type, published: published, ctaLabel: ctaLabel, ctaUrl: ctaUrl);

  @override
  Future<void> updateAnnouncement(String id, {String? title, String? body, AnnouncementType? type, bool? published, String? ctaLabel, String? ctaUrl}) =>
      _datasource.updateAnnouncement(id, title: title, body: body, type: type, published: published, ctaLabel: ctaLabel, ctaUrl: ctaUrl);

  @override
  Future<void> deleteAnnouncement(String id) =>
      _datasource.deleteAnnouncement(id);

  @override
  Future<List<AppRelease>> fetchReleases() => _datasource.fetchReleases();

  @override
  Future<AppRelease> createRelease(String version, String title, String body, ReleasePlatforms platforms) =>
      _datasource.createRelease(version, title, body, platforms);

  @override
  Future<void> deleteAllReleases() => _datasource.deleteAllReleases();

  @override
  Future<String> uploadReleaseFile({required String platform, required List<int> bytes, required String fileName}) =>
      _datasource.uploadReleaseFile(platform: platform, bytes: bytes, fileName: fileName);

  @override
  Future<AppRelease> updatePlatformField({required String id, required String platform, required Map<String, dynamic> fields}) =>
      _datasource.updatePlatformField(id: id, platform: platform, fields: fields);
}
