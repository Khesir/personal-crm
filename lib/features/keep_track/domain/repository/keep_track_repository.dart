import '../../presentation/state/keep_track_state.dart';

abstract class KeepTrackRepository {
  Future<List<Announcement>> fetchAnnouncements();
  Future<void> createAnnouncement(String title, String body, AnnouncementType type, {bool published, String? ctaLabel, String? ctaUrl});
  Future<void> updateAnnouncement(String id, {String? title, String? body, AnnouncementType? type, bool? published, String? ctaLabel, String? ctaUrl});
  Future<void> deleteAnnouncement(String id);
  Future<List<AppRelease>> fetchReleases();
  Future<AppRelease> createRelease(String version, String title, String body, ReleasePlatforms platforms);
  Future<void> deleteAllReleases();
  Future<String> uploadReleaseFile({required String platform, required List<int> bytes, required String fileName});
  Future<AppRelease> updatePlatformField({required String id, required String platform, required Map<String, dynamic> fields});
}
