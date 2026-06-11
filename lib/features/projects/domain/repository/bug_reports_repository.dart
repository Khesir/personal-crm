import '../model/bug_report.dart';

abstract class BugReportsRepository {
  Future<List<BugReport>> fetchBugReports();

  Future<void> updateBugReport(String id, {required bool resolved});

  Future<void> deleteBugReport(String id);
}
