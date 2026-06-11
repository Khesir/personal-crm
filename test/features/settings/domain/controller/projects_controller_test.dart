import 'package:flutter_test/flutter_test.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/features/settings/domain/controller/projects_controller.dart';
import 'package:crm/features/settings/domain/model/project.dart';
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

void main() {
  group('ProjectsController', () {
    test('load() populates state with projects from the repository', () async {
      final repo = FakeProjectsRepository([
        const Project(
          id: 'personal-crm',
          name: 'personal-crm',
          localPath: r'C:\repo\crm',
          projectKey: 'personal-crm',
          hasBugReports: true,
          hasAnnouncements: true,
        ),
      ]);
      final controller = ProjectsController(repo);

      await controller.load();

      expect(controller.data, hasLength(1));
      expect(controller.data!.first.id, 'personal-crm');

      controller.dispose();
    });

    test('addProject derives a slugified id/projectKey from the name', () async {
      final repo = FakeProjectsRepository();
      final controller = ProjectsController(repo);
      await controller.load();

      await controller.addProject('My Cool Project', r'C:\repo\my-cool-project');

      expect(controller.data, hasLength(1));
      final project = controller.data!.first;
      expect(project.id, 'my-cool-project');
      expect(project.projectKey, 'my-cool-project');
      expect(project.name, 'My Cool Project');
      expect(project.localPath, r'C:\repo\my-cool-project');
      expect(project.hasBugReports, isFalse);
      expect(project.hasAnnouncements, isFalse);

      controller.dispose();
    });

    test('addProject appends a numeric suffix on slug collision', () async {
      final repo = FakeProjectsRepository();
      final controller = ProjectsController(repo);
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
      final controller = ProjectsController(repo);
      await controller.load();

      await controller.addProject('Alpha', r'C:\repo\alpha');

      expect(repo.stored, hasLength(1));
      expect(repo.stored.first.id, 'alpha');

      controller.dispose();
    });

    test('updateProject changes name/path/toggles without changing id or projectKey', () async {
      final repo = FakeProjectsRepository();
      final controller = ProjectsController(repo);
      await controller.load();
      await controller.addProject('Alpha', r'C:\repo\alpha');
      final original = controller.data!.first;

      await controller.updateProject(
        original.id,
        name: 'Alpha Renamed',
        localPath: r'C:\repo\alpha-renamed',
        hasBugReports: true,
        hasAnnouncements: true,
      );

      final updated = controller.data!.first;
      expect(updated.id, original.id);
      expect(updated.projectKey, original.projectKey);
      expect(updated.name, 'Alpha Renamed');
      expect(updated.localPath, r'C:\repo\alpha-renamed');
      expect(updated.hasBugReports, isTrue);
      expect(updated.hasAnnouncements, isTrue);

      controller.dispose();
    });

    test('updateProject persists changes via the repository', () async {
      final repo = FakeProjectsRepository();
      final controller = ProjectsController(repo);
      await controller.load();
      await controller.addProject('Alpha', r'C:\repo\alpha');
      final original = controller.data!.first;

      await controller.updateProject(original.id, name: 'Alpha Renamed');

      expect(repo.stored.first.name, 'Alpha Renamed');

      controller.dispose();
    });

    test('removeProject deletes the project and persists the change', () async {
      final repo = FakeProjectsRepository();
      final controller = ProjectsController(repo);
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

    test('persistence round trip via the fake repository', () async {
      final repo = FakeProjectsRepository();
      final firstController = ProjectsController(repo);
      await firstController.load();
      await firstController.addProject('Alpha', r'C:\repo\alpha');
      firstController.dispose();

      final secondController = ProjectsController(repo);
      await secondController.load();

      expect(secondController.data, hasLength(1));
      expect(secondController.data!.first.id, 'alpha');
      expect(secondController.data!.first.localPath, r'C:\repo\alpha');

      secondController.dispose();
    });
  });
}
