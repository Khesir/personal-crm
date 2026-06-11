import '../../domain/model/announcement.dart';
import '../../domain/repository/announcements_repository.dart';
import '../datasource/announcements_datasource.dart';

class AnnouncementsRepositoryImpl implements AnnouncementsRepository {
  final AnnouncementsDatasource _datasource;

  AnnouncementsRepositoryImpl(this._datasource);

  @override
  Future<List<Announcement>> fetchAnnouncements() =>
      _datasource.fetchAnnouncements();

  @override
  Future<void> createAnnouncement(
    String title,
    String body,
    AnnouncementType type, {
    bool published = true,
    String? ctaLabel,
    String? ctaUrl,
  }) =>
      _datasource.createAnnouncement(
        title,
        body,
        type,
        published: published,
        ctaLabel: ctaLabel,
        ctaUrl: ctaUrl,
      );

  @override
  Future<void> updateAnnouncement(
    String id, {
    String? title,
    String? body,
    AnnouncementType? type,
    bool? published,
    String? ctaLabel,
    String? ctaUrl,
  }) =>
      _datasource.updateAnnouncement(
        id,
        title: title,
        body: body,
        type: type,
        published: published,
        ctaLabel: ctaLabel,
        ctaUrl: ctaUrl,
      );

  @override
  Future<void> deleteAnnouncement(String id) =>
      _datasource.deleteAnnouncement(id);
}
