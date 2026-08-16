import 'package:crm/core/state/state.dart';
import '../helper/checklist_toggle.dart';
import '../model/issue.dart';
import '../repository/issues_repository.dart';

class IssuesController extends StreamState<AsyncState<List<Issue>>> {
  final IssuesRepository repository;

  String? _localPath;
  bool _folderExists = true;

  IssuesController(this.repository) : super(const AsyncLoading());

  String? get localPath => _localPath;

  /// Whether `{localPath}/issues/` was confirmed to exist as of the most
  /// recent [load]/[refresh]/[initializeIssuesFolder] call. Defaults to
  /// `true` so consumers don't flash an "initialize" empty state before
  /// the first load resolves.
  bool get folderExists => _folderExists;

  Future<void> load(String localPath) async {
    _localPath = localPath;
    _folderExists = await repository.issuesFolderExists(localPath);
    await execute(() => repository.getIssues(localPath));
  }

  Future<void> refresh(String localPath) async {
    _folderExists = await repository.issuesFolderExists(localPath);
    await execute(() => repository.getIssues(localPath));
  }

  /// Scaffolds `{localPath}/issues/` via [IssuesRepository.initializeIssuesFolder],
  /// then reloads so the (now empty but scaffolded) columns appear and
  /// [folderExists] flips to `true`. No-op if [load] hasn't been called yet.
  Future<void> initializeIssuesFolder() async {
    final path = _localPath;
    if (path == null) return;
    await repository.initializeIssuesFolder(path);
    await load(path);
  }

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

  Future<void> updateIssueRaw(Issue issue, String rawContent) async {
    final updated = await repository.updateIssueRaw(issue, rawContent);
    _replaceIssue(updated);
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
