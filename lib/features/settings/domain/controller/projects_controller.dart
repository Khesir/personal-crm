import 'package:crm/core/state/state.dart';
import '../helper/project_slug.dart';
import '../model/project.dart';
import '../repository/projects_repository.dart';

class ProjectsController extends StreamState<AsyncState<List<Project>>> {
  final ProjectsRepository repository;

  ProjectsController(this.repository) : super(const AsyncLoading());

  Future<void> load() => execute(() => repository.getProjects());

  Future<void> addProject(String name, String localPath) async {
    final current = data ?? [];
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
  }

  Future<void> updateProject(
    String id, {
    String? name,
    String? localPath,
  }) async {
    final current = data ?? [];
    final updated = [
      for (final project in current)
        if (project.id == id)
          project.copyWith(name: name, localPath: localPath)
        else
          project,
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
