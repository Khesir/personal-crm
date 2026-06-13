import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:crm/features/brain/data/repository/brain_repository_impl.dart';
import 'package:crm/features/brain/data/datasource/brain_seed_content.dart';

const String _innerContent =
    'Identity content\n\n---\n\nSoul content\n\n---\n\nMemory content';

void main() {
  group('BrainRepositoryImpl', () {
    late Directory tempDir;
    late Directory brainDir;
    late BrainRepositoryImpl repository;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('brain_repo_test_');
      brainDir = Directory(p.join(tempDir.path, 'brain'));
      repository = BrainRepositoryImpl(brainDir);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    void writeFile(String name, String contents) {
      File(p.join(brainDir.path, name)).writeAsStringSync(contents);
    }

    void writeSkillFile(String name, String contents) {
      final skillsDir = Directory(p.join(brainDir.path, 'skills'));
      skillsDir.createSync(recursive: true);
      File(p.join(skillsDir.path, name)).writeAsStringSync(contents);
    }

    test('all three files present and non-empty are joined in order',
        () async {
      brainDir.createSync(recursive: true);
      writeFile('identity.md', 'Identity content');
      writeFile('soul.md', 'Soul content');
      writeFile('memory.md', 'Memory content');

      final prompt = await repository.buildSystemPrompt();

      expect(prompt, contains(_innerContent));
    });

    test('missing files are omitted from the prompt', () async {
      brainDir.createSync(recursive: true);
      writeFile('identity.md', 'Identity content');
      writeFile('soul.md', 'Soul content');
      // memory.md is missing entirely

      final prompt = await repository.buildSystemPrompt();

      expect(prompt, contains('Identity content\n\n---\n\nSoul content'));
    });

    test('empty files are omitted from the prompt', () async {
      brainDir.createSync(recursive: true);
      writeFile('identity.md', 'Identity content');
      writeFile('soul.md', '   \n  ');
      writeFile('memory.md', 'Memory content');

      final prompt = await repository.buildSystemPrompt();

      expect(prompt, contains('Identity content\n\n---\n\nMemory content'));
    });

    test('skills folder with files adds a note after memory section',
        () async {
      brainDir.createSync(recursive: true);
      writeFile('identity.md', 'Identity content');
      writeFile('soul.md', 'Soul content');
      writeFile('memory.md', 'Memory content');
      writeSkillFile('cooking.md', 'Cooking skill');

      final prompt = await repository.buildSystemPrompt();

      expect(prompt, isNotNull);
      expect(
        prompt,
        contains(
          'Identity content\n\n---\n\nSoul content\n\n---\n\nMemory content\n\n---\n\n',
        ),
      );
      expect(prompt, contains('cooking.md'));
    });

    test('empty skills folder does not add a note', () async {
      brainDir.createSync(recursive: true);
      writeFile('identity.md', 'Identity content');
      Directory(p.join(brainDir.path, 'skills')).createSync(recursive: true);

      final prompt = await repository.buildSystemPrompt();

      expect(prompt, contains('Identity content'));
      expect(prompt, isNot(contains('skills')));
    });

    test('absent skills folder does not add a note', () async {
      brainDir.createSync(recursive: true);
      writeFile('identity.md', 'Identity content');

      final prompt = await repository.buildSystemPrompt();

      expect(prompt, contains('Identity content'));
      expect(prompt, isNot(contains('skills')));
    });

    test(
        'returns null when everything is empty/missing and skills is empty/absent',
        () async {
      brainDir.createSync(recursive: true);
      writeFile('identity.md', '');
      writeFile('soul.md', '   ');
      // memory.md missing, skills absent

      final prompt = await repository.buildSystemPrompt();

      expect(prompt, isNull);
    });

    test(
        'seeds the brain folder on first run with verbatim identity/soul content',
        () async {
      expect(brainDir.existsSync(), isFalse);

      final prompt = await repository.buildSystemPrompt();

      expect(brainDir.existsSync(), isTrue);

      final identityFile = File(p.join(brainDir.path, 'identity.md'));
      final soulFile = File(p.join(brainDir.path, 'soul.md'));
      final memoryFile = File(p.join(brainDir.path, 'memory.md'));
      final skillsDir = Directory(p.join(brainDir.path, 'skills'));

      expect(identityFile.existsSync(), isTrue);
      expect(soulFile.existsSync(), isTrue);
      expect(memoryFile.existsSync(), isTrue);
      expect(skillsDir.existsSync(), isTrue);

      expect(identityFile.readAsStringSync(), kIdentitySeedContent);
      expect(soulFile.readAsStringSync(), kSoulSeedContent);
      expect(memoryFile.readAsStringSync().trim(), isEmpty);
      expect(skillsDir.listSync(), isEmpty);

      expect(
        prompt,
        contains('$kIdentitySeedContent\n\n---\n\n$kSoulSeedContent'),
      );
    });

    test('does not re-seed when brain folder already exists', () async {
      brainDir.createSync(recursive: true);
      writeFile('identity.md', 'Custom identity');
      // soul.md and memory.md intentionally left missing

      final prompt = await repository.buildSystemPrompt();

      expect(prompt, contains('Custom identity'));
      expect(File(p.join(brainDir.path, 'soul.md')).existsSync(), isFalse);
      expect(File(p.join(brainDir.path, 'memory.md')).existsSync(), isFalse);
    });

    test('wraps assembled content with a framing instruction to embody Avyn',
        () async {
      brainDir.createSync(recursive: true);
      writeFile('identity.md', 'Identity content');
      writeFile('soul.md', 'Soul content');
      writeFile('memory.md', 'Memory content');

      final prompt = await repository.buildSystemPrompt();

      expect(prompt, isNotNull);
      expect(prompt, contains('You are Avyn'));
      expect(prompt, contains('first person'));
      expect(prompt, contains(_innerContent));

      // The framing must surround the inner content, not just be appended.
      final innerStart = prompt!.indexOf(_innerContent);
      expect(innerStart, greaterThan(0));
    });

    test('framing instruction explicitly forbids describing Avyn in third person',
        () async {
      brainDir.createSync(recursive: true);
      writeFile('identity.md', 'Identity content');

      final prompt = await repository.buildSystemPrompt();

      expect(prompt, isNotNull);
      expect(
        prompt!.toLowerCase(),
        contains('do not describe avyn in the third person'),
      );
    });
  });
}
