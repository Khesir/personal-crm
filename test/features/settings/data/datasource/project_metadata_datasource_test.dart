import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:crm/features/settings/data/datasource/project_metadata_datasource.dart';
import 'package:crm/features/settings/domain/model/project_metadata.dart';

void main() {
  group('ProjectMetadataDatasource', () {
    late Directory tempDir;
    late Directory sourceImageDir;
    const datasource = ProjectMetadataDatasource();

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('project_metadata_test_');
      sourceImageDir = Directory.systemTemp.createTempSync('project_metadata_src_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      if (sourceImageDir.existsSync()) sourceImageDir.deleteSync(recursive: true);
    });

    test('exists() is false when no project.json has been written', () {
      expect(datasource.exists(tempDir.path), isFalse);
    });

    test('read() returns null when .avyn/project.json does not exist', () async {
      expect(await datasource.read(tempDir.path), isNull);
    });

    test('write() creates .avyn/project.json with the given metadata, then read() round-trips it', () async {
      const metadata = ProjectMetadata(id: 'avyn-os', name: 'Avyn', settings: {'theme': 'dark'});

      await datasource.write(tempDir.path, metadata);

      expect(datasource.exists(tempDir.path), isTrue);
      expect(Directory(p.join(tempDir.path, '.avyn')).existsSync(), isTrue);
      final read = await datasource.read(tempDir.path);
      expect(read!.id, 'avyn-os');
      expect(read.name, 'Avyn');
      expect(read.settings, {'theme': 'dark'});
      expect(read.iconFileName, isNull);
    });

    test('write() overwrites an existing project.json', () async {
      await datasource.write(tempDir.path, const ProjectMetadata(id: 'x', name: 'First'));
      await datasource.write(tempDir.path, const ProjectMetadata(id: 'x', name: 'Second'));

      final read = await datasource.read(tempDir.path);
      expect(read!.name, 'Second');
    });

    test('writeIcon() copies the source image into .avyn/icon.<ext> and returns its filename', () async {
      final source = File(p.join(sourceImageDir.path, 'logo.png'))..writeAsBytesSync([1, 2, 3]);

      final fileName = await datasource.writeIcon(tempDir.path, source.path);

      expect(fileName, 'icon.png');
      final iconFile = File(p.join(tempDir.path, '.avyn', 'icon.png'));
      expect(iconFile.existsSync(), isTrue);
      expect(iconFile.readAsBytesSync(), [1, 2, 3]);
    });

    test('writeIcon() removes a previously-stored icon with a different extension', () async {
      final pngSource = File(p.join(sourceImageDir.path, 'logo.png'))..writeAsBytesSync([1]);
      final jpgSource = File(p.join(sourceImageDir.path, 'logo.jpg'))..writeAsBytesSync([2]);

      await datasource.writeIcon(tempDir.path, pngSource.path);
      await datasource.writeIcon(tempDir.path, jpgSource.path);

      expect(File(p.join(tempDir.path, '.avyn', 'icon.png')).existsSync(), isFalse);
      expect(File(p.join(tempDir.path, '.avyn', 'icon.jpg')).existsSync(), isTrue);
    });

    test('removeIcon() deletes the icon file regardless of extension', () async {
      final source = File(p.join(sourceImageDir.path, 'logo.webp'))..writeAsBytesSync([9]);
      await datasource.writeIcon(tempDir.path, source.path);

      await datasource.removeIcon(tempDir.path);

      expect(File(p.join(tempDir.path, '.avyn', 'icon.webp')).existsSync(), isFalse);
    });

    test('removeIcon() is a no-op when .avyn/ does not exist yet', () async {
      await datasource.removeIcon(tempDir.path);
      expect(Directory(p.join(tempDir.path, '.avyn')).existsSync(), isFalse);
    });
  });
}
