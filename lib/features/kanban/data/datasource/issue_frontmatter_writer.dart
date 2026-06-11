import '../../domain/model/issue.dart';

const _frontmatterDelimiter = '---';

/// Rewrites the raw markdown [contents] of an issue file, applying the given
/// field changes to its YAML frontmatter and/or replacing its body.
///
/// Fields left `null` are unchanged. Frontmatter keys not covered by this
/// writer (e.g. `id`, `created_at`) are preserved as-is.
class IssueFrontmatterWriter {
  const IssueFrontmatterWriter();

  String write(
    String contents, {
    String? title,
    String? body,
    String? feature,
    List<String>? tags,
    IssueStatus? status,
  }) {
    final lines = contents.split('\n');
    if (lines.isEmpty || lines.first.trim() != _frontmatterDelimiter) {
      return contents;
    }

    final endIndex = _findFrontmatterEnd(lines);
    if (endIndex == -1) return contents;

    final frontmatterLines = lines.sublist(1, endIndex);
    final originalBody = lines.sublist(endIndex + 1).join('\n');

    final updatedFrontmatter = _updateFrontmatter(
      frontmatterLines,
      title: title,
      feature: feature,
      tags: tags,
      status: status,
    );

    final newBody = body ?? originalBody.trim();

    return [
      _frontmatterDelimiter,
      ...updatedFrontmatter,
      _frontmatterDelimiter,
      '',
      newBody,
    ].join('\n');
  }

  List<String> _updateFrontmatter(
    List<String> lines, {
    String? title,
    String? feature,
    List<String>? tags,
    IssueStatus? status,
  }) {
    final updates = <String, String>{
      if (title != null) 'title': _scalar(title),
      if (feature != null) 'feature': _scalar(feature),
      if (tags != null) 'tags': _flowList(tags),
      if (status != null) 'status': status.name,
    };
    if (updates.isEmpty) return lines;

    final result = <String>[];
    final remaining = Map<String, String>.from(updates);

    for (final line in lines) {
      final key = _keyOf(line);
      if (key != null && remaining.containsKey(key)) {
        result.add('$key: ${remaining.remove(key)}');
      } else {
        result.add(line);
      }
    }

    for (final entry in remaining.entries) {
      result.add('${entry.key}: ${entry.value}');
    }

    return result;
  }

  String? _keyOf(String line) {
    final match = RegExp(r'^([A-Za-z0-9_]+):').firstMatch(line);
    return match?.group(1);
  }

  static const _yamlSpecialChars = [':', '#', '[', ']', '{', '}', ',', '&', '*', '!', '|', '>', "'", '"', '%', '@', '`'];

  String _scalar(String value) {
    final needsQuoting = value.isEmpty ||
        value.trim() != value ||
        _yamlSpecialChars.any(value.contains);
    if (!needsQuoting) return value;
    return '"${value.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"';
  }

  String _flowList(List<String> values) =>
      '[${values.map(_scalar).join(', ')}]';

  int _findFrontmatterEnd(List<String> lines) {
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim() == _frontmatterDelimiter) return i;
    }
    return -1;
  }
}
