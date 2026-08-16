import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:crm/features/settings/data/datasource/project_metadata_datasource.dart';
import 'package:crm/features/settings/data/repository/project_metadata_repository_impl.dart';

void main() {
  group('ProjectMetadataRepositoryImpl', () {
    late Directory tempDir;
    late Directory sourceImageDir;
    late ProjectMetadataRepositoryImpl repository;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('project_metadata_repo_test_');
      sourceImageDir = Directory.systemTemp.createTempSync('project_metadata_repo_src_');
      repository = ProjectMetadataRepositoryImpl(const ProjectMetadataDatasource());
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      if (sourceImageDir.existsSync()) sourceImageDir.deleteSync(recursive: true);
    });

    test('ensureMetadata creates project.json when missing', () async {
      final metadata = await repository.ensureMetadata(tempDir.path, id: 'avyn-os', name: 'Avyn');

      expect(metadata.id, 'avyn-os');
      expect(metadata.name, 'Avyn');
      expect(File(p.join(tempDir.path, '.avyn', 'project.json')).existsSync(), isTrue);
    });

    test('ensureMetadata is a no-op (returns existing) when project.json already exists', () async {
      await repository.ensureMetadata(tempDir.path, id: 'avyn-os', name: 'Avyn');
      await repository.writeName(tempDir.path, 'Renamed');

      final metadata = await repository.ensureMetadata(tempDir.path, id: 'avyn-os', name: 'Would Overwrite');

      expect(metadata.name, 'Renamed');
    });

    test('writeName updates the name and preserves the id', () async {
      await repository.ensureMetadata(tempDir.path, id: 'avyn-os', name: 'Avyn');

      await repository.writeName(tempDir.path, 'Avyn Renamed');

      final metadata = await repository.readMetadata(tempDir.path);
      expect(metadata!.id, 'avyn-os');
      expect(metadata.name, 'Avyn Renamed');
    });

    test('setIcon stores the image and records its filename in project.json', () async {
      await repository.ensureMetadata(tempDir.path, id: 'avyn-os', name: 'Avyn');
      final source = File(p.join(sourceImageDir.path, 'logo.png'))..writeAsBytesSync([1, 2, 3]);

      final fileName = await repository.setIcon(tempDir.path, source.path);

      expect(fileName, 'icon.png');
      final metadata = await repository.readMetadata(tempDir.path);
      expect(metadata!.iconFileName, 'icon.png');
    });

    test('removeIcon deletes the file and clears the field in project.json', () async {
      await repository.ensureMetadata(tempDir.path, id: 'avyn-os', name: 'Avyn');
      final source = File(p.join(sourceImageDir.path, 'logo.png'))..writeAsBytesSync([1]);
      await repository.setIcon(tempDir.path, source.path);

      await repository.removeIcon(tempDir.path);

      final metadata = await repository.readMetadata(tempDir.path);
      expect(metadata!.iconFileName, isNull);
      expect(File(p.join(tempDir.path, '.avyn', 'icon.png')).existsSync(), isFalse);
    });
  });
}
