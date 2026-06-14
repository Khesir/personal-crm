import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/model/tool_call.dart';
import '../../domain/model/tool_execution_result.dart';
import '../../domain/repository/agent_tool_repository.dart';

/// Whether reads to a resolved path are permitted under the working
/// project, a trusted reference project, a registered-but-untrusted
/// reference project, or none of the above.
enum _ReadAccess { allowed, needsConfirmation, denied }

class AgentToolRepositoryImpl implements AgentToolRepository {
  @override
  Future<ToolExecutionResult> execute(
    ToolCall call, {
    required String workingProjectPath,
    required List<String> trustedReferenceProjectPaths,
    required Map<String, String> registeredProjectPaths,
  }) async {
    switch (call.name) {
      case 'read_file':
        return _readFile(call, workingProjectPath, trustedReferenceProjectPaths, registeredProjectPaths);
      case 'list_dir':
        return _listDir(call, workingProjectPath, trustedReferenceProjectPaths, registeredProjectPaths);
      case 'grep':
        return _grep(call, workingProjectPath, trustedReferenceProjectPaths, registeredProjectPaths);
      case 'write_file':
        return _writeFile(call, workingProjectPath);
      case 'edit_file':
        return _editFile(call, workingProjectPath);
      default:
        return ToolError('Unknown tool: ${call.name}');
    }
  }

  Future<ToolExecutionResult> _readFile(
    ToolCall call,
    String workingProjectPath,
    List<String> trustedReferenceProjectPaths,
    Map<String, String> registeredProjectPaths,
  ) async {
    final path = call.arguments['path'] as String?;
    if (path == null) return const ToolError('Missing required argument: path');

    final resolved = _resolvePath(path, workingProjectPath);
    final access = _checkReadAccess(resolved, workingProjectPath, trustedReferenceProjectPaths, registeredProjectPaths);
    if (access case _ReadAccessResult(needsConfirmation: true, projectId: final projectId?)) {
      return ToolReferenceConfirmationNeeded(projectId, resolved);
    }
    if (access.access == _ReadAccess.denied) {
      return ToolError('Access denied: $resolved is outside all known project roots');
    }

    final file = File(resolved);
    if (!await file.exists()) {
      return ToolError('File not found: $resolved');
    }
    final contents = await file.readAsString();
    return ToolOutput(contents);
  }

  Future<ToolExecutionResult> _listDir(
    ToolCall call,
    String workingProjectPath,
    List<String> trustedReferenceProjectPaths,
    Map<String, String> registeredProjectPaths,
  ) async {
    final path = call.arguments['path'] as String?;
    if (path == null) return const ToolError('Missing required argument: path');

    final resolved = _resolvePath(path, workingProjectPath);
    final access = _checkReadAccess(resolved, workingProjectPath, trustedReferenceProjectPaths, registeredProjectPaths);
    if (access case _ReadAccessResult(needsConfirmation: true, projectId: final projectId?)) {
      return ToolReferenceConfirmationNeeded(projectId, resolved);
    }
    if (access.access == _ReadAccess.denied) {
      return ToolError('Access denied: $resolved is outside all known project roots');
    }

    final dir = Directory(resolved);
    if (!await dir.exists()) {
      return ToolError('Directory not found: $resolved');
    }

    final entries = await dir.list().toList();
    entries.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    final lines = entries.map((entry) {
      final name = p.basename(entry.path);
      return entry is Directory ? '$name/' : name;
    });
    return ToolOutput(lines.join('\n'));
  }

  Future<ToolExecutionResult> _grep(
    ToolCall call,
    String workingProjectPath,
    List<String> trustedReferenceProjectPaths,
    Map<String, String> registeredProjectPaths,
  ) async {
    final pattern = call.arguments['pattern'] as String?;
    if (pattern == null) return const ToolError('Missing required argument: pattern');

    final path = call.arguments['path'] as String? ?? workingProjectPath;
    final resolved = _resolvePath(path, workingProjectPath);
    final access = _checkReadAccess(resolved, workingProjectPath, trustedReferenceProjectPaths, registeredProjectPaths);
    if (access case _ReadAccessResult(needsConfirmation: true, projectId: final projectId?)) {
      return ToolReferenceConfirmationNeeded(projectId, resolved);
    }
    if (access.access == _ReadAccess.denied) {
      return ToolError('Access denied: $resolved is outside all known project roots');
    }

    final dir = Directory(resolved);
    if (!await dir.exists()) {
      return ToolError('Directory not found: $resolved');
    }

    final regex = RegExp(RegExp.escape(pattern));
    final matches = <String>[];
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File) continue;
      String contents;
      try {
        contents = await entity.readAsString();
      } catch (_) {
        continue; // skip unreadable/binary files
      }
      final lines = contents.split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (regex.hasMatch(lines[i])) {
          matches.add('${entity.path}:${i + 1}: ${lines[i]}');
        }
      }
    }

    if (matches.isEmpty) {
      return const ToolOutput('No matches found.');
    }
    return ToolOutput(matches.join('\n'));
  }

  Future<ToolExecutionResult> _writeFile(ToolCall call, String workingProjectPath) async {
    final path = call.arguments['path'] as String?;
    final content = call.arguments['content'] as String?;
    if (path == null) return const ToolError('Missing required argument: path');
    if (content == null) return const ToolError('Missing required argument: content');

    final resolved = _resolvePath(path, workingProjectPath);
    if (!_isUnder(resolved, workingProjectPath)) {
      return ToolError('Access denied: $resolved is outside the working project');
    }

    final file = File(resolved);
    if (await file.exists()) {
      return ToolError('File already exists: $resolved');
    }

    return ToolWriteProposal(resolved, WriteFileCreation(content));
  }

  Future<ToolExecutionResult> _editFile(ToolCall call, String workingProjectPath) async {
    final path = call.arguments['path'] as String?;
    final oldText = call.arguments['old_text'] as String?;
    final newText = call.arguments['new_text'] as String?;
    if (path == null) return const ToolError('Missing required argument: path');
    if (oldText == null) return const ToolError('Missing required argument: old_text');
    if (newText == null) return const ToolError('Missing required argument: new_text');

    final resolved = _resolvePath(path, workingProjectPath);
    if (!_isUnder(resolved, workingProjectPath)) {
      return ToolError('Access denied: $resolved is outside the working project');
    }

    final file = File(resolved);
    if (!await file.exists()) {
      return ToolError('File not found: $resolved');
    }

    final contents = await file.readAsString();
    final occurrences = _countOccurrences(contents, oldText);
    if (occurrences == 0) {
      return ToolError('old_text not found in $resolved');
    }
    if (occurrences > 1) {
      return ToolError('old_text matches $occurrences times in $resolved; must match exactly once');
    }

    return ToolWriteProposal(resolved, EditFileChange(oldText, newText));
  }

  @override
  Future<ToolExecutionResult> applyWrite(ToolWriteProposal proposal) async {
    final file = File(proposal.path);
    switch (proposal.preview) {
      case WriteFileCreation(content: final content):
        await file.create(recursive: true);
        await file.writeAsString(content);
        return ToolOutput('Wrote ${content.length} bytes to ${proposal.path}');
      case EditFileChange(oldText: final oldText, newText: final newText):
        if (!await file.exists()) {
          return ToolError('File not found: ${proposal.path}');
        }
        final contents = await file.readAsString();
        final occurrences = _countOccurrences(contents, oldText);
        if (occurrences == 0) {
          return ToolError('old_text not found in ${proposal.path}');
        }
        if (occurrences > 1) {
          return ToolError('old_text matches $occurrences times in ${proposal.path}; must match exactly once');
        }
        await file.writeAsString(contents.replaceFirst(oldText, newText));
        return ToolOutput('Replaced text in ${proposal.path}');
      case CommandExecution():
        throw UnsupportedError('CommandExecution is applied via CommandExecutionRepository, not AgentToolRepository.applyWrite');
    }
  }

  int _countOccurrences(String haystack, String needle) {
    if (needle.isEmpty) return 0;
    var count = 0;
    var index = 0;
    while (true) {
      final found = haystack.indexOf(needle, index);
      if (found == -1) break;
      count++;
      index = found + needle.length;
    }
    return count;
  }

  /// Resolves [path] against [workingProjectPath] if relative, otherwise
  /// returns it normalized as-is.
  String _resolvePath(String path, String workingProjectPath) {
    if (p.isAbsolute(path)) return p.normalize(path);
    return p.normalize(p.join(workingProjectPath, path));
  }

  /// Whether [resolved] is [root] itself or nested under it.
  bool _isUnder(String resolved, String root) {
    final normalizedRoot = p.normalize(root);
    final normalizedResolved = p.normalize(resolved);
    if (normalizedResolved == normalizedRoot) return true;
    return p.isWithin(normalizedRoot, normalizedResolved);
  }

  _ReadAccessResult _checkReadAccess(
    String resolved,
    String workingProjectPath,
    List<String> trustedReferenceProjectPaths,
    Map<String, String> registeredProjectPaths,
  ) {
    if (_isUnder(resolved, workingProjectPath)) {
      return const _ReadAccessResult(_ReadAccess.allowed);
    }
    for (final trusted in trustedReferenceProjectPaths) {
      if (_isUnder(resolved, trusted)) {
        return const _ReadAccessResult(_ReadAccess.allowed);
      }
    }
    for (final entry in registeredProjectPaths.entries) {
      if (_isUnder(resolved, entry.key)) {
        return _ReadAccessResult(_ReadAccess.needsConfirmation, projectId: entry.value);
      }
    }
    return const _ReadAccessResult(_ReadAccess.denied);
  }
}

class _ReadAccessResult {
  final _ReadAccess access;
  final String? projectId;

  const _ReadAccessResult(this.access, {this.projectId});

  bool get needsConfirmation => access == _ReadAccess.needsConfirmation;
}
