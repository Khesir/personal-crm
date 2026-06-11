import 'package:yaml/yaml.dart';
import '../../domain/model/issue.dart';

const _frontmatterDelimiter = '---';

class IssueFrontmatterParser {
  const IssueFrontmatterParser();

  Issue? parse(String contents, IssueStatus status, String filePath) {
    final lines = contents.split('\n');
    if (lines.isEmpty || lines.first.trim() != _frontmatterDelimiter) {
      return null;
    }

    final endIndex = _findFrontmatterEnd(lines);
    if (endIndex == -1) return null;

    final yamlText = lines.sublist(1, endIndex).join('\n');
    final body = lines.sublist(endIndex + 1).join('\n').trim();

    final yamlMap = loadYaml(yamlText);
    if (yamlMap is! YamlMap) return null;

    final id = yamlMap['id']?.toString();
    final title = yamlMap['title']?.toString();
    if (id == null || title == null) return null;

    return Issue(
      id: id,
      title: title,
      feature: yamlMap['feature']?.toString() ?? '',
      status: status,
      createdAt: _parseDate(yamlMap['created_at']),
      tags: _parseTags(yamlMap['tags']),
      body: body,
      filePath: filePath,
    );
  }

  int _findFrontmatterEnd(List<String> lines) {
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim() == _frontmatterDelimiter) return i;
    }
    return -1;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  List<String> _parseTags(dynamic value) {
    if (value is YamlList) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }
}
