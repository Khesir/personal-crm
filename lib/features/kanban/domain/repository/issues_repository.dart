import '../model/issue.dart';

abstract class IssuesRepository {
  Future<List<Issue>> getIssues(String localPath);

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
