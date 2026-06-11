enum IssueStatus { backlog, ready, inprogress, qa, done }

class Issue {
  final String id;
  final String title;
  final String feature;
  final IssueStatus status;
  final DateTime? createdAt;
  final List<String> tags;
  final String body;
  final String filePath;

  const Issue({
    required this.id,
    required this.title,
    required this.feature,
    required this.status,
    required this.createdAt,
    required this.tags,
    required this.body,
    required this.filePath,
  });
}
