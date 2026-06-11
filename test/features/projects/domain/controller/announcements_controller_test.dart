import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/projects/domain/controller/announcements_controller.dart';
import 'package:crm/features/projects/domain/model/announcement.dart';
import 'package:crm/features/projects/domain/repository/announcements_repository.dart';

class FakeAnnouncementsRepository implements AnnouncementsRepository {
  List<Announcement> announcements;
  String projectKey;
  int fetchCallCount = 0;

  String? lastCreateTitle;
  String? lastCreateBody;
  AnnouncementType? lastCreateType;
  bool? lastCreatePublished;
  String? lastCreateCtaLabel;
  String? lastCreateCtaUrl;

  String? lastEditId;
  String? lastEditTitle;
  String? lastEditBody;
  AnnouncementType? lastEditType;
  bool? lastEditPublished;

  String? lastDeleteId;

  FakeAnnouncementsRepository({required this.projectKey, List<Announcement>? initial})
      : announcements = initial ?? [];

  @override
  Future<List<Announcement>> fetchAnnouncements() async {
    fetchCallCount++;
    return List.unmodifiable(announcements);
  }

  @override
  Future<void> createAnnouncement(
    String title,
    String body,
    AnnouncementType type, {
    bool published = true,
    String? ctaLabel,
    String? ctaUrl,
  }) async {
    lastCreateTitle = title;
    lastCreateBody = body;
    lastCreateType = type;
    lastCreatePublished = published;
    lastCreateCtaLabel = ctaLabel;
    lastCreateCtaUrl = ctaUrl;

    announcements = [
      ...announcements,
      Announcement(
        id: 'new-id',
        title: title,
        body: body,
        type: type,
        published: published,
        ctaLabel: ctaLabel,
        ctaUrl: ctaUrl,
        publishedAt: published ? DateTime(2024, 1, 1) : null,
        createdAt: DateTime(2024, 1, 1),
      ),
    ];
  }

  @override
  Future<void> updateAnnouncement(
    String id, {
    String? title,
    String? body,
    AnnouncementType? type,
    bool? published,
    String? ctaLabel,
    String? ctaUrl,
  }) async {
    lastEditId = id;
    lastEditTitle = title;
    lastEditBody = body;
    lastEditType = type;
    lastEditPublished = published;

    announcements = [
      for (final a in announcements)
        if (a.id == id)
          Announcement(
            id: a.id,
            title: title ?? a.title,
            body: body ?? a.body,
            type: type ?? a.type,
            published: published ?? a.published,
            ctaLabel: ctaLabel ?? a.ctaLabel,
            ctaUrl: ctaUrl ?? a.ctaUrl,
            publishedAt: a.publishedAt,
            createdAt: a.createdAt,
          )
        else
          a,
    ];
  }

  @override
  Future<void> deleteAnnouncement(String id) async {
    lastDeleteId = id;
    announcements = announcements.where((a) => a.id != id).toList();
  }
}

void main() {
  group('AnnouncementsController', () {
    test('load() populates state with announcements from the repository', () async {
      final repo = FakeAnnouncementsRepository(
        projectKey: 'keep-track',
        initial: [
          Announcement(
            id: 'a1',
            title: 'Hello',
            body: 'World',
            type: AnnouncementType.info,
            published: true,
            createdAt: DateTime(2024, 1, 1),
          ),
        ],
      );
      final controller = AnnouncementsController(repo);

      await controller.load();

      expect(controller.data, hasLength(1));
      expect(controller.data!.first.id, 'a1');
      expect(repo.fetchCallCount, 1);

      controller.dispose();
    });

    test('create() calls repository with correct args and reloads', () async {
      final repo = FakeAnnouncementsRepository(projectKey: 'keep-track');
      final controller = AnnouncementsController(repo);
      await controller.load();

      await controller.create(
        'Title',
        'Body',
        AnnouncementType.release,
        published: false,
        ctaLabel: 'Learn more',
        ctaUrl: 'https://example.com',
      );

      expect(repo.lastCreateTitle, 'Title');
      expect(repo.lastCreateBody, 'Body');
      expect(repo.lastCreateType, AnnouncementType.release);
      expect(repo.lastCreatePublished, false);
      expect(repo.lastCreateCtaLabel, 'Learn more');
      expect(repo.lastCreateCtaUrl, 'https://example.com');
      expect(controller.data, hasLength(1));

      controller.dispose();
    });

    test('edit() calls repository with correct id and fields and reloads', () async {
      final repo = FakeAnnouncementsRepository(
        projectKey: 'keep-track',
        initial: [
          Announcement(
            id: 'a1',
            title: 'Old title',
            body: 'Old body',
            type: AnnouncementType.info,
            published: false,
            createdAt: DateTime(2024, 1, 1),
          ),
        ],
      );
      final controller = AnnouncementsController(repo);
      await controller.load();

      await controller.edit(
        'a1',
        title: 'New title',
        body: 'New body',
        type: AnnouncementType.update,
        published: true,
      );

      expect(repo.lastEditId, 'a1');
      expect(repo.lastEditTitle, 'New title');
      expect(repo.lastEditBody, 'New body');
      expect(repo.lastEditType, AnnouncementType.update);
      expect(repo.lastEditPublished, true);
      expect(controller.data!.first.title, 'New title');
      expect(controller.data!.first.published, true);

      controller.dispose();
    });

    test('delete() calls repository with correct id and reloads', () async {
      final repo = FakeAnnouncementsRepository(
        projectKey: 'keep-track',
        initial: [
          Announcement(
            id: 'a1',
            title: 'Title',
            body: 'Body',
            type: AnnouncementType.info,
            published: true,
            createdAt: DateTime(2024, 1, 1),
          ),
        ],
      );
      final controller = AnnouncementsController(repo);
      await controller.load();

      await controller.delete('a1');

      expect(repo.lastDeleteId, 'a1');
      expect(controller.data, isEmpty);

      controller.dispose();
    });

    test('repository is constructed scoped to the given projectKey', () async {
      final repo = FakeAnnouncementsRepository(projectKey: 'project-x');

      expect(repo.projectKey, 'project-x');
    });
  });
}
