import '../../domain/model/project.dart';
import '../../domain/repository/projects_repository.dart';
import '../datasource/projects_local_datasource.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  final ProjectsLocalDatasource datasource;

  ProjectsRepositoryImpl(this.datasource);

  @override
  Future<List<Project>> getProjects() async {
    final stored = datasource.read();
    return stored.map(Project.fromJson).toList();
  }

  @override
  Future<void> saveProjects(List<Project> projects) async {
    await datasource.write(projects.map((p) => p.toJson()).toList());
  }
}
