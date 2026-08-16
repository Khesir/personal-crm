import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:crm/core/state/state.dart';
import 'package:crm/features/settings/domain/controller/projects_controller.dart';
import 'package:crm/features/settings/domain/model/project.dart';
import 'package:crm/features/settings/domain/model/project_metadata.dart';
import 'package:crm/features/settings/domain/repository/project_metadata_repository.dart';
import 'package:crm/features/settings/domain/repository/projects_repository.dart';

class FakeProjectsRepository implements ProjectsRepository {
  List<Project> stored;

  FakeProjectsRepository([List<Project>? initial]) : stored = initial ?? [];

  @override
  Future<List<Project>> getProjects() async => List.unmodifiable(stored);

  @override
  Future<void> saveProjects(List<Project> projects) async {
    stored = List.of(projects);
  }
}

/// In-memory fake — keeps these tests hermetic (the real
/// `ProjectMetadataRepositoryImpl` writes to disk at `localPath`, and most
/// tests here use fabricated paths like `C:\repo\alpha` that must never
/// actually be touched).
class FakeProjectMetadataRepository implements ProjectMetadataRepository {
  final Map<String, ProjectMetadata> store = {};

  @override
  Future<ProjectMetadata> ensureMetadata(
    String localPath, {
    required String id,
    required String name,
  }) async {
    return store.putIfAbsent(localPath, () => ProjectMetadata(id: id, name: name));
  }

  @override
  Future<ProjectMetadata?> readMetadata(String localPath) async => store[localPath];

  @override
  Future<void> writeName(String localPath, String name) async {
    final existing = store[localPath];
    store[localPath] = (existing ?? ProjectMetadata(id: '', name: name)).copyWith(name: name);
  }

  @override
  Future<String> setIcon(String localPath, String sourceImagePath) async {
    final fileName = 'icon${p.extension(sourceImagePath)}';
    final existing = store[localPath];
    store[localPath] =
        (existing ?? const ProjectMetadata(id: '', name: '')).copyWith(iconFileName: () => fileName);
    return fileName;
  }

  @override
  Future<void> removeIcon(String localPath) async {
    final existing = store[localPath];
    if (existing == null) return;
    store[localPath] = existing.copyWith(iconFileName: () => null);
  }
}

void main() {
  group('ProjectsController', () {
    test('load() populates state with projects from the repository', () async {
      final repo = FakeProjectsRepository([
        const Project(
          id: 'personal-crm',
          name: 'personal-crm',
          localPath: r'C:\repo\crm',
          projectKey: 'personal-crm',
        ),
      ]);
      final controller = ProjectsController(repo, FakeProjectMetadataRepository());

      await controller.load();

      expect(controller.data, hasLength(1));
      expect(controller.data!.first.id, 'personal-crm');

      controller.dispose();
    });

    test('addProject derives a slugified id/projectKey from the name', () async {
      final repo = FakeProjectsRepository();
      final controller = ProjectsController(repo, FakeProjectMetadataRepository());
      await controller.load();

      await controller.addProject('My Cool Project', r'C:\repo\my-cool-project');

      expect(controller.data, hasLength(1));
      final project = controller.data!.first;
      expect(project.id, 'my-cool-project');
      expect(project.projectKey, 'my-cool-project');
      expect(project.name, 'My Cool Project');
      expect(project.localPath, r'C:\repo\my-cool-project');

      controller.dispose();
    });

    test('addProject appends a numeric suffix on slug collision', () async {
      final repo = FakeProjectsRepository();
      final controller = ProjectsController(repo, FakeProjectMetadataRepository());
      await controller.load();

      await controller.addProject('My Project', r'C:\repo\one');
      await controller.addProject('My Project', r'C:\repo\two');

      expect(controller.data, hasLength(2));
      expect(controller.data![0].id, 'my-project');
      expect(controller.data![1].id, 'my-project-2');

      controller.dispose();
    });

    test('addProject persists the new project via the repository', () async {
      final repo = FakeProjectsRepository();
      final controller = ProjectsController(repo, FakeProjectMetadataRepository());
      await controller.load();

      await controller.addProject('Alpha', r'C:\repo\alpha');

      expect(repo.stored, hasLength(1));
      expect(repo.stored.first.id, 'alpha');

      controller.dispose();
    });

    test('addProject also seeds .avyn/project.json metadata for the new project', () async {
      final repo = FakeProjectsRepository();
      final metadataRepo = FakeProjectMetadataRepository();
      final controller = ProjectsController(repo, metadataRepo);
      await controller.load();

      await controller.addProject('Alpha', r'C:\repo\alpha');

      final metadata = metadataRepo.store[r'C:\repo\alpha'];
      expect(metadata, isNotNull);
      expect(metadata!.id, 'alpha');
      expect(metadata.name, 'Alpha');

      controller.dispose();
    });

    test('updateProject changes name/path/toggles without changing id or projectKey', () async {
      final repo = FakeProjectsRepository();
      final controller = ProjectsController(repo, FakeProjectMetadataRepository());
      await controller.load();
      await controller.addProject('Alpha', r'C:\repo\alpha');
      final original = controller.data!.first;

      await controller.updateProject(
        original.id,
        name: 'Alpha Renamed',
        localPath: r'C:\repo\alpha-renamed',
      );

      final updated = controller.data!.first;
      expect(updated.id, original.id);
      expect(updated.projectKey, original.projectKey);
      expect(updated.name, 'Alpha Renamed');
      expect(updated.localPath, r'C:\repo\alpha-renamed');

      controller.dispose();
    });

    test('updateProject persists changes via the repository', () async {
      final repo = FakeProjectsRepository();
      final controller = ProjectsController(repo, FakeProjectMetadataRepository());
      await controller.load();
      await controller.addProject('Alpha', r'C:\repo\alpha');
      final original = controller.data!.first;

      await controller.updateProject(original.id, name: 'Alpha Renamed');

      expect(repo.stored.first.name, 'Alpha Renamed');

      controller.dispose();
    });

    test('updateProject with a new name writes through to .avyn/project.json', () async {
      final repo = FakeProjectsRepository();
      final metadataRepo = FakeProjectMetadataRepository();
      final controller = ProjectsController(repo, metadataRepo);
      await controller.load();
      await controller.addProject('Alpha', r'C:\repo\alpha');

      await controller.updateProject('alpha', name: 'Alpha Renamed');

      expect(metadataRepo.store[r'C:\repo\alpha']!.name, 'Alpha Renamed');

      controller.dispose();
    });

    test('removeProject deletes the project and persists the change', () async {
      final repo = FakeProjectsRepository();
      final controller = ProjectsController(repo, FakeProjectMetadataRepository());
      await controller.load();
      await controller.addProject('Alpha', r'C:\repo\alpha');
      await controller.addProject('Beta', r'C:\repo\beta');

      await controller.removeProject('alpha');

      expect(controller.data, hasLength(1));
      expect(controller.data!.first.id, 'beta');
      expect(repo.stored, hasLength(1));
      expect(repo.stored.first.id, 'beta');

      controller.dispose();
    });

    test('addProject returns success with the created project on a non-duplicate path', () async {
      final repo = FakeProjectsRepository();
      final controller = ProjectsController(repo, FakeProjectMetadataRepository());
      await controller.load();

      final result = await controller.addProject('Alpha', r'C:\repo\alpha');

      expect(result, isA<ProjectSaveSuccess>());
      final project = (result as ProjectSaveSuccess).project;
      expect(project.id, 'alpha');
      expect(project.localPath, r'C:\repo\alpha');
      expect(controller.data, hasLength(1));

      controller.dispose();
    });

    test('addProject rejects a path already registered to another project without throwing', () async {
      final repo = FakeProjectsRepository();
      final controller = ProjectsController(repo, FakeProjectMetadataRepository());
      await controller.load();
      await controller.addProject('Alpha', r'C:\repo\alpha');

      final result = await controller.addProject('Beta', r'C:\repo\alpha');

      expect(result, isA<ProjectSaveDuplicatePath>());
      expect((result as ProjectSaveDuplicatePath).existing.name, 'Alpha');
      // Rejected registration must not be persisted.
      expect(controller.data, hasLength(1));
      expect(repo.stored, hasLength(1));

      controller.dispose();
    });

    test('addProject rejects a duplicate path regardless of path formatting differences', () async {
      final repo = FakeProjectsRepository();
      final controller = ProjectsController(repo, FakeProjectMetadataRepository());
      await controller.load();
      await controller.addProject('Alpha', r'C:\repo\alpha');

      final result = await controller.addProject('Beta', r'C:\repo\alpha\');

      expect(result, isA<ProjectSaveDuplicatePath>());

      controller.dispose();
    });

    test('persistence round trip via the fake repository', () async {
      final repo = FakeProjectsRepository();
      final firstController = ProjectsController(repo, FakeProjectMetadataRepository());
      await firstController.load();
      await firstController.addProject('Alpha', r'C:\repo\alpha');
      firstController.dispose();

      final secondController = ProjectsController(repo, FakeProjectMetadataRepository());
      await secondController.load();

      expect(secondController.data, hasLength(1));
      expect(secondController.data!.first.id, 'alpha');
      expect(secondController.data!.first.localPath, r'C:\repo\alpha');

      secondController.dispose();
    });

    group('refreshFromDisk', () {
      test('updates the cached name/icon when .avyn/project.json has changed', () async {
        final repo = FakeProjectsRepository();
        final metadataRepo = FakeProjectMetadataRepository();
        final controller = ProjectsController(repo, metadataRepo);
        await controller.load();
        await controller.addProject('Alpha', r'C:\repo\alpha');

        // Simulate an external edit to project.json.
        metadataRepo.store[r'C:\repo\alpha'] =
            metadataRepo.store[r'C:\repo\alpha']!.copyWith(name: 'Renamed Externally');

        await controller.refreshFromDisk('alpha');

        expect(controller.data!.first.name, 'Renamed Externally');
        expect(repo.stored.first.name, 'Renamed Externally');

        controller.dispose();
      });

      test('is a no-op when metadata is unchanged (does not re-persist)', () async {
        final repo = FakeProjectsRepository();
        final metadataRepo = FakeProjectMetadataRepository();
        final controller = ProjectsController(repo, metadataRepo);
        await controller.load();
        await controller.addProject('Alpha', r'C:\repo\alpha');
        final savedCountBefore = repo.stored.length;

        await controller.refreshFromDisk('alpha');

        expect(controller.data!.first.name, 'Alpha');
        expect(repo.stored, hasLength(savedCountBefore));

        controller.dispose();
      });

      test('auto-heals by creating metadata for a project that predates this feature', () async {
        final repo = FakeProjectsRepository([
          const Project(
            id: 'legacy',
            name: 'Legacy Project',
            localPath: r'C:\repo\legacy',
            projectKey: 'legacy',
          ),
        ]);
        final metadataRepo = FakeProjectMetadataRepository();
        final controller = ProjectsController(repo, metadataRepo);
        await controller.load();
        expect(metadataRepo.store[r'C:\repo\legacy'], isNull);

        await controller.refreshFromDisk('legacy');

        expect(metadataRepo.store[r'C:\repo\legacy'], isNotNull);
        expect(metadataRepo.store[r'C:\repo\legacy']!.name, 'Legacy Project');

        controller.dispose();
      });
    });

    group('setProjectIcon / removeProjectIcon', () {
      test('setProjectIcon stores the icon and updates the cached project', () async {
        final repo = FakeProjectsRepository();
        final controller = ProjectsController(repo, FakeProjectMetadataRepository());
        await controller.load();
        await controller.addProject('Alpha', r'C:\repo\alpha');

        await controller.setProjectIcon('alpha', r'C:\Users\me\Pictures\logo.png');

        expect(controller.data!.first.iconFileName, 'icon.png');
        expect(repo.stored.first.iconFileName, 'icon.png');

        controller.dispose();
      });

      test('removeProjectIcon clears the cached icon', () async {
        final repo = FakeProjectsRepository();
        final controller = ProjectsController(repo, FakeProjectMetadataRepository());
        await controller.load();
        await controller.addProject('Alpha', r'C:\repo\alpha');
        await controller.setProjectIcon('alpha', r'C:\Users\me\Pictures\logo.png');

        await controller.removeProjectIcon('alpha');

        expect(controller.data!.first.iconFileName, isNull);
        expect(repo.stored.first.iconFileName, isNull);

        controller.dispose();
      });
    });

    group('createProject', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('projects_controller_test_');
      });

      tearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      test('builds <parent>/<slug>, creates it on disk, and registers the project', () async {
        final repo = FakeProjectsRepository();
        final controller = ProjectsController(repo, FakeProjectMetadataRepository());
        await controller.load();

        final result = await controller.createProject('My Cool Project', tempDir.path);

        final expectedPath = p.join(tempDir.path, 'my-cool-project');
        expect(result, isA<ProjectSaveSuccess>());
        final project = (result as ProjectSaveSuccess).project;
        expect(project.id, 'my-cool-project');
        expect(project.projectKey, 'my-cool-project');
        expect(project.name, 'My Cool Project');
        expect(project.localPath, expectedPath);
        expect(Directory(expectedPath).existsSync(), isTrue);
        expect(controller.data, hasLength(1));
        expect(repo.stored, hasLength(1));
        expect(repo.stored.first.localPath, expectedPath);

        controller.dispose();
      });

      test('returns folderCollision without creating or persisting anything when the target path already exists', () async {
        final targetPath = p.join(tempDir.path, 'alpha');
        Directory(targetPath).createSync(recursive: true);
        // Prove existing contents survive: nothing should touch this folder.
        File(p.join(targetPath, 'marker.txt')).writeAsStringSync('keep me');

        final repo = FakeProjectsRepository();
        final controller = ProjectsController(repo, FakeProjectMetadataRepository());
        await controller.load();

        final result = await controller.createProject('Alpha', tempDir.path);

        expect(result, isA<ProjectSaveFolderCollision>());
        expect((result as ProjectSaveFolderCollision).path, targetPath);
        expect(controller.data, isEmpty);
        expect(repo.stored, isEmpty);
        expect(File(p.join(targetPath, 'marker.txt')).readAsStringSync(), 'keep me');

        controller.dispose();
      });

      test('slugifies the name for both id and the created folder name', () async {
        final repo = FakeProjectsRepository();
        final controller = ProjectsController(repo, FakeProjectMetadataRepository());
        await controller.load();

        await controller.createProject('My Project', tempDir.path);
        final result = await controller.createProject('My Project', tempDir.path);

        expect(result, isA<ProjectSaveSuccess>());
        final project = (result as ProjectSaveSuccess).project;
        expect(project.id, 'my-project-2');
        expect(project.localPath, p.join(tempDir.path, 'my-project-2'));
        expect(Directory(p.join(tempDir.path, 'my-project-2')).existsSync(), isTrue);

        controller.dispose();
      });

      test('also seeds .avyn/project.json metadata for the newly created project', () async {
        final repo = FakeProjectsRepository();
        final metadataRepo = FakeProjectMetadataRepository();
        final controller = ProjectsController(repo, metadataRepo);
        await controller.load();

        final result = await controller.createProject('My Cool Project', tempDir.path);
        final project = (result as ProjectSaveSuccess).project;

        final metadata = metadataRepo.store[project.localPath];
        expect(metadata, isNotNull);
        expect(metadata!.id, 'my-cool-project');
        expect(metadata.name, 'My Cool Project');

        controller.dispose();
      });
    });
  });
}
