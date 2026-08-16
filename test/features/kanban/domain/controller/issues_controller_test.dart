import 'package:flutter_test/flutter_test.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/features/kanban/domain/controller/issues_controller.dart';
import 'package:crm/features/kanban/domain/model/issue.dart';
import 'package:crm/features/kanban/domain/repository/issues_repository.dart';

class FakeIssuesRepository implements IssuesRepository {
  List<Issue> issues;
  int callCount = 0;
  String? lastLocalPath;

  Issue? lastUpdatedIssue;
  String? lastUpdatedTitle;
  String? lastUpdatedBody;
  String? lastUpdatedFeature;
  List<String>? lastUpdatedTags;

  Issue? lastMovedIssue;
  IssueStatus? lastMovedStatus;

  Issue? lastCreatedIssue;
  String? lastCreatedLocalPath;

  List<Issue> archivedIssues;
  List<String> archives;
  String? lastArchiveLocalPath;
  String? lastArchiveName;
  String? lastListArchivesLocalPath;

  FakeIssuesRepository([List<Issue>? initial])
    : issues = initial ?? [],
      archivedIssues = [],
      archives = [];

  @override
  Future<List<Issue>> getIssues(String localPath) async {
    callCount++;
    lastLocalPath = localPath;
    return List.unmodifiable(issues);
  }

  @override
  Future<List<Issue>> getArchivedIssues(
    String localPath,
    String archiveName,
  ) async {
    lastArchiveLocalPath = localPath;
    lastArchiveName = archiveName;
    return List.unmodifiable(archivedIssues);
  }

  @override
  Future<List<String>> listArchives(String localPath) async {
    lastListArchivesLocalPath = localPath;
    return List.unmodifiable(archives);
  }

  @override
  Future<Issue> updateIssue(
    Issue issue, {
    String? title,
    String? body,
    String? feature,
    List<String>? tags,
  }) async {
    lastUpdatedIssue = issue;
    lastUpdatedTitle = title;
    lastUpdatedBody = body;
    lastUpdatedFeature = feature;
    lastUpdatedTags = tags;

    final updated = Issue(
      id: issue.id,
      title: title ?? issue.title,
      feature: feature ?? issue.feature,
      status: issue.status,
      createdAt: issue.createdAt,
      tags: tags ?? issue.tags,
      body: body ?? issue.body,
      filePath: issue.filePath,
    );
    issues = [
      for (final existing in issues)
        if (existing.id == issue.id) updated else existing,
    ];
    return updated;
  }

  @override
  Future<Issue> createIssue(String localPath, Issue issue) async {
    lastCreatedLocalPath = localPath;
    lastCreatedIssue = issue;

    final created = Issue(
      id: issue.id,
      title: issue.title,
      feature: issue.feature,
      status: IssueStatus.backlog,
      createdAt: issue.createdAt,
      tags: issue.tags,
      body: issue.body,
      filePath: 'C:\\repo\\issues\\backlog\\${issue.id}.md',
    );
    issues = [...issues, created];
    return created;
  }

  @override
  Future<Issue> moveIssue(Issue issue, IssueStatus newStatus) async {
    lastMovedIssue = issue;
    lastMovedStatus = newStatus;

    final moved = Issue(
      id: issue.id,
      title: issue.title,
      feature: issue.feature,
      status: newStatus,
      createdAt: issue.createdAt,
      tags: issue.tags,
      body: issue.body,
      filePath: issue.filePath,
    );
    issues = [
      for (final existing in issues)
        if (existing.id == issue.id) moved else existing,
    ];
    return moved;
  }

  @override
  Future<void> deleteIssue(Issue issue) async {
    issues = [
      for (final existing in issues)
        if (existing.id != issue.id) existing,
    ];
  }

  Issue? lastRawUpdateIssue;
  String? lastRawUpdateContent;

  @override
  Future<Issue> updateIssueRaw(Issue issue, String rawContent) async {
    lastRawUpdateIssue = issue;
    lastRawUpdateContent = rawContent;

    final updated = Issue(
      id: issue.id,
      title: issue.title,
      feature: issue.feature,
      status: issue.status,
      createdAt: issue.createdAt,
      tags: issue.tags,
      body: issue.body,
      filePath: issue.filePath,
    );
    issues = [
      for (final existing in issues)
        if (existing.id == issue.id) updated else existing,
    ];
    return updated;
  }

  int initializeIssuesFolderCallCount = 0;
  void Function(String localPath)? initializeIssuesFolderCallback;

  @override
  Future<void> initializeIssuesFolder(String localPath) async {
    initializeIssuesFolderCallCount++;
    initializeIssuesFolderCallback?.call(localPath);
  }

  bool folderExists = true;
  String? lastFolderExistsCheckLocalPath;

  @override
  Future<bool> issuesFolderExists(String localPath) async {
    lastFolderExistsCheckLocalPath = localPath;
    return folderExists;
  }
}

void main() {
  group('IssuesController', () {
    test('load() populates state with issues from the repository', () async {
      final repo = FakeIssuesRepository([
        const Issue(
          id: 'issue-001',
          title: 'Add OAuth login',
          feature: 'user-auth',
          status: IssueStatus.ready,
          createdAt: null,
          tags: ['auth'],
          body: 'Body',
          filePath: r'C:\repo\issues\ready\issue-001.md',
        ),
      ]);
      final controller = IssuesController(repo);

      await controller.load(r'C:\repo');

      expect(controller.data, hasLength(1));
      expect(controller.data!.first.id, 'issue-001');
      expect(repo.lastLocalPath, r'C:\repo');

      controller.dispose();
    });

    test('loadArchive() populates state with issues from the archive', () async {
      final repo = FakeIssuesRepository();
      repo.archivedIssues = [
        const Issue(
          id: 'issue-001',
          title: 'Shell rewrite and theme',
          feature: 'shell',
          status: IssueStatus.done,
          createdAt: null,
          tags: ['ui'],
          body: 'Body',
          filePath: r'C:\repo\issues\archive\2026-06-12-dev-command-center\done\issue-001.md',
        ),
      ];
      final controller = IssuesController(repo);

      await controller.loadArchive(r'C:\repo', '2026-06-12-dev-command-center');

      expect(controller.data, hasLength(1));
      expect(controller.data!.first.id, 'issue-001');
      expect(controller.data!.first.status, IssueStatus.done);
      expect(repo.lastArchiveLocalPath, r'C:\repo');
      expect(repo.lastArchiveName, '2026-06-12-dev-command-center');

      controller.dispose();
    });

    test('load() again (rescan) reflects updated repository contents', () async {
      final repo = FakeIssuesRepository([
        const Issue(
          id: 'issue-001',
          title: 'Add OAuth login',
          feature: 'user-auth',
          status: IssueStatus.ready,
          createdAt: null,
          tags: ['auth'],
          body: 'Body',
          filePath: r'C:\repo\issues\ready\issue-001.md',
        ),
      ]);
      final controller = IssuesController(repo);

      await controller.load(r'C:\repo');
      expect(controller.data, hasLength(1));

      repo.issues = [
        ...repo.issues,
        const Issue(
          id: 'issue-002',
          title: 'Fix bug',
          feature: 'user-auth',
          status: IssueStatus.backlog,
          createdAt: null,
          tags: [],
          body: 'Body',
          filePath: r'C:\repo\issues\backlog\issue-002.md',
        ),
      ];
      await controller.load(r'C:\repo');

      expect(controller.data, hasLength(2));
      expect(repo.callCount, 2);

      controller.dispose();
    });

    test('updateIssue() persists field changes and updates state', () async {
      const issue = Issue(
        id: 'issue-001',
        title: 'Add OAuth login',
        feature: 'user-auth',
        status: IssueStatus.ready,
        createdAt: null,
        tags: ['auth'],
        body: 'Body',
        filePath: r'C:\repo\issues\ready\issue-001.md',
      );
      final repo = FakeIssuesRepository([issue]);
      final controller = IssuesController(repo);
      await controller.load(r'C:\repo');

      await controller.updateIssue(
        issue,
        title: 'Add OAuth login (v2)',
        feature: 'auth',
        tags: ['auth', 'oauth'],
      );

      expect(repo.lastUpdatedIssue, issue);
      expect(repo.lastUpdatedTitle, 'Add OAuth login (v2)');
      expect(repo.lastUpdatedFeature, 'auth');
      expect(repo.lastUpdatedTags, ['auth', 'oauth']);
      expect(controller.data!.first.title, 'Add OAuth login (v2)');
      expect(controller.data!.first.feature, 'auth');
      expect(controller.data!.first.tags, ['auth', 'oauth']);

      controller.dispose();
    });

    test('moveIssue() updates status and relocates the issue', () async {
      const issue = Issue(
        id: 'issue-001',
        title: 'Add OAuth login',
        feature: 'user-auth',
        status: IssueStatus.ready,
        createdAt: null,
        tags: ['auth'],
        body: 'Body',
        filePath: r'C:\repo\issues\ready\issue-001.md',
      );
      final repo = FakeIssuesRepository([issue]);
      final controller = IssuesController(repo);
      await controller.load(r'C:\repo');

      await controller.moveIssue(issue, IssueStatus.inprogress);

      expect(repo.lastMovedIssue, issue);
      expect(repo.lastMovedStatus, IssueStatus.inprogress);
      expect(controller.data!.first.status, IssueStatus.inprogress);

      controller.dispose();
    });

    test('toggleAcceptanceCriteria() flips the checkbox at the given index and persists', () async {
      const issue = Issue(
        id: 'issue-001',
        title: 'Add OAuth login',
        feature: 'user-auth',
        status: IssueStatus.ready,
        createdAt: null,
        tags: ['auth'],
        body: '''
## Acceptance criteria

- [ ] First item
- [ ] Second item
''',
        filePath: r'C:\repo\issues\ready\issue-001.md',
      );
      final repo = FakeIssuesRepository([issue]);
      final controller = IssuesController(repo);
      await controller.load(r'C:\repo');

      await controller.toggleAcceptanceCriteria(issue, 1);

      expect(repo.lastUpdatedIssue, issue);
      expect(repo.lastUpdatedBody, contains('- [ ] First item'));
      expect(repo.lastUpdatedBody, contains('- [x] Second item'));
      expect(controller.data!.first.body, contains('- [x] Second item'));

      controller.dispose();
    });

    test('createIssue() persists the new issue and appends it to state', () async {
      const existing = Issue(
        id: 'issue-001',
        title: 'Add OAuth login',
        feature: 'user-auth',
        status: IssueStatus.ready,
        createdAt: null,
        tags: ['auth'],
        body: 'Body',
        filePath: r'C:\repo\issues\ready\issue-001.md',
      );
      final repo = FakeIssuesRepository([existing]);
      final controller = IssuesController(repo);
      await controller.load(r'C:\repo');

      final newIssue = Issue(
        id: 'bug-bug-123',
        title: 'Crash on save',
        feature: 'bug-report',
        status: IssueStatus.backlog,
        createdAt: DateTime(2026, 6, 12),
        tags: const ['bug', 'error'],
        body: '## Message\n\nCrash on save',
        filePath: '',
      );

      await controller.createIssue(r'C:\repo', newIssue);

      expect(repo.lastCreatedLocalPath, r'C:\repo');
      expect(repo.lastCreatedIssue, newIssue);
      expect(controller.data, hasLength(2));
      expect(controller.data!.last.id, 'bug-bug-123');
      expect(controller.data!.last.status, IssueStatus.backlog);
      expect(controller.data!.last.filePath, isNotEmpty);

      controller.dispose();
    });

    test('updateIssueRaw() persists raw content and updates state', () async {
      const issue = Issue(
        id: 'issue-001',
        title: 'Add OAuth login',
        feature: 'user-auth',
        status: IssueStatus.ready,
        createdAt: null,
        tags: ['auth'],
        body: 'Body',
        filePath: r'C:\repo\issues\ready\issue-001.md',
      );
      final repo = FakeIssuesRepository([issue]);
      final controller = IssuesController(repo);
      await controller.load(r'C:\repo');

      const rawContent = '---\nid: issue-001\ntitle: New title\n---\n\nNew body';
      await controller.updateIssueRaw(issue, rawContent);

      expect(repo.lastRawUpdateIssue, issue);
      expect(repo.lastRawUpdateContent, rawContent);
      expect(controller.data!.first.id, 'issue-001');

      controller.dispose();
    });

    test('load() populates folderExists from the repository', () async {
      final repo = FakeIssuesRepository()..folderExists = false;
      final controller = IssuesController(repo);

      await controller.load(r'C:\repo');

      expect(controller.folderExists, isFalse);
      expect(repo.lastFolderExistsCheckLocalPath, r'C:\repo');

      controller.dispose();
    });

    test('initializeIssuesFolder() calls the repository then reloads, flipping folderExists', () async {
      final repo = FakeIssuesRepository()..folderExists = false;
      final controller = IssuesController(repo);
      await controller.load(r'C:\repo');
      expect(controller.folderExists, isFalse);

      var initializeCalled = false;
      repo.initializeIssuesFolderCallback = (localPath) {
        initializeCalled = true;
        repo.folderExists = true;
      };

      await controller.initializeIssuesFolder();

      expect(initializeCalled, isTrue);
      expect(controller.folderExists, isTrue);
      expect(controller.data, isEmpty);

      controller.dispose();
    });

    test('initializeIssuesFolder() is a no-op if load() has not been called yet', () async {
      final repo = FakeIssuesRepository()..folderExists = false;
      final controller = IssuesController(repo);

      await controller.initializeIssuesFolder();

      expect(repo.initializeIssuesFolderCallCount, 0);

      controller.dispose();
    });
  });
}
