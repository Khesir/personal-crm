import 'package:yaml/yaml.dart';

import '../../data/datasource/issue_frontmatter_parser.dart';
import '../model/issue.dart';

/// Reason a raw-edit commit was rejected by [validateIssueRawEdit].
enum IssueRawEditFailureReason { parseError, idChanged, createdAtChanged, statusChanged }

/// Result of validating raw markdown text against the issue it is meant to
/// replace — see `IssueDetailSection._commitEdit`.
sealed class IssueRawEditResult {
  const IssueRawEditResult();

  const factory IssueRawEditResult.success(Issue issue) = IssueRawEditSuccess;

  const factory IssueRawEditResult.failure(IssueRawEditFailureReason reason) = IssueRawEditFailure;
}

class IssueRawEditSuccess extends IssueRawEditResult {
  final Issue issue;
  const IssueRawEditSuccess(this.issue);
}

class IssueRawEditFailure extends IssueRawEditResult {
  final IssueRawEditFailureReason reason;
  const IssueRawEditFailure(this.reason);
}

const _frontmatterDelimiter = '---';

/// Validates [rawContent] as a replacement for [original]'s file contents.
///
/// Parses [rawContent] with [original.status] (status is derived from the
/// file's folder, not read from YAML, so the parsed [Issue.status] can never
/// itself differ from [original.status] — the raw `status:` text is checked
/// separately below). Fails with [IssueRawEditFailureReason.parseError] if
/// parsing fails, or with the matching locked-field reason if `id`,
/// `createdAt`, or `status` differs from [original]. Otherwise succeeds with
/// the parsed [Issue].
IssueRawEditResult validateIssueRawEdit(Issue original, String rawContent) {
  const parser = IssueFrontmatterParser();
  final candidate = parser.parse(rawContent, original.status, original.filePath);
  if (candidate == null) {
    return const IssueRawEditResult.failure(IssueRawEditFailureReason.parseError);
  }

  if (candidate.id != original.id) {
    return const IssueRawEditResult.failure(IssueRawEditFailureReason.idChanged);
  }
  if (candidate.createdAt != original.createdAt) {
    return const IssueRawEditResult.failure(IssueRawEditFailureReason.createdAtChanged);
  }
  if (_rawStatusChanged(rawContent, original.status)) {
    return const IssueRawEditResult.failure(IssueRawEditFailureReason.statusChanged);
  }

  return IssueRawEditResult.success(candidate);
}

bool _rawStatusChanged(String rawContent, IssueStatus originalStatus) {
  final rawStatus = _readRawStatus(rawContent);
  if (rawStatus == null) return false;
  return rawStatus != originalStatus.name;
}

String? _readRawStatus(String rawContent) {
  final lines = rawContent.split('\n');
  if (lines.isEmpty || lines.first.trim() != _frontmatterDelimiter) return null;

  var endIndex = -1;
  for (var i = 1; i < lines.length; i++) {
    if (lines[i].trim() == _frontmatterDelimiter) {
      endIndex = i;
      break;
    }
  }
  if (endIndex == -1) return null;

  final yamlText = lines.sublist(1, endIndex).join('\n');
  final yamlMap = loadYaml(yamlText);
  if (yamlMap is! YamlMap) return null;

  return yamlMap['status']?.toString();
}
