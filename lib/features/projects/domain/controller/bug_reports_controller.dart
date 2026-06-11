import 'package:crm/core/state/state.dart';
import '../model/bug_report.dart';
import '../repository/bug_reports_repository.dart';

class BugReportsController extends StreamState<AsyncState<List<BugReport>>> {
  final BugReportsRepository _repository;

  BugReportsController(this._repository) : super(const AsyncLoading());

  List<BugReport>? get data => switch (state) {
        AsyncData(data: final list) => list,
        _ => null,
      };

  Future<void> load() => execute(_repository.fetchBugReports);

  Future<void> resolve(String id) async {
    await _repository.updateBugReport(id, resolved: true);
    await executeSilent(_repository.fetchBugReports);
  }

  Future<void> delete(String id) async {
    await _repository.deleteBugReport(id);
    await executeSilent(_repository.fetchBugReports);
  }

  List<BugReport> filteredBySeverity(BugSeverity? severity) {
    final reports = data ?? [];
    if (severity == null) return reports;
    return reports.where((b) => b.severity == severity).toList();
  }
}
