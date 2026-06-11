import '../model/announcement.dart';

abstract class AnnouncementsRepository {
  Future<List<Announcement>> fetchAnnouncements();

  Future<void> createAnnouncement(
    String title,
    String body,
    AnnouncementType type, {
    bool published = true,
    String? ctaLabel,
    String? ctaUrl,
  });

  Future<void> updateAnnouncement(
    String id, {
    String? title,
    String? body,
    AnnouncementType? type,
    bool? published,
    String? ctaLabel,
    String? ctaUrl,
  });

  Future<void> deleteAnnouncement(String id);
}
