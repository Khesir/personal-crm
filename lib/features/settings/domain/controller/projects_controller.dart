import 'dart:io' show Directory, Platform;

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

import 'package:crm/core/state/state.dart';
import '../helper/project_slug.dart';
import '../model/project.dart';
import '../repository/project_metadata_repository.dart';
import '../repository/projects_repository.dart';

/// Result of [ProjectsController.addProject] and
/// [ProjectsController.createProject].
///
/// Kept as an extensible sealed type (rather than throwing) so callers such
/// as [ProjectFormDialog] can pattern-match and render a specific inline
/// error instead of catching a generic exception.
sealed class ProjectSaveResult {
  const ProjectSaveResult();

  const factory ProjectSaveResult.success(Project project) = ProjectSaveSuccess;

  const factory ProjectSaveResult.duplicatePath(Project existing) = ProjectSaveDuplicatePath;

  const factory ProjectSaveResult.folderCollision(String path) = ProjectSaveFolderCollision;
}

class ProjectSaveSuccess extends ProjectSaveResult {
  final Project project;
  const ProjectSaveSuccess(this.project);
}

/// [existing] is the already-registered project whose `localPath` collided
/// with the one being submitted — used to name it in the inline error.
class ProjectSaveDuplicatePath extends ProjectSaveResult {
  final Project existing;
  const ProjectSaveDuplicatePath(this.existing);
}

/// [path] is the `<parentDirectoryPath>/<slug>` folder that already exists
/// on disk — returned by [ProjectsController.createProject] when a folder
/// with that name is already there, so nothing was created or persisted.
class ProjectSaveFolderCollision extends ProjectSaveResult {
  final String path;
  const ProjectSaveFolderCollision(this.path);
}

class ProjectsController extends StreamState<AsyncState<List<Project>>> {
  final ProjectsRepository repository;
  final ProjectMetadataRepository metadataRepository;

  ProjectsController(this.repository, this.metadataRepository) : super(const AsyncLoading());

  Future<void> load() => execute(() => repository.getProjects());

  /// Normalizes [path] for duplicate-path comparison. This is a Windows-first
  /// codebase and Windows paths are case-insensitive, so paths are
  /// lower-cased there after `p.normalize` collapses separators/`.`/`..`
  /// segments and trailing slashes; other platforms compare case-sensitively.
  String _normalizeForComparison(String path) {
    final normalized = p.normalize(path);
    return Platform.isWindows ? normalized.toLowerCase() : normalized;
  }

  Future<ProjectSaveResult> addProject(String name, String localPath) async {
    final current = data ?? [];
    final normalizedNew = _normalizeForComparison(localPath);
    for (final project in current) {
      if (_normalizeForComparison(project.localPath) == normalizedNew) {
        return ProjectSaveResult.duplicatePath(project);
      }
    }

    final id = uniqueSlug(name, current.map((p) => p.id));
    final project = Project(
      id: id,
      name: name,
      localPath: localPath,
      projectKey: id,
    );
    final updated = [...current, project];
    await execute(() async {
      await repository.saveProjects(updated);
      return updated;
    });
    await _ensureMetadataSafely(localPath, id: id, name: name);
    return ProjectSaveResult.success(project);
  }

  /// `.avyn/project.json` is app-owned infrastructure, not user content, so
  /// it's always auto-created (unlike `issues/`, see
  /// `docs/adr/0004-avyn-folder-project-metadata.md`) — but a failure here
  /// must never undo an already-persisted registration.
  Future<void> _ensureMetadataSafely(String localPath, {required String id, required String name}) async {
    try {
      await metadataRepository.ensureMetadata(localPath, id: id, name: name);
    } catch (_) {
      // Registration already succeeded; metadata scaffolding is best-effort.
    }
  }

  /// Creates a brand-new project folder at `<parentDirectoryPath>/<slug>`
  /// and registers it. Returns [ProjectSaveResult.folderCollision] without
  /// creating or persisting anything if that path already exists on disk.
  ///
  /// Only creates the bare directory — scaffolding `issues/` inside it is
  /// the caller's responsibility (see [initializeIssuesFolder] in the
  /// `kanban` feature), since this controller intentionally has no
  /// dependency on that feature's domain layer.
  Future<ProjectSaveResult> createProject(String name, String parentDirectoryPath) async {
    final current = data ?? [];
    final slug = uniqueSlug(name, current.map((p) => p.id));
    final targetPath = p.join(parentDirectoryPath, slug);

    if (Directory(targetPath).existsSync()) {
      return ProjectSaveResult.folderCollision(targetPath);
    }

    Directory(targetPath).createSync(recursive: true);

    final project = Project(
      id: slug,
      name: name,
      localPath: targetPath,
      projectKey: slug,
    );
    final updated = [...current, project];
    await execute(() async {
      await repository.saveProjects(updated);
      return updated;
    });
    await _ensureMetadataSafely(targetPath, id: slug, name: name);
    return ProjectSaveResult.success(project);
  }

  Future<void> updateProject(
    String id, {
    String? name,
    String? localPath,
  }) async {
    final current = data ?? [];
    final project = current.where((p) => p.id == id).firstOrNull;
    if (project == null) return;

    if (name != null) {
      await _ensureMetadataSafely(localPath ?? project.localPath, id: project.id, name: name);
      try {
        await metadataRepository.writeName(localPath ?? project.localPath, name);
      } catch (_) {
        // The cache below still updates even if the on-disk write fails.
      }
    }

    final updated = [
      for (final p in current)
        if (p.id == id)
          p.copyWith(name: name, localPath: localPath)
        else
          p,
    ];
    await execute(() async {
      await repository.saveProjects(updated);
      return updated;
    });
  }

  /// Re-reads `.avyn/project.json` for the project with [id] and updates the
  /// cached name/icon if they've changed — called when a project is
  /// "visited" (selected in the rail), not on every list load. See
  /// `docs/adr/0004-avyn-folder-project-metadata.md`.
  Future<void> refreshFromDisk(String id) async {
    final current = data ?? [];
    final project = current.where((p) => p.id == id).firstOrNull;
    if (project == null) return;

    final metadata = await metadataRepository.ensureMetadata(
      project.localPath,
      id: project.id,
      name: project.name,
    );
    if (metadata.name == project.name && metadata.iconFileName == project.iconFileName) return;

    final updated = [
      for (final p in current)
        if (p.id == id)
          p.copyWith(name: metadata.name, iconFileName: () => metadata.iconFileName)
        else
          p,
    ];
    await execute(() async {
      await repository.saveProjects(updated);
      return updated;
    });
  }

  Future<void> setProjectIcon(String id, String sourceImagePath) async {
    final current = data ?? [];
    final project = current.where((p) => p.id == id).firstOrNull;
    if (project == null) return;

    final fileName = await metadataRepository.setIcon(project.localPath, sourceImagePath);
    final updated = [
      for (final p in current)
        if (p.id == id) p.copyWith(iconFileName: () => fileName) else p,
    ];
    await execute(() async {
      await repository.saveProjects(updated);
      return updated;
    });
  }

  Future<void> removeProjectIcon(String id) async {
    final current = data ?? [];
    final project = current.where((p) => p.id == id).firstOrNull;
    if (project == null) return;

    await metadataRepository.removeIcon(project.localPath);
    final updated = [
      for (final p in current)
        if (p.id == id) p.copyWith(iconFileName: () => null) else p,
    ];
    await execute(() async {
      await repository.saveProjects(updated);
      return updated;
    });
  }

  Future<void> removeProject(String id) async {
    final current = data ?? [];
    final updated = current.where((p) => p.id != id).toList();
    await execute(() async {
      await repository.saveProjects(updated);
      return updated;
    });
  }
}
