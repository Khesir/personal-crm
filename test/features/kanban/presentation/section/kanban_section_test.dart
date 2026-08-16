import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/kanban/domain/controller/issues_controller.dart';
import 'package:crm/features/kanban/domain/model/issue.dart';
import 'package:crm/features/kanban/domain/repository/issues_repository.dart';
import 'package:crm/features/kanban/presentation/section/kanban_section.dart';
import 'package:crm/features/kanban/presentation/widget/kanban_column.dart';

class FakeIssuesRepository implements IssuesRepository {
  List<Issue> issues;
  bool folderExists;

  int initializeIssuesFolderCallCount = 0;
  String? lastInitializedLocalPath;

  /// Called from within [initializeIssuesFolder], before it returns, so
  /// tests can flip [folderExists] the way the real repository would once
  /// the folder is actually scaffolded on disk.
  void Function(String localPath)? onInitialize;

  FakeIssuesRepository({List<Issue>? initial, this.folderExists = true})
    : issues = initial ?? [];

  @override
  Future<List<Issue>> getIssues(String localPath) async => List.unmodifiable(issues);

  @override
  Future<List<Issue>> getArchivedIssues(String localPath, String archiveName) async => [];

  @override
  Future<List<String>> listArchives(String localPath) async => [];

  @override
  Future<Issue> createIssue(String localPath, Issue issue) async {
    issues = [...issues, issue];
    return issue;
  }

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
  Future<void> deleteIssue(Issue issue) async {}

  @override
  Future<Issue> updateIssueRaw(Issue issue, String rawContent) async => issue;

  @override
  Future<void> initializeIssuesFolder(String localPath) async {
    initializeIssuesFolderCallCount++;
    lastInitializedLocalPath = localPath;
    onInitialize?.call(localPath);
  }

  @override
  Future<bool> issuesFolderExists(String localPath) async => folderExists;
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('KanbanSection empty-state / initialize action', () {
    testWidgets(
      'shows "Initialize issues folder" button when issues/ is confirmed absent, not the 5-column board',
      (tester) async {
        final repo = FakeIssuesRepository(folderExists: false);
        final controller = IssuesController(repo);
        await controller.load(r'C:\repo');

        await tester.pumpWidget(_wrap(KanbanSection(controller: controller)));
        await tester.pump();

        expect(find.text('Initialize issues folder'), findsOneWidget);
        expect(find.byType(KanbanColumn), findsNothing);

        controller.dispose();
      },
    );

    testWidgets(
      'shows the normal empty 5-column board (no button) when issues/ exists with zero issues',
      (tester) async {
        final repo = FakeIssuesRepository(folderExists: true);
        final controller = IssuesController(repo);
        await controller.load(r'C:\repo');

        await tester.pumpWidget(_wrap(KanbanSection(controller: controller)));
        await tester.pump();

        expect(find.text('Initialize issues folder'), findsNothing);
        expect(find.byType(KanbanColumn), findsNWidgets(IssueStatus.values.length));

        controller.dispose();
      },
    );

    testWidgets(
      'tapping the button calls initializeIssuesFolder then refreshes so the board shows columns and the button disappears',
      (tester) async {
        final repo = FakeIssuesRepository(folderExists: false);
        repo.onInitialize = (_) => repo.folderExists = true;
        final controller = IssuesController(repo);
        await controller.load(r'C:\repo');

        await tester.pumpWidget(_wrap(KanbanSection(controller: controller)));
        await tester.pump();
        expect(find.text('Initialize issues folder'), findsOneWidget);

        await tester.tap(find.text('Initialize issues folder'));
        await tester.pumpAndSettle();

        expect(repo.initializeIssuesFolderCallCount, 1);
        expect(repo.lastInitializedLocalPath, r'C:\repo');
        expect(controller.folderExists, isTrue);
        expect(find.text('Initialize issues folder'), findsNothing);
        expect(find.byType(KanbanColumn), findsNWidgets(IssueStatus.values.length));

        controller.dispose();
      },
    );
  });
}
