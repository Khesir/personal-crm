import '../model/project.dart';

abstract class ProjectsRepository {
  Future<List<Project>> getProjects();

  Future<void> saveProjects(List<Project> projects);
}
