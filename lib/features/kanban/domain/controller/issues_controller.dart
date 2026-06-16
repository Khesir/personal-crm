import 'package:crm/core/state/state.dart';
import '../helper/checklist_toggle.dart';
import '../model/issue.dart';
import '../repository/issues_repository.dart';

class IssuesController extends StreamState<AsyncState<List<Issue>>> {
  final IssuesRepository repository;

  String? _localPath;

  IssuesController(this.repository) : super(const AsyncLoading());

  String? get localPath => _localPath;

  Future<void> load(String localPath) {
    _localPath = localPath;
    return execute(() => repository.getIssues(localPath));
  }

  Future<void> refresh(String localPath) =>
      execute(() => repository.getIssues(localPath));

  Future<void> loadArchive(String localPath, String archiveName) =>
      execute(() => repository.getArchivedIssues(localPath, archiveName));

  Future<void> updateIssue(
    Issue issue, {
    String? title,
    String? body,
    String? feature,
    List<String>? tags,
  }) async {
    final updated = await repository.updateIssue(
      issue,
      title: title,
      body: body,
      feature: feature,
      tags: tags,
    );
    _replaceIssue(updated);
  }

  Future<void> moveIssue(Issue issue, IssueStatus newStatus) async {
    final moved = await repository.moveIssue(issue, newStatus);
    _replaceIssue(moved);
  }

  Future<void> deleteIssue(Issue issue) async {
    await repository.deleteIssue(issue);
    final current = data;
    if (current == null) return;
    emit(AsyncData(current.where((i) => i.id != issue.id).toList()));
  }

  Future<void> createIssue(String localPath, Issue issue) async {
    final created = await repository.createIssue(localPath, issue);
    final current = data;
    if (current == null) return;
    emit(AsyncData([...current, created]));
  }

  Future<void> toggleAcceptanceCriteria(Issue issue, int index) {
    final updatedBody = toggleChecklistItem(issue.body, index);
    return updateIssue(issue, body: updatedBody);
  }

  void _replaceIssue(Issue updated) {
    final current = data;
    if (current == null) return;
    emit(AsyncData([
      for (final existing in current)
        if (existing.id == updated.id) updated else existing,
    ]));
  }
}
