import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/kanban/domain/helper/issue_raw_edit_validator.dart';
import 'package:crm/features/kanban/domain/model/issue.dart';

void main() {
  final original = Issue(
    id: 'issue-001',
    title: 'Add OAuth login',
    feature: 'user-auth',
    status: IssueStatus.ready,
    createdAt: DateTime(2026, 6, 10),
    tags: const ['auth'],
    body: 'Body',
    filePath: r'C:\repo\issues\ready\issue-001.md',
  );

  group('validateIssueRawEdit', () {
    test('valid edit with title/feature/tags/body changed succeeds with parsed Issue', () {
      const rawContent = '''
---
id: issue-001
title: Add OAuth login (v2)
feature: auth-revamp
status: ready
created_at: 2026-06-10
tags: [auth, security]
---

Updated body''';

      final result = validateIssueRawEdit(original, rawContent);

      expect(result, isA<IssueRawEditSuccess>());
      final issue = (result as IssueRawEditSuccess).issue;
      expect(issue.title, 'Add OAuth login (v2)');
      expect(issue.feature, 'auth-revamp');
      expect(issue.tags, ['auth', 'security']);
      expect(issue.body, 'Updated body');
      expect(issue.id, original.id);
      expect(issue.createdAt, original.createdAt);
      expect(issue.status, original.status);
    });

    test('malformed frontmatter fails with parseError', () {
      const rawContent = 'not even frontmatter';

      final result = validateIssueRawEdit(original, rawContent);

      expect(result, isA<IssueRawEditFailure>());
      expect((result as IssueRawEditFailure).reason, IssueRawEditFailureReason.parseError);
    });

    test('id changed fails with idChanged', () {
      const rawContent = '''
---
id: issue-999
title: Add OAuth login
feature: user-auth
status: ready
created_at: 2026-06-10
tags: [auth]
---

Body''';

      final result = validateIssueRawEdit(original, rawContent);

      expect(result, isA<IssueRawEditFailure>());
      expect((result as IssueRawEditFailure).reason, IssueRawEditFailureReason.idChanged);
    });

    test('createdAt changed fails with createdAtChanged', () {
      const rawContent = '''
---
id: issue-001
title: Add OAuth login
feature: user-auth
status: ready
created_at: 2026-01-01
tags: [auth]
---

Body''';

      final result = validateIssueRawEdit(original, rawContent);

      expect(result, isA<IssueRawEditFailure>());
      expect((result as IssueRawEditFailure).reason, IssueRawEditFailureReason.createdAtChanged);
    });

    test('status changed fails with statusChanged', () {
      const rawContent = '''
---
id: issue-001
title: Add OAuth login
feature: user-auth
status: done
created_at: 2026-06-10
tags: [auth]
---

Body''';

      final result = validateIssueRawEdit(original, rawContent);

      expect(result, isA<IssueRawEditFailure>());
      expect((result as IssueRawEditFailure).reason, IssueRawEditFailureReason.statusChanged);
    });
  });
}
