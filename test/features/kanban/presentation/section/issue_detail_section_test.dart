import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/kanban/domain/controller/issues_controller.dart';
import 'package:crm/features/kanban/domain/model/issue.dart';
import 'package:crm/features/kanban/domain/repository/issues_repository.dart';
import 'package:crm/features/kanban/presentation/section/issue_detail_section.dart';
import 'package:crm/features/kanban/presentation/widget/issue_edit_tabs.dart';
import 'package:crm/features/kanban/presentation/widget/markdown_issue_body.dart';

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

  Issue? lastRawUpdateIssue;
  String? lastRawUpdateContent;
  Issue? rawUpdateResult;

  @override
  Future<Issue> updateIssueRaw(Issue issue, String rawContent) async {
    lastRawUpdateIssue = issue;
    lastRawUpdateContent = rawContent;
    final updated = rawUpdateResult ?? issue;
    issues = [
      for (final existing in issues)
        if (existing.id == issue.id) updated else existing,
    ];
    return updated;
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
        onDeleted: () {},
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
        onDeleted: () {},
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
        onDeleted: () {},
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
        onDeleted: () {},
        readOnly: true,
      )));

      expect(find.text('Delete'), findsNothing);

      controller.dispose();
    });
  });

  group('IssueDetailSection edit mode', () {
    late Directory tempDir;
    late Issue issue;
    const rawFileContents = '''
---
id: issue-001
title: Add OAuth login
feature: user-auth
status: ready
created_at: 2026-06-10
tags: [auth]
---

Body''';

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('issue_detail_section_test_');
      final filePath = p.join(tempDir.path, 'issue-001.md');
      File(filePath).writeAsStringSync(rawFileContents);
      issue = Issue(
        id: 'issue-001',
        title: 'Add OAuth login',
        feature: 'user-auth',
        status: IssueStatus.ready,
        createdAt: DateTime(2026, 6, 10),
        tags: const ['auth'],
        body: 'Body',
        filePath: filePath,
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    testWidgets('tapping Edit enters edit mode and hides the title row', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = FakeIssuesRepository([issue]);
      final controller = IssuesController(repo);
      await controller.load(tempDir.path);

      await tester.pumpWidget(_wrap(IssueDetailSection(
        controller: controller,
        issue: issue,
        onBack: () {},
        onDeleted: () {},
      )));

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text(issue.title), findsNothing);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Commit changes'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      expect(find.widgetWithText(TextField, rawFileContents), findsOneWidget);

      controller.dispose();
    });

    testWidgets('tapping Commit with valid text calls controller and returns to read view', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = FakeIssuesRepository([issue]);
      final updatedIssue = Issue(
        id: issue.id,
        title: 'Add OAuth login (v2)',
        feature: issue.feature,
        status: issue.status,
        createdAt: issue.createdAt,
        tags: issue.tags,
        body: 'Updated body',
        filePath: issue.filePath,
      );
      repo.rawUpdateResult = updatedIssue;
      final controller = IssuesController(repo);
      await controller.load(tempDir.path);

      await tester.pumpWidget(_wrap(IssueDetailSection(
        controller: controller,
        issue: issue,
        onBack: () {},
        onDeleted: () {},
      )));

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      const newRawContent = '''
---
id: issue-001
title: Add OAuth login (v2)
feature: user-auth
status: ready
created_at: 2026-06-10
tags: [auth]
---

Updated body''';
      await tester.enterText(find.byType(TextField), newRawContent);
      await tester.tap(find.text('Commit changes'));
      await tester.pumpAndSettle();

      expect(repo.lastRawUpdateIssue, issue);
      expect(repo.lastRawUpdateContent, newRawContent);
      expect(find.text('Cancel'), findsNothing);
      expect(find.text('Commit changes'), findsNothing);
      expect(find.text('Edit'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('tapping Commit with malformed raw text shows an inline error and blocks commit', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = FakeIssuesRepository([issue]);
      final controller = IssuesController(repo);
      await controller.load(tempDir.path);

      await tester.pumpWidget(_wrap(IssueDetailSection(
        controller: controller,
        issue: issue,
        onBack: () {},
        onDeleted: () {},
      )));

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'not even frontmatter');
      await tester.tap(find.text('Commit changes'));
      await tester.pumpAndSettle();

      expect(repo.lastRawUpdateIssue, isNull);
      expect(find.text('Commit changes'), findsOneWidget);
      expect(find.text('Could not parse this content. Check the frontmatter and try again.'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('tapping Commit with id changed shows an inline error and blocks commit', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = FakeIssuesRepository([issue]);
      final controller = IssuesController(repo);
      await controller.load(tempDir.path);

      await tester.pumpWidget(_wrap(IssueDetailSection(
        controller: controller,
        issue: issue,
        onBack: () {},
        onDeleted: () {},
      )));

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      const newRawContent = '''
---
id: issue-999
title: Add OAuth login
feature: user-auth
status: ready
created_at: 2026-06-10
tags: [auth]
---

Body''';
      await tester.enterText(find.byType(TextField), newRawContent);
      await tester.tap(find.text('Commit changes'));
      await tester.pumpAndSettle();

      expect(repo.lastRawUpdateIssue, isNull);
      expect(find.text('Commit changes'), findsOneWidget);
      expect(find.text('`id` cannot be changed.'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('tapping Commit with created_at changed shows an inline error and blocks commit', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = FakeIssuesRepository([issue]);
      final controller = IssuesController(repo);
      await controller.load(tempDir.path);

      await tester.pumpWidget(_wrap(IssueDetailSection(
        controller: controller,
        issue: issue,
        onBack: () {},
        onDeleted: () {},
      )));

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      const newRawContent = '''
---
id: issue-001
title: Add OAuth login
feature: user-auth
status: ready
created_at: 2026-01-01
tags: [auth]
---

Body''';
      await tester.enterText(find.byType(TextField), newRawContent);
      await tester.tap(find.text('Commit changes'));
      await tester.pumpAndSettle();

      expect(repo.lastRawUpdateIssue, isNull);
      expect(find.text('Commit changes'), findsOneWidget);
      expect(find.text('`created_at` cannot be changed.'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('tapping Commit with status changed shows an inline error and blocks commit', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = FakeIssuesRepository([issue]);
      final controller = IssuesController(repo);
      await controller.load(tempDir.path);

      await tester.pumpWidget(_wrap(IssueDetailSection(
        controller: controller,
        issue: issue,
        onBack: () {},
        onDeleted: () {},
      )));

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      const newRawContent = '''
---
id: issue-001
title: Add OAuth login
feature: user-auth
status: done
created_at: 2026-06-10
tags: [auth]
---

Body''';
      await tester.enterText(find.byType(TextField), newRawContent);
      await tester.tap(find.text('Commit changes'));
      await tester.pumpAndSettle();

      expect(repo.lastRawUpdateIssue, isNull);
      expect(find.text('Commit changes'), findsOneWidget);
      expect(find.text('`status` cannot be changed here. Use the status picker instead.'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('tapping Cancel discards and returns to read view without calling the controller', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = FakeIssuesRepository([issue]);
      final controller = IssuesController(repo);
      await controller.load(tempDir.path);

      await tester.pumpWidget(_wrap(IssueDetailSection(
        controller: controller,
        issue: issue,
        onBack: () {},
        onDeleted: () {},
      )));

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'discarded content');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repo.lastRawUpdateIssue, isNull);
      expect(find.text(issue.title), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Edit is not rendered at all when readOnly', (tester) async {
      final repo = FakeIssuesRepository([issue]);
      final controller = IssuesController(repo);
      await controller.load(tempDir.path);

      await tester.pumpWidget(_wrap(IssueDetailSection(
        controller: controller,
        issue: issue,
        onBack: () {},
        onDeleted: () {},
        readOnly: true,
      )));

      expect(find.text('Edit'), findsNothing);

      controller.dispose();
    });
  });

  group('IssueDetailSection preview tab', () {
    late Directory tempDir;
    late Issue issue;
    const rawFileContents = '''
---
id: issue-001
title: Add OAuth login
feature: user-auth
status: ready
created_at: 2026-06-10
tags: [auth]
---

## Acceptance criteria

- [ ] First criterion
- [x] Second criterion''';

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('issue_detail_section_preview_test_');
      final filePath = p.join(tempDir.path, 'issue-001.md');
      File(filePath).writeAsStringSync(rawFileContents);
      issue = Issue(
        id: 'issue-001',
        title: 'Add OAuth login',
        feature: 'user-auth',
        status: IssueStatus.ready,
        createdAt: DateTime(2026, 6, 10),
        tags: const ['auth'],
        body: '## Acceptance criteria\n\n- [ ] First criterion\n- [x] Second criterion',
        filePath: filePath,
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    Future<void> enterEditMode(WidgetTester tester, Issue issue) async {
      final repo = FakeIssuesRepository([issue]);
      final controller = IssuesController(repo);
      await controller.load(tempDir.path);

      await tester.pumpWidget(_wrap(IssueDetailSection(
        controller: controller,
        issue: issue,
        onBack: () {},
        onDeleted: () {},
      )));

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows Write and Preview tabs while in edit mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await enterEditMode(tester, issue);

      expect(find.text('Write'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);

      final controller = (tester.widget(find.byType(IssueDetailSection)) as IssueDetailSection).controller;
      controller.dispose();
    });

    testWidgets('editor panel renders a visible border framing the tabs, toolbar, and content', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await enterEditMode(tester, issue);

      final panel = tester.widget<Container>(
        find.descendant(of: find.byType(IssueEditTabs), matching: find.byType(Container)).first,
      );
      final panelDecoration = panel.decoration as BoxDecoration;
      expect(panelDecoration.border, isNotNull);
      expect(panelDecoration.border?.top.color, AppColors.borderStrong);

      final tabBar = tester.widget<Container>(
        find.ancestor(of: find.text('Write'), matching: find.byType(Container)).last,
      );
      final tabBarDecoration = tabBar.decoration as BoxDecoration;
      expect(tabBarDecoration.border?.bottom.color, AppColors.borderStrong);

      final controller = (tester.widget(find.byType(IssueDetailSection)) as IssueDetailSection).controller;
      controller.dispose();
    });

    testWidgets('Write tab shows the raw textarea exactly as in issue 001', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await enterEditMode(tester, issue);

      expect(find.widgetWithText(TextField, rawFileContents), findsOneWidget);

      final controller = (tester.widget(find.byType(IssueDetailSection)) as IssueDetailSection).controller;
      controller.dispose();
    });

    testWidgets('switching to Preview renders the body without the frontmatter block', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await enterEditMode(tester, issue);

      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      final preview = tester.widget<MarkdownIssueBody>(find.byType(MarkdownIssueBody));
      expect(preview.content, isNot(contains('id: issue-001')));
      expect(preview.content, isNot(contains('---')));
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('Acceptance criteria'), findsOneWidget);

      final controller = (tester.widget(find.byType(IssueDetailSection)) as IssueDetailSection).controller;
      controller.dispose();
    });

    testWidgets('acceptance criteria items in Preview are plain text, not interactive checkboxes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await enterEditMode(tester, issue);

      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsNothing);
      expect(find.textContaining('First criterion'), findsOneWidget);
      expect(find.textContaining('Second criterion'), findsOneWidget);

      final controller = (tester.widget(find.byType(IssueDetailSection)) as IssueDetailSection).controller;
      controller.dispose();
    });

    testWidgets('typing in Write and switching to Preview reflects the typed content', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await enterEditMode(tester, issue);

      const editedContent = '''
---
id: issue-001
title: Add OAuth login
feature: user-auth
status: ready
created_at: 2026-06-10
tags: [auth]
---

Freshly typed body content''';
      await tester.enterText(find.byType(TextField), editedContent);
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Freshly typed body content'), findsOneWidget);

      final controller = (tester.widget(find.byType(IssueDetailSection)) as IssueDetailSection).controller;
      controller.dispose();
    });

    testWidgets('switching back to Write preserves the typed content', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await enterEditMode(tester, issue);

      const editedContent = '''
---
id: issue-001
title: Add OAuth login
feature: user-auth
status: ready
created_at: 2026-06-10
tags: [auth]
---

Round trip body content''';
      await tester.enterText(find.byType(TextField), editedContent);
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Write'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, editedContent), findsOneWidget);

      final controller = (tester.widget(find.byType(IssueDetailSection)) as IssueDetailSection).controller;
      controller.dispose();
    });

    testWidgets('malformed raw text in Preview falls back gracefully instead of crashing', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await enterEditMode(tester, issue);

      await tester.enterText(find.byType(TextField), 'not even frontmatter');
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('not even frontmatter'), findsOneWidget);

      final controller = (tester.widget(find.byType(IssueDetailSection)) as IssueDetailSection).controller;
      controller.dispose();
    });
  });

  group('IssueDetailSection markdown formatting toolbar', () {
    late Directory tempDir;
    late Issue issue;
    const rawFileContents = '''
---
id: issue-001
title: Add OAuth login
feature: user-auth
status: ready
created_at: 2026-06-10
tags: [auth]
---

hello world''';

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('issue_detail_section_toolbar_test_');
      final filePath = p.join(tempDir.path, 'issue-001.md');
      File(filePath).writeAsStringSync(rawFileContents);
      issue = Issue(
        id: 'issue-001',
        title: 'Add OAuth login',
        feature: 'user-auth',
        status: IssueStatus.ready,
        createdAt: DateTime(2026, 6, 10),
        tags: const ['auth'],
        body: 'hello world',
        filePath: filePath,
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    Future<IssuesController> enterEditMode(WidgetTester tester, Issue issue) async {
      final repo = FakeIssuesRepository([issue]);
      final controller = IssuesController(repo);
      await controller.load(tempDir.path);

      await tester.pumpWidget(_wrap(IssueDetailSection(
        controller: controller,
        issue: issue,
        onBack: () {},
        onDeleted: () {},
      )));

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('shows all eight formatting icons during edit mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = await enterEditMode(tester, issue);

      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      expect(find.byIcon(Icons.format_italic), findsOneWidget);
      expect(find.byIcon(Icons.format_quote), findsOneWidget);
      expect(find.byIcon(Icons.code), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
      expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);
      expect(find.byIcon(Icons.checklist), findsOneWidget);

      controller.dispose();
    });

    testWidgets('tapping Bold with a selection wraps it in ** **', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = await enterEditMode(tester, issue);

      final textField = tester.widget<TextField>(find.byType(TextField));
      final editingController = textField.controller!;
      final helloIndex = editingController.text.indexOf('hello world');
      editingController.selection = TextSelection(
        baseOffset: helloIndex,
        extentOffset: helloIndex + 'hello'.length,
      );

      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      expect(editingController.text, contains('**hello** world'));

      controller.dispose();
    });

    testWidgets('tapping Bulleted list prefixes the current line with - ', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = await enterEditMode(tester, issue);

      final textField = tester.widget<TextField>(find.byType(TextField));
      final editingController = textField.controller!;
      final helloIndex = editingController.text.indexOf('hello world');
      editingController.selection = TextSelection.collapsed(offset: helloIndex);

      await tester.tap(find.byIcon(Icons.format_list_bulleted));
      await tester.pumpAndSettle();

      expect(editingController.text, contains('- hello world'));

      controller.dispose();
    });

    testWidgets('toolbar is not shown in Preview tab', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = await enterEditMode(tester, issue);

      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.format_bold), findsNothing);

      controller.dispose();
    });
  });

  group('IssueDetailSection unsaved-changes guard', () {
    late Directory tempDir;
    late Issue issue;
    const rawFileContents = '''
---
id: issue-001
title: Add OAuth login
feature: user-auth
status: ready
created_at: 2026-06-10
tags: [auth]
---

hello world''';

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('issue_detail_section_unsaved_guard_test_');
      final filePath = p.join(tempDir.path, 'issue-001.md');
      File(filePath).writeAsStringSync(rawFileContents);
      issue = Issue(
        id: 'issue-001',
        title: 'Add OAuth login',
        feature: 'user-auth',
        status: IssueStatus.ready,
        createdAt: DateTime(2026, 6, 10),
        tags: const ['auth'],
        body: 'hello world',
        filePath: filePath,
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    Future<IssuesController> enterEditMode(WidgetTester tester, Issue issue, {required VoidCallback onBack}) async {
      final repo = FakeIssuesRepository([issue]);
      final controller = IssuesController(repo);
      await controller.load(tempDir.path);

      await tester.pumpWidget(_wrap(IssueDetailSection(
        controller: controller,
        issue: issue,
        onBack: onBack,
        onDeleted: () {},
      )));

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('tapping Back to board with unsaved changes shows the discard-changes dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var backCalled = false;
      final controller = await enterEditMode(tester, issue, onBack: () => backCalled = true);

      await tester.enterText(find.byType(TextField), 'edited content');
      await tester.tap(find.text('Back to board'));
      await tester.pumpAndSettle();

      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      expect(backCalled, isFalse);

      controller.dispose();
    });

    testWidgets('confirming the discard-changes dialog calls onBack', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var backCalled = false;
      final controller = await enterEditMode(tester, issue, onBack: () => backCalled = true);

      await tester.enterText(find.byType(TextField), 'edited content');
      await tester.tap(find.text('Back to board'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(backCalled, isTrue);

      controller.dispose();
    });

    testWidgets('cancelling the discard-changes dialog keeps edit mode with typed text intact', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var backCalled = false;
      final controller = await enterEditMode(tester, issue, onBack: () => backCalled = true);

      await tester.enterText(find.byType(TextField), 'edited content');
      await tester.tap(find.text('Back to board'));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Cancel'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Discard unsaved changes?'), findsNothing);
      expect(backCalled, isFalse);
      expect(find.widgetWithText(TextField, 'edited content'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Commit changes'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('tapping Back to board with no unsaved changes navigates immediately with no dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var backCalled = false;
      final controller = await enterEditMode(tester, issue, onBack: () => backCalled = true);

      await tester.tap(find.text('Back to board'));
      await tester.pumpAndSettle();

      expect(find.text('Discard unsaved changes?'), findsNothing);
      expect(backCalled, isTrue);

      controller.dispose();
    });

    testWidgets('tapping Cancel never shows the discard-changes dialog regardless of unsaved changes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var backCalled = false;
      final controller = await enterEditMode(tester, issue, onBack: () => backCalled = true);

      await tester.enterText(find.byType(TextField), 'edited content');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Discard unsaved changes?'), findsNothing);
      expect(backCalled, isFalse);
      expect(find.text('Edit'), findsOneWidget);

      controller.dispose();
    });
  });
}
