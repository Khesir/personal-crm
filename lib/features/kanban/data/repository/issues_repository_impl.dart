import 'dart:io';

import 'package:path/path.dart' as p;
import '../../domain/model/issue.dart';
import '../../domain/repository/issues_repository.dart';
import '../datasource/issue_frontmatter_parser.dart';
import '../datasource/issue_frontmatter_writer.dart';

const _statusFolders = {
  IssueStatus.backlog: 'backlog',
  IssueStatus.ready: 'ready',
  IssueStatus.inprogress: 'in-progress',
  IssueStatus.qa: 'qa',
  IssueStatus.done: 'done',
};

class IssuesRepositoryImpl implements IssuesRepository {
  final IssueFrontmatterParser parser;
  final IssueFrontmatterWriter writer;

  IssuesRepositoryImpl({
    this.parser = const IssueFrontmatterParser(),
    this.writer = const IssueFrontmatterWriter(),
  });

  @override
  Future<List<Issue>> getIssues(String localPath) async {
    final issuesDir = Directory(p.join(localPath, 'issues'));
    if (!await issuesDir.exists()) return [];

    final issues = <Issue>[];
    for (final entry in _statusFolders.entries) {
      final statusDir = Directory(p.join(issuesDir.path, entry.value));
      if (!await statusDir.exists()) continue;

      await for (final fileEntity in statusDir.list()) {
        if (fileEntity is! File || !fileEntity.path.endsWith('.md')) continue;

        final contents = await fileEntity.readAsString();
        final issue = parser.parse(contents, entry.key, fileEntity.path);
        if (issue != null) issues.add(issue);
      }
    }
    return issues;
  }

  @override
  Future<List<Issue>> getArchivedIssues(
    String localPath,
    String archiveName,
  ) async {
    final archiveDir = Directory(
      p.join(localPath, 'issues', 'archive', archiveName),
    );
    if (!await archiveDir.exists()) return [];

    final issues = <Issue>[];
    for (final entry in _statusFolders.entries) {
      final statusDir = Directory(p.join(archiveDir.path, entry.value));
      if (!await statusDir.exists()) continue;

      await for (final fileEntity in statusDir.list()) {
        if (fileEntity is! File || !fileEntity.path.endsWith('.md')) continue;

        final contents = await fileEntity.readAsString();
        final issue = parser.parse(contents, entry.key, fileEntity.path);
        if (issue != null) issues.add(issue);
      }
    }
    return issues;
  }

  @override
  Future<List<String>> listArchives(String localPath) async {
    final archiveDir = Directory(p.join(localPath, 'issues', 'archive'));
    if (!await archiveDir.exists()) return [];

    final names = <String>[];
    await for (final entity in archiveDir.list()) {
      if (entity is Directory) names.add(p.basename(entity.path));
    }
    names.sort((a, b) => b.compareTo(a));
    return names;
  }

  @override
  Future<Issue> createIssue(String localPath, Issue issue) async {
    final targetDir = Directory(
      p.join(localPath, 'issues', _statusFolders[issue.status]!),
    );
    if (!await targetDir.exists()) await targetDir.create(recursive: true);

    final filePath = p.join(targetDir.path, '${issue.id}.md');
    final contents = writer.createFileContents(issue);
    await File(filePath).writeAsString(contents);

    return Issue(
      id: issue.id,
      title: issue.title,
      feature: issue.feature,
      status: issue.status,
      createdAt: issue.createdAt,
      tags: issue.tags,
      body: issue.body,
      filePath: filePath,
    );
  }

  @override
  Future<Issue> updateIssue(
    Issue issue, {
    String? title,
    String? body,
    String? feature,
    List<String>? tags,
  }) async {
    final file = File(issue.filePath);
    final contents = await file.readAsString();
    final updatedContents = writer.write(
      contents,
      title: title,
      body: body,
      feature: feature,
      tags: tags,
    );
    await file.writeAsString(updatedContents);

    return Issue(
      id: issue.id,
      title: title ?? issue.title,
      feature: feature ?? issue.feature,
      status: issue.status,
      createdAt: issue.createdAt,
      tags: tags ?? issue.tags,
      body: body ?? issue.body,
      filePath: issue.filePath,
    );
  }

  @override
  Future<void> deleteIssue(Issue issue) async {
    await File(issue.filePath).delete();
  }

  @override
  Future<Issue> moveIssue(Issue issue, IssueStatus newStatus) async {
    final file = File(issue.filePath);
    final contents = await file.readAsString();
    final updatedContents = writer.write(contents, status: newStatus);

    final issuesDir = p.dirname(p.dirname(issue.filePath));
    final newDir = Directory(p.join(issuesDir, _statusFolders[newStatus]));
    if (!await newDir.exists()) await newDir.create(recursive: true);

    final newPath = p.join(newDir.path, p.basename(issue.filePath));
    await File(newPath).writeAsString(updatedContents);
    if (newPath != issue.filePath) await file.delete();

    return Issue(
      id: issue.id,
      title: issue.title,
      feature: issue.feature,
      status: newStatus,
      createdAt: issue.createdAt,
      tags: issue.tags,
      body: issue.body,
      filePath: newPath,
    );
  }
}
