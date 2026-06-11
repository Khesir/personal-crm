import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/kanban/data/datasource/issue_frontmatter_writer.dart';
import 'package:crm/features/kanban/domain/model/issue.dart';

void main() {
  group('IssueFrontmatterWriter', () {
    const writer = IssueFrontmatterWriter();
    const original = '''
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
''';

    test('updates title while preserving other frontmatter fields', () {
      final result = writer.write(original, title: 'Add OAuth login (v2)');

      expect(result, contains('title: Add OAuth login (v2)'));
      expect(result, contains('id: issue-044'));
      expect(result, contains('feature: user-auth'));
      expect(result, contains('status: ready'));
      expect(result, contains('created_at: 2026-06-10'));
      expect(result, contains('tags: [auth, backend]'));
      expect(result, contains('## Description\nBody text here.'));
    });

    test('updates feature field', () {
      final result = writer.write(original, feature: 'auth');

      expect(result, contains('feature: auth'));
      expect(result, contains('title: Add OAuth login'));
    });

    test('updates tags as a flow list', () {
      final result = writer.write(original, tags: ['auth', 'oauth', 'security']);

      expect(result, contains('tags: [auth, oauth, security]'));
    });

    test('updates body content', () {
      final result = writer.write(original, body: '## New body\nReplaced.');

      expect(result, contains('## New body\nReplaced.'));
      expect(result, isNot(contains('Body text here.')));
      expect(result, contains('title: Add OAuth login'));
    });

    test('updates status field for moveIssue', () {
      final result = writer.write(original, status: IssueStatus.inprogress);

      expect(result, contains('status: inprogress'));
    });

    test('returns contents unchanged when no frontmatter block exists', () {
      const noFrontmatter = '# Just a heading\n\nSome body.';

      final result = writer.write(noFrontmatter, title: 'New title');

      expect(result, noFrontmatter);
    });

    test('quotes title values containing YAML special characters', () {
      final result = writer.write(original, title: 'Fix: bug in parser');

      expect(result, contains('title: "Fix: bug in parser"'));
    });
  });
}
