import 'package:crm/core/state/state.dart';
import '../../domain/repository/keep_track_repository.dart';
import '../../presentation/state/keep_track_state.dart';

class AnnouncementsController
    extends StreamState<AsyncState<List<Announcement>>> {
  final KeepTrackRepository _repository;

  AnnouncementsController(this._repository) : super(const AsyncLoading());

  Future<void> load() => execute(_repository.fetchAnnouncements);

  Future<void> create(
    String title,
    String body,
    AnnouncementType type, {
    bool published = true,
    String? ctaLabel,
    String? ctaUrl,
  }) async {
    await _repository.createAnnouncement(title, body, type, published: published, ctaLabel: ctaLabel, ctaUrl: ctaUrl);
    await executeSilent(_repository.fetchAnnouncements);
  }

  Future<void> edit(String id, {String? title, String? body, AnnouncementType? type, bool? published, String? ctaLabel, String? ctaUrl}) async {
    await _repository.updateAnnouncement(id, title: title, body: body, type: type, published: published, ctaLabel: ctaLabel, ctaUrl: ctaUrl);
    await executeSilent(_repository.fetchAnnouncements);
  }

  Future<void> delete(String id) async {
    await _repository.deleteAnnouncement(id);
    await executeSilent(_repository.fetchAnnouncements);
  }
}

class ReleasesController extends StreamState<AsyncState<List<AppRelease>>> {
  final KeepTrackRepository _repository;

  ReleasesController(this._repository) : super(const AsyncLoading());

  Future<void> load() => execute(_repository.fetchReleases);

  Future<void> createNewVersion(
    String version,
    String title,
    String body,
    ReleasePlatforms platforms,
  ) async {
    await _repository.createRelease(version, title, body, platforms);
    await executeSilent(_repository.fetchReleases);
  }

  Future<void> uploadPlatformFile({
    required String platform,
    required String urlField,
    required List<int> bytes,
    required String fileName,
  }) async {
    final releases = data;
    if (releases == null || releases.isEmpty) return;
    final id = releases.first.id;

    final url = await _repository.uploadReleaseFile(
      platform: platform,
      bytes: bytes,
      fileName: fileName,
    );

    await _repository.updatePlatformField(
      id: id,
      platform: platform,
      fields: {urlField: url},
    );

    await executeSilent(_repository.fetchReleases);
  }

  Future<void> updatePlatformStatus({
    required String platform,
    required PlatformStatus status,
  }) async {
    final releases = data;
    if (releases == null || releases.isEmpty) return;
    await _repository.updatePlatformField(
      id: releases.first.id,
      platform: platform,
      fields: {'status': status.value},
    );
    await executeSilent(_repository.fetchReleases);
  }

  Future<void> updatePlatformStoreUrl({
    required String platform,
    required String url,
  }) async {
    final releases = data;
    if (releases == null || releases.isEmpty) return;
    await _repository.updatePlatformField(
      id: releases.first.id,
      platform: platform,
      fields: {'storeUrl': url},
    );
    await executeSilent(_repository.fetchReleases);
  }

  Future<void> updatePlayStoreUrl(String url) async {
    final releases = data;
    if (releases == null || releases.isEmpty) return;
    await _repository.updatePlatformField(
      id: releases.first.id,
      platform: 'android',
      fields: {'playStoreUrl': url},
    );
    await executeSilent(_repository.fetchReleases);
  }
}
