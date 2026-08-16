import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/model/project_metadata.dart';

/// Reads/writes the `.avyn/` folder inside a project's `localPath` —
/// `project.json` (authoritative name/settings/icon reference) and the
/// optional icon image file itself. See
/// `docs/adr/0004-avyn-folder-project-metadata.md`.
class ProjectMetadataDatasource {
  const ProjectMetadataDatasource();

  String avynDirPath(String localPath) => p.join(localPath, '.avyn');
  String _metadataFilePath(String localPath) => p.join(avynDirPath(localPath), 'project.json');

  bool exists(String localPath) => File(_metadataFilePath(localPath)).existsSync();

  Future<ProjectMetadata?> read(String localPath) async {
    final file = File(_metadataFilePath(localPath));
    if (!await file.exists()) return null;
    final contents = await file.readAsString();
    return ProjectMetadata.fromJson(jsonDecode(contents) as Map<String, dynamic>);
  }

  Future<void> write(String localPath, ProjectMetadata metadata) async {
    final dir = Directory(avynDirPath(localPath));
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File(_metadataFilePath(localPath));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(metadata.toJson()));
  }

  /// Copies [sourceImagePath] into `.avyn/icon.<ext>` (preserving the
  /// original extension), removing any previously-stored icon file first.
  /// Returns the stored file's name (e.g. `icon.png`) to be saved as
  /// [ProjectMetadata.iconFileName].
  Future<String> writeIcon(String localPath, String sourceImagePath) async {
    await removeIcon(localPath);
    final ext = p.extension(sourceImagePath);
    final fileName = 'icon$ext';
    final dir = Directory(avynDirPath(localPath));
    if (!await dir.exists()) await dir.create(recursive: true);
    await File(sourceImagePath).copy(p.join(dir.path, fileName));
    return fileName;
  }

  /// Deletes any `.avyn/icon.*` file, regardless of extension.
  Future<void> removeIcon(String localPath) async {
    final dir = Directory(avynDirPath(localPath));
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File && p.basenameWithoutExtension(entity.path) == 'icon') {
        await entity.delete();
      }
    }
  }
}
