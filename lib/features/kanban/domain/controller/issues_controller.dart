import 'package:crm/core/state/state.dart';
import '../helper/checklist_toggle.dart';
import '../model/issue.dart';
import '../repository/issues_repository.dart';

class IssuesController extends StreamState<AsyncState<List<Issue>>> {
  final IssuesRepository repository;

  IssuesController(this.repository) : super(const AsyncLoading());

  Future<void> load(String localPath) =>
      execute(() => repository.getIssues(localPath));

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
