import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/kanban/domain/model/issue.dart';
import 'package:crm/features/projects/domain/helper/bug_report_to_issue.dart';
import 'package:crm/features/projects/domain/model/bug_report.dart';

void main() {
  group('mapBugReportToIssue', () {
    test('maps a bug report with a stack trace to an Issue', () {
      final report = BugReport(
        id: 'bug-123',
        severity: BugSeverity.error,
        message: 'Crash on save\nUser tapped save twice quickly.',
        stackTrace: 'at foo()\nat bar()',
        source: 'lib/main.dart:42',
        resolved: false,
        createdAt: DateTime(2026, 6, 10),
      );

      final issue = mapBugReportToIssue(report);

      expect(issue.id, 'bug-bug-123');
      expect(issue.title, 'Crash on save');
      expect(issue.feature, 'bug-report');
      expect(issue.status, IssueStatus.backlog);
      expect(issue.tags, ['bug', 'error']);
      expect(issue.filePath, '');
      expect(issue.body, contains('Crash on save'));
      expect(issue.body, contains('User tapped save twice quickly.'));
      expect(issue.body, contains('## Stack Trace'));
      expect(issue.body, contains('at foo()'));
      expect(issue.body, contains('at bar()'));
      expect(issue.body, contains('lib/main.dart:42'));
    });

    test('maps a bug report without a stack trace to an Issue', () {
      final report = BugReport(
        id: 'bug-456',
        severity: BugSeverity.warning,
        message: 'Slow query on dashboard load',
        stackTrace: null,
        source: null,
        resolved: false,
        createdAt: DateTime(2026, 6, 11),
      );

      final issue = mapBugReportToIssue(report);

      expect(issue.id, 'bug-bug-456');
      expect(issue.title, 'Slow query on dashboard load');
      expect(issue.feature, 'bug-report');
      expect(issue.status, IssueStatus.backlog);
      expect(issue.tags, ['bug', 'warning']);
      expect(issue.body, contains('Slow query on dashboard load'));
      expect(issue.body, isNot(contains('## Stack Trace')));
      expect(issue.body, isNot(contains('## Source')));
    });
  });
}
