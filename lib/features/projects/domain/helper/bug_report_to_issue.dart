import 'package:crm/features/kanban/api.dart';
import '../model/bug_report.dart';

/// Maps a [BugReport] to an [Issue] ready to be written into
/// `issues/backlog/` via `IssuesRepository.createIssue`.
Issue mapBugReportToIssue(BugReport report) {
  return Issue(
    id: 'bug-${report.id}',
    title: _firstLine(report.message),
    feature: 'bug-report',
    status: IssueStatus.backlog,
    createdAt: DateTime.now(),
    tags: ['bug', report.severity.value],
    body: _buildBody(report),
    filePath: '',
  );
}

String _firstLine(String message) {
  final newlineIndex = message.indexOf('\n');
  final firstLine = newlineIndex == -1 ? message : message.substring(0, newlineIndex);
  return firstLine.trim();
}

String _buildBody(BugReport report) {
  final buffer = StringBuffer();
  buffer.writeln('## Message');
  buffer.writeln();
  buffer.writeln(report.message);

  if (report.source != null) {
    buffer.writeln();
    buffer.writeln('## Source');
    buffer.writeln();
    buffer.writeln(report.source);
  }

  if (report.stackTrace != null) {
    buffer.writeln();
    buffer.writeln('## Stack Trace');
    buffer.writeln();
    buffer.writeln('```');
    buffer.writeln(report.stackTrace);
    buffer.writeln('```');
  }

  return buffer.toString().trim();
}
