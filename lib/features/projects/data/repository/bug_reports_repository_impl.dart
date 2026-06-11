import '../../domain/model/bug_report.dart';
import '../../domain/repository/bug_reports_repository.dart';
import '../datasource/bug_reports_datasource.dart';

class BugReportsRepositoryImpl implements BugReportsRepository {
  final BugReportsDatasource _datasource;

  BugReportsRepositoryImpl(this._datasource);

  @override
  Future<List<BugReport>> fetchBugReports() => _datasource.fetchBugReports();

  @override
  Future<void> updateBugReport(String id, {required bool resolved}) =>
      _datasource.updateBugReport(id, resolved: resolved);

  @override
  Future<void> deleteBugReport(String id) => _datasource.deleteBugReport(id);
}
