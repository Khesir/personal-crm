import 'package:crm/core/state/state.dart';
import '../model/announcement.dart';
import '../repository/announcements_repository.dart';

class AnnouncementsController
    extends StreamState<AsyncState<List<Announcement>>> {
  final AnnouncementsRepository _repository;

  AnnouncementsController(this._repository) : super(const AsyncLoading());

  List<Announcement>? get data => switch (state) {
        AsyncData(data: final list) => list,
        _ => null,
      };

  Future<void> load() => execute(_repository.fetchAnnouncements);

  Future<void> create(
    String title,
    String body,
    AnnouncementType type, {
    bool published = true,
    String? ctaLabel,
    String? ctaUrl,
  }) async {
    await _repository.createAnnouncement(
      title,
      body,
      type,
      published: published,
      ctaLabel: ctaLabel,
      ctaUrl: ctaUrl,
    );
    await executeSilent(_repository.fetchAnnouncements);
  }

  Future<void> edit(
    String id, {
    String? title,
    String? body,
    AnnouncementType? type,
    bool? published,
    String? ctaLabel,
    String? ctaUrl,
  }) async {
    await _repository.updateAnnouncement(
      id,
      title: title,
      body: body,
      type: type,
      published: published,
      ctaLabel: ctaLabel,
      ctaUrl: ctaUrl,
    );
    await executeSilent(_repository.fetchAnnouncements);
  }

  Future<void> delete(String id) async {
    await _repository.deleteAnnouncement(id);
    await executeSilent(_repository.fetchAnnouncements);
  }
}
