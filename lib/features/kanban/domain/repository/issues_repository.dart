import '../model/issue.dart';

abstract class IssuesRepository {
  Future<List<Issue>> getIssues(String localPath);

  /// Parses and groups issues from
  /// `{localPath}/issues/archive/{archiveName}/{backlog,ready,in-progress,qa,done}/`
  /// using the existing frontmatter parser. Returns an empty list if the
  /// archive directory doesn't exist.
  Future<List<Issue>> getArchivedIssues(String localPath, String archiveName);

  /// Returns the subdirectory names directly under
  /// `{localPath}/issues/archive/`, sorted descending (newest-first, since
  /// folder names start with `YYYY-MM-DD-`). Returns an empty list if
  /// `issues/archive/` doesn't exist.
  Future<List<String>> listArchives(String localPath);

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

  /// Overwrites the file at [issue.filePath] with [rawContent] exactly as
  /// given, then re-reads and re-parses it from disk to return the
  /// canonical [Issue]. The issue's status/folder location is unchanged.
  Future<Issue> updateIssueRaw(Issue issue, String rawContent);

  /// Permanently deletes the issue's file from disk.
  Future<void> deleteIssue(Issue issue);

  /// Scaffolds `{localPath}/issues/{backlog,ready,in-progress,qa,done}/`,
  /// creating each status folder that doesn't already exist.
  ///
  /// Idempotent: safe to call against an already-scaffolded `issues/`
  /// folder without clobbering any files already inside those folders.
  Future<void> initializeIssuesFolder(String localPath);

  /// Whether `{localPath}/issues/` exists at all. Distinct from
  /// [getIssues] returning an empty list, which also happens when the
  /// folder exists but every status subfolder is empty.
  Future<bool> issuesFolderExists(String localPath);
}
