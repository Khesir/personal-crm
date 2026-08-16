import '../model/project_metadata.dart';

abstract class ProjectMetadataRepository {
  /// Creates `.avyn/project.json` at [localPath] if it doesn't already
  /// exist, seeded with [id]/[name]. No-ops (returns the existing metadata)
  /// if it's already present — used both for fresh registration and
  /// auto-heal on first visit of a project registered before this feature
  /// existed.
  Future<ProjectMetadata> ensureMetadata(
    String localPath, {
    required String id,
    required String name,
  });

  Future<ProjectMetadata?> readMetadata(String localPath);

  Future<void> writeName(String localPath, String name);

  /// Copies [sourceImagePath] into the project's `.avyn/` folder and records
  /// it in `project.json`. Returns the stored filename (e.g. `icon.png`).
  Future<String> setIcon(String localPath, String sourceImagePath);

  Future<void> removeIcon(String localPath);
}
