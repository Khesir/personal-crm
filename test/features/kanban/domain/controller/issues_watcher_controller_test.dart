import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/features/kanban/domain/controller/issues_controller.dart';
import 'package:crm/features/kanban/domain/controller/issues_watcher_controller.dart';
import 'package:crm/features/kanban/domain/model/issue.dart';
import 'package:crm/features/kanban/domain/repository/issues_repository.dart';

class FakeIssuesRepository implements IssuesRepository {
  List<Issue> issues;
  int getIssuesCallCount = 0;

  FakeIssuesRepository(this.issues);

  @override
  Future<List<Issue>> getIssues(String localPath) async {
    getIssuesCallCount++;
    return issues;
  }

  @override
  Future<List<Issue>> getArchivedIssues(String localPath, String archiveName) async => [];

  @override
  Future<List<String>> listArchives(String localPath) async => [];

  @override
  Future<Issue> updateIssue(
    Issue issue, {
    String? title,
    String? body,
    String? feature,
    List<String>? tags,
  }) async => issue;

  @override
  Future<Issue> moveIssue(Issue issue, IssueStatus newStatus) async => issue;

  @override
  Future<Issue> createIssue(String localPath, Issue issue) async => issue;

  @override
  Future<void> deleteIssue(Issue issue) async {}

  @override
  Future<Issue> updateIssueRaw(Issue issue, String rawContent) async => issue;
}

Issue _issue(String id, String filePath) => Issue(
      id: id,
      title: 'Title $id',
      feature: 'kanban',
      status: IssueStatus.ready,
      createdAt: null,
      tags: const [],
      body: '',
      filePath: filePath,
    );

const _testDebounce = Duration(milliseconds: 50);

void main() {
  group('IssuesWatcherController', () {
    test('a change event triggers a debounced load()', () async {
      final repo = FakeIssuesRepository([_issue('issue-1', '/repo/issues/ready/issue-1.md')]);
      final issuesController = IssuesController(repo);
      final eventsController = StreamController<String>();

      final watcher = IssuesWatcherController(
        issuesController,
        watcherFactory: (_) => eventsController.stream,
        debounceDuration: _testDebounce,
      );

      watcher.start('/repo');
      expect(watcher.state.watching, isTrue);

      eventsController.add('/repo/issues/ready/issue-1.md');
      expect(repo.getIssuesCallCount, 0);

      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(repo.getIssuesCallCount, 1);

      watcher.dispose();
      issuesController.dispose();
      await eventsController.close();
    });

    test('lastSyncedAt and changedIds update after the debounced reload', () async {
      final repo = FakeIssuesRepository([_issue('issue-1', '/repo/issues/ready/issue-1.md')]);
      final issuesController = IssuesController(repo);
      final eventsController = StreamController<String>();

      final watcher = IssuesWatcherController(
        issuesController,
        watcherFactory: (_) => eventsController.stream,
        debounceDuration: _testDebounce,
      );

      watcher.start('/repo');
      expect(watcher.state.lastSyncedAt, isNull);
      expect(watcher.state.changedIds, isEmpty);

      eventsController.add('/repo/issues/ready/issue-1.md');
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(watcher.state.lastSyncedAt, isNotNull);
      expect(watcher.state.changedIds, {'issue-1'});

      watcher.dispose();
      issuesController.dispose();
      await eventsController.close();
    });

    test('a debounced reload calls refresh, not load (no AsyncLoading emission)', () async {
      final repo = FakeIssuesRepository([_issue('issue-1', '/repo/issues/ready/issue-1.md')]);
      final issuesController = IssuesController(repo);
      final eventsController = StreamController<String>();

      final watcher = IssuesWatcherController(
        issuesController,
        watcherFactory: (_) => eventsController.stream,
        debounceDuration: _testDebounce,
      );

      watcher.start('/repo');
      await issuesController.load('/repo');

      final emissions = <AsyncState<List<Issue>>>[];
      final subscription = issuesController.stream.listen(emissions.add);

      eventsController.add('/repo/issues/ready/issue-1.md');
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(emissions, isNotEmpty);
      expect(emissions, everyElement(isA<AsyncData<List<Issue>>>()));
      expect(emissions.any((e) => e is AsyncLoading<List<Issue>>), isFalse);

      await subscription.cancel();
      watcher.dispose();
      issuesController.dispose();
      await eventsController.close();
    });

    test('watching is false and reload does not happen via the watcher when the watcher stream errors', () async {
      final repo = FakeIssuesRepository([_issue('issue-1', '/repo/issues/ready/issue-1.md')]);
      final issuesController = IssuesController(repo);
      final eventsController = StreamController<String>();

      final watcher = IssuesWatcherController(
        issuesController,
        watcherFactory: (_) => eventsController.stream,
        debounceDuration: _testDebounce,
      );

      watcher.start('/repo');
      expect(watcher.state.watching, isTrue);

      eventsController.addError(Exception('watch failed'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(watcher.state.watching, isFalse);
      expect(repo.getIssuesCallCount, 0);

      await issuesController.load('/repo');
      expect(repo.getIssuesCallCount, 1);

      watcher.dispose();
      issuesController.dispose();
      await eventsController.close();
    });

    test('watching is false when the watcher factory throws synchronously', () async {
      final repo = FakeIssuesRepository([_issue('issue-1', '/repo/issues/ready/issue-1.md')]);
      final issuesController = IssuesController(repo);

      final watcher = IssuesWatcherController(
        issuesController,
        watcherFactory: (_) => throw Exception('unsupported platform'),
        debounceDuration: _testDebounce,
      );

      watcher.start('/repo');

      expect(watcher.state.watching, isFalse);
      expect(repo.getIssuesCallCount, 0);

      await issuesController.load('/repo');
      expect(repo.getIssuesCallCount, 1);

      watcher.dispose();
      issuesController.dispose();
    });
  });
}
