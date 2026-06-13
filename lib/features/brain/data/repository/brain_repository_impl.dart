import 'dart:io';

import 'package:path/path.dart' as p;
import '../../domain/repository/brain_repository.dart';
import '../datasource/brain_seed_content.dart';

const String _sectionSeparator = '\n\n---\n\n';

const String _systemPromptFramingPrefix = 'You are Avyn. Embody this '
    'identity and personality fully. Respond in first person, in character, '
    'as Avyn — do not describe Avyn in the third person.\n\n---\n\n';

class BrainRepositoryImpl implements BrainRepository {
  final Directory brainDir;

  BrainRepositoryImpl(this.brainDir);

  @override
  Future<String?> buildSystemPrompt() async {
    if (!await brainDir.exists()) {
      await _seedBrainFolder();
    }

    final sections = <String>[];
    for (final fileName in const ['identity.md', 'soul.md', 'memory.md']) {
      final content = await _readTrimmedFile(fileName);
      if (content != null && content.isNotEmpty) sections.add(content);
    }

    final skillsNote = await _buildSkillsNote();
    if (skillsNote != null) sections.add(skillsNote);

    if (sections.isEmpty) return null;
    return _systemPromptFramingPrefix + sections.join(_sectionSeparator);
  }

  Future<void> _seedBrainFolder() async {
    await brainDir.create(recursive: true);
    await File(
      p.join(brainDir.path, 'identity.md'),
    ).writeAsString(kIdentitySeedContent);
    await File(
      p.join(brainDir.path, 'soul.md'),
    ).writeAsString(kSoulSeedContent);
    await File(p.join(brainDir.path, 'memory.md')).writeAsString('');
    await Directory(p.join(brainDir.path, 'skills')).create(recursive: true);
  }

  Future<String?> _readTrimmedFile(String fileName) async {
    final file = File(p.join(brainDir.path, fileName));
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    final trimmed = content.trim();
    return trimmed.isEmpty ? null : content;
  }

  Future<String?> _buildSkillsNote() async {
    final skillsDir = Directory(p.join(brainDir.path, 'skills'));
    if (!await skillsDir.exists()) return null;

    final fileNames = <String>[];
    await for (final entity in skillsDir.list()) {
      if (entity is File) fileNames.add(p.basename(entity.path));
    }
    if (fileNames.isEmpty) return null;

    return 'Skills available: ${fileNames.join(', ')}';
  }
}
