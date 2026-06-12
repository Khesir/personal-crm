import '../model/issue.dart';

abstract class IssuesRepository {
  Future<List<Issue>> getIssues(String localPath);

  /// Writes a brand-new issue file into `{localPath}/issues/backlog/` and
  /// returns the persisted [Issue] with its `status` set to
  /// [IssueStatus.backlog] and `filePath` pointing at the new file.
  Future<Issue> createIssue(String localPath, Issue issue);

  /// Persists the given field changes back to the issue's file. Fields left
  /// `null` are unchanged.
  Future<Issue> updateIssue(
    Issue issue, {
    String? title,
    String? body,
    String? feature,
    List<String>? tags,
  });

  /// Moves the issue's file to the folder for [newStatus] and updates its
  /// `status:` frontmatter field.
  Future<Issue> moveIssue(Issue issue, IssueStatus newStatus);
}
