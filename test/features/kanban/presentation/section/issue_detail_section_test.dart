import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/features/kanban/domain/controller/issues_controller.dart';
import 'package:crm/features/kanban/domain/model/issue.dart';
import 'package:crm/features/kanban/domain/repository/issues_repository.dart';
import 'package:crm/features/kanban/presentation/section/issue_detail_section.dart';

class FakeIssuesRepository implements IssuesRepository {
  List<Issue> issues;
  Issue? lastDeletedIssue;

  FakeIssuesRepository(this.issues);

  @override
  Future<List<Issue>> getIssues(String localPath) async => List.unmodifiable(issues);

  @override
  Future<List<Issue>> getArchivedIssues(String localPath, String archiveName) async => [];

  @override
  Future<List<String>> listArchives(String localPath) async => [];

  @override
  Future<Issue> createIssue(String localPath, Issue issue) async => issue;

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
  Future<void> deleteIssue(Issue issue) async {
    lastDeletedIssue = issue;
    issues = [
      for (final existing in issues)
        if (existing.id != issue.id) existing,
    ];
  }
}

const _issue = Issue(
  id: 'issue-001',
  title: 'Add OAuth login',
  feature: 'user-auth',
  status: IssueStatus.ready,
  createdAt: null,
  tags: ['auth'],
  body: 'Body',
  filePath: r'C:\repo\issues\ready\issue-001.md',
);

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('IssueDetailSection delete action', () {
    testWidgets('shows a confirmation dialog when delete is tapped', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = FakeIssuesRepository([_issue]);
      final controller = IssuesController(repo);
      await controller.load(r'C:\repo');

      await tester.pumpWidget(_wrap(IssueDetailSection(
        controller: controller,
        issue: _issue,
        onBack: () {},
        onRunSkill: () {}, onDeleted: () {},
      )));

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.textContaining("Delete issue?"), findsOneWidget);
      expect(find.textContaining("This can't be undone"), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('cancelling the dialog leaves the issue untouched', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = FakeIssuesRepository([_issue]);
      final controller = IssuesController(repo);
      await controller.load(r'C:\repo');
      var backCalled = false;

      await tester.pumpWidget(_wrap(IssueDetailSection(
        controller: controller,
        issue: _issue,
        onBack: () => backCalled = true,
        onRunSkill: () {}, onDeleted: () {},
      )));

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.textContaining("Delete issue?"), findsNothing);
      expect(repo.lastDeletedIssue, isNull);
      expect(backCalled, isFalse);
      expect(controller.data, hasLength(1));

      controller.dispose();
    });

    testWidgets('confirming the dialog deletes the issue and triggers onBack', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = FakeIssuesRepository([_issue]);
      final controller = IssuesController(repo);
      await controller.load(r'C:\repo');
      var backCalled = false;

      await tester.pumpWidget(_wrap(IssueDetailSection(
        controller: controller,
        issue: _issue,
        onBack: () => backCalled = true,
        onRunSkill: () {}, onDeleted: () {},
      )));

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Delete'),
      ));
      await tester.pumpAndSettle();

      expect(repo.lastDeletedIssue, _issue);
      expect(controller.data, isEmpty);
      expect(backCalled, isTrue);

      controller.dispose();
    });

    testWidgets('delete action is hidden when readOnly', (tester) async {
      final repo = FakeIssuesRepository([_issue]);
      final controller = IssuesController(repo);
      await controller.load(r'C:\repo');

      await tester.pumpWidget(_wrap(IssueDetailSection(
        controller: controller,
        issue: _issue,
        onBack: () {},
        onRunSkill: () {}, onDeleted: () {},
        readOnly: true,
      )));

      expect(find.text('Delete'), findsNothing);

      controller.dispose();
    });
  });
}
