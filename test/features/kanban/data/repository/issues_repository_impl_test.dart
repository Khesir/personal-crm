import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:crm/features/kanban/data/repository/issues_repository_impl.dart';
import 'package:crm/features/kanban/domain/model/issue.dart';

void main() {
  group('IssuesRepositoryImpl', () {
    late Directory tempDir;
    late IssuesRepositoryImpl repository;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('issues_repo_test_');
      repository = IssuesRepositoryImpl();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    void writeIssue(String folder, String fileName, String contents) {
      final dir = Directory(p.join(tempDir.path, 'issues', folder));
      dir.createSync(recursive: true);
      File(p.join(dir.path, fileName)).writeAsStringSync(contents);
    }

    void writeArchivedIssue(
      String archiveName,
      String folder,
      String fileName,
      String contents,
    ) {
      final dir = Directory(
        p.join(tempDir.path, 'issues', 'archive', archiveName, folder),
      );
      dir.createSync(recursive: true);
      File(p.join(dir.path, fileName)).writeAsStringSync(contents);
    }

    test('returns empty list when issues folder does not exist', () async {
      final issues = await repository.getIssues(tempDir.path);

      expect(issues, isEmpty);
    });

    test('parses a single issue with full frontmatter', () async {
      writeIssue('ready', 'issue-044.md', '''
---
id: issue-044
title: Add OAuth login
feature: user-auth
status: ready
created_at: 2026-06-10
tags: [auth, backend]
---

## Description
Body text here.
''');

      final issues = await repository.getIssues(tempDir.path);

      expect(issues, hasLength(1));
      final issue = issues.first;
      expect(issue.id, 'issue-044');
      expect(issue.title, 'Add OAuth login');
      expect(issue.feature, 'user-auth');
      expect(issue.status, IssueStatus.ready);
      expect(issue.createdAt, DateTime(2026, 6, 10));
      expect(issue.tags, ['auth', 'backend']);
      expect(issue.body.trim(), '## Description\nBody text here.');
    });

    test('skips markdown files without a frontmatter block', () async {
      writeIssue('backlog', '001-no-frontmatter.md', '''
# [001] Title without frontmatter

**Type:** AFK
**Priority:** P1

---

## What to build
Something.
''');

      final issues = await repository.getIssues(tempDir.path);

      expect(issues, isEmpty);
    });

    test('reads issues from the in-progress folder as IssueStatus.inprogress', () async {
      writeIssue('in-progress', 'issue-005.md', '''
---
id: issue-005
title: Kanban board
feature: kanban
status: inprogress
created_at: 2026-06-12
tags: []
---

Body.
''');

      final issues = await repository.getIssues(tempDir.path);

      expect(issues, hasLength(1));
      expect(issues.first.status, IssueStatus.inprogress);
      expect(issues.first.tags, isEmpty);
    });

    test('groups issues from multiple status folders', () async {
      writeIssue('backlog', 'issue-001.md', '''
---
id: issue-001
title: Backlog issue
feature: core
status: backlog
created_at: 2026-06-01
tags: []
---
Body.
''');
      writeIssue('done', 'issue-002.md', '''
---
id: issue-002
title: Done issue
feature: core
status: done
created_at: 2026-06-02
tags: []
---
Body.
''');

      final issues = await repository.getIssues(tempDir.path);

      expect(issues, hasLength(2));
      expect(issues.map((i) => i.status), containsAll([IssueStatus.backlog, IssueStatus.done]));
    });

    test('getArchivedIssues() parses a single issue from an archive folder', () async {
      writeArchivedIssue('2026-06-12-dev-command-center', 'done', 'issue-001.md', '''
---
id: issue-001
title: Shell rewrite and theme
feature: shell
status: done
created_at: 2026-06-01
tags: [ui]
---

## Description
Body text here.
''');

      final issues = await repository.getArchivedIssues(
        tempDir.path,
        '2026-06-12-dev-command-center',
      );

      expect(issues, hasLength(1));
      final issue = issues.first;
      expect(issue.id, 'issue-001');
      expect(issue.title, 'Shell rewrite and theme');
      expect(issue.feature, 'shell');
      expect(issue.status, IssueStatus.done);
      expect(issue.createdAt, DateTime(2026, 6, 1));
      expect(issue.tags, ['ui']);
      expect(issue.body.trim(), '## Description\nBody text here.');
    });

    test('getArchivedIssues() groups issues from multiple status folders and skips files without frontmatter', () async {
      writeArchivedIssue('2026-06-12-dev-command-center', 'done', 'issue-001.md', '''
---
id: issue-001
title: Shell rewrite and theme
feature: shell
status: done
created_at: 2026-06-01
tags: []
---
Body.
''');
      writeArchivedIssue('2026-06-12-dev-command-center', 'backlog', 'issue-002.md', '''
---
id: issue-002
title: Backlog issue
feature: core
status: backlog
created_at: 2026-06-02
tags: []
---
Body.
''');
      writeArchivedIssue('2026-06-12-dev-command-center', 'done', '003-no-frontmatter.md', '''
# [003] Title without frontmatter

Some text without a frontmatter block.
''');

      final issues = await repository.getArchivedIssues(
        tempDir.path,
        '2026-06-12-dev-command-center',
      );

      expect(issues, hasLength(2));
      expect(issues.map((i) => i.status), containsAll([IssueStatus.backlog, IssueStatus.done]));
    });

    test('getArchivedIssues() returns empty list when the archive does not exist', () async {
      final issues = await repository.getArchivedIssues(
        tempDir.path,
        '2026-06-12-dev-command-center',
      );

      expect(issues, isEmpty);
    });

    test('listArchives() returns empty list when issues/archive does not exist', () async {
      final archives = await repository.listArchives(tempDir.path);

      expect(archives, isEmpty);
    });

    test('listArchives() returns archive folder names sorted descending', () async {
      Directory(
        p.join(tempDir.path, 'issues', 'archive', '2026-06-12-dev-command-center'),
      ).createSync(recursive: true);
      Directory(
        p.join(tempDir.path, 'issues', 'archive', '2026-01-01-early-feature'),
      ).createSync(recursive: true);
      Directory(
        p.join(tempDir.path, 'issues', 'archive', '2026-09-30-later-feature'),
      ).createSync(recursive: true);

      final archives = await repository.listArchives(tempDir.path);

      expect(archives, [
        '2026-09-30-later-feature',
        '2026-06-12-dev-command-center',
        '2026-01-01-early-feature',
      ]);
    });

    test('updateIssue() persists field changes to the file', () async {
      writeIssue('ready', 'issue-044.md', '''
---
id: issue-044
title: Add OAuth login
feature: user-auth
status: ready
created_at: 2026-06-10
tags: [auth, backend]
---

## Description
Body text here.
''');
      final issues = await repository.getIssues(tempDir.path);
      final issue = issues.first;

      final updated = await repository.updateIssue(
        issue,
        title: 'Add OAuth login (v2)',
        feature: 'auth',
        tags: ['auth', 'oauth'],
        body: '## Description\nUpdated body.',
      );

      expect(updated.title, 'Add OAuth login (v2)');
      expect(updated.feature, 'auth');
      expect(updated.tags, ['auth', 'oauth']);
      expect(updated.body, '## Description\nUpdated body.');

      final reloaded = await repository.getIssues(tempDir.path);
      expect(reloaded.first.title, 'Add OAuth login (v2)');
      expect(reloaded.first.feature, 'auth');
      expect(reloaded.first.tags, ['auth', 'oauth']);
      expect(reloaded.first.body, '## Description\nUpdated body.');
    });

    test('moveIssue() relocates the file and updates status frontmatter', () async {
      writeIssue('ready', 'issue-044.md', '''
---
id: issue-044
title: Add OAuth login
feature: user-auth
status: ready
created_at: 2026-06-10
tags: [auth, backend]
---

## Description
Body text here.
''');
      final issues = await repository.getIssues(tempDir.path);
      final issue = issues.first;

      final moved = await repository.moveIssue(issue, IssueStatus.inprogress);

      expect(moved.status, IssueStatus.inprogress);
      expect(moved.filePath, contains('in-progress'));
      expect(File(issue.filePath).existsSync(), isFalse);
      expect(File(moved.filePath).existsSync(), isTrue);

      final reloaded = await repository.getIssues(tempDir.path);
      expect(reloaded, hasLength(1));
      expect(reloaded.first.status, IssueStatus.inprogress);
    });

    test('createIssue() writes a new file into issues/backlog/', () async {
      final issue = Issue(
        id: 'bug-bug-123',
        title: 'Crash on save',
        feature: 'bug-report',
        status: IssueStatus.backlog,
        createdAt: DateTime(2026, 6, 12),
        tags: const ['bug', 'error'],
        body: '## Message\n\nCrash on save\n\n## Stack Trace\n\n```\nat foo()\n```',
        filePath: '',
      );

      final created = await repository.createIssue(tempDir.path, issue);

      expect(created.status, IssueStatus.backlog);
      expect(created.filePath, contains('backlog'));
      expect(File(created.filePath).existsSync(), isTrue);

      final reloaded = await repository.getIssues(tempDir.path);
      expect(reloaded, hasLength(1));
      final reloadedIssue = reloaded.first;
      expect(reloadedIssue.id, 'bug-bug-123');
      expect(reloadedIssue.title, 'Crash on save');
      expect(reloadedIssue.feature, 'bug-report');
      expect(reloadedIssue.status, IssueStatus.backlog);
      expect(reloadedIssue.createdAt, DateTime(2026, 6, 12));
      expect(reloadedIssue.tags, ['bug', 'error']);
      expect(reloadedIssue.body, contains('Crash on save'));
      expect(reloadedIssue.body, contains('## Stack Trace'));
      expect(reloadedIssue.body, contains('at foo()'));
    });

    test('updateIssueRaw() overwrites the file with raw content and re-parses it', () async {
      writeIssue('ready', 'issue-044.md', '''
---
id: issue-044
title: Add OAuth login
feature: user-auth
status: ready
created_at: 2026-06-10
tags: [auth, backend]
---

## Description
Body text here.
''');
      final issues = await repository.getIssues(tempDir.path);
      final issue = issues.first;

      const newRawContent = '''
---
id: issue-044
title: Add OAuth login (v2)
feature: auth
status: ready
created_at: 2026-06-10
tags: [auth, oauth]
---

## Description
Updated body.
''';

      final updated = await repository.updateIssueRaw(issue, newRawContent);

      expect(File(issue.filePath).readAsStringSync(), newRawContent);
      expect(updated.id, 'issue-044');
      expect(updated.title, 'Add OAuth login (v2)');
      expect(updated.feature, 'auth');
      expect(updated.status, IssueStatus.ready);
      expect(updated.tags, ['auth', 'oauth']);
      expect(updated.body.trim(), '## Description\nUpdated body.');
      expect(updated.filePath, issue.filePath);
    });

    test('initializeIssuesFolder() creates all five status folders', () async {
      await repository.initializeIssuesFolder(tempDir.path);

      for (final folder in ['backlog', 'ready', 'in-progress', 'qa', 'done']) {
        expect(
          Directory(p.join(tempDir.path, 'issues', folder)).existsSync(),
          isTrue,
          reason: '$folder folder should exist',
        );
      }
    });

    test('initializeIssuesFolder() is idempotent and does not clobber existing files', () async {
      await repository.initializeIssuesFolder(tempDir.path);
      final markerFile = File(p.join(tempDir.path, 'issues', 'backlog', 'issue-001.md'));
      await markerFile.writeAsString('existing content');

      await repository.initializeIssuesFolder(tempDir.path);

      expect(markerFile.existsSync(), isTrue);
      expect(await markerFile.readAsString(), 'existing content');
      for (final folder in ['backlog', 'ready', 'in-progress', 'qa', 'done']) {
        expect(Directory(p.join(tempDir.path, 'issues', folder)).existsSync(), isTrue);
      }
    });

    test('issuesFolderExists() returns false when issues/ does not exist', () async {
      final exists = await repository.issuesFolderExists(tempDir.path);

      expect(exists, isFalse);
    });

    test('issuesFolderExists() returns true when issues/ exists', () async {
      await repository.initializeIssuesFolder(tempDir.path);

      final exists = await repository.issuesFolderExists(tempDir.path);

      expect(exists, isTrue);
    });

    test('issuesFolderExists() returns true even when issues/ exists but has no status folders', () async {
      Directory(p.join(tempDir.path, 'issues')).createSync(recursive: true);

      final exists = await repository.issuesFolderExists(tempDir.path);

      expect(exists, isTrue);
    });
  });
}
