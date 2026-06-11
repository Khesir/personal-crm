import '../../domain/model/project.dart';
import '../../domain/repository/projects_repository.dart';
import '../datasource/projects_local_datasource.dart';

const kSeedProjectId = 'personal-crm';
const kSeedProjectName = 'personal-crm';
const kSeedProjectLocalPath = r'C:\Users\ajriz\Documents\Projects\keep-track\crm';

final _seedProjects = [
  const Project(
    id: kSeedProjectId,
    name: kSeedProjectName,
    localPath: kSeedProjectLocalPath,
    projectKey: kSeedProjectId,
    hasBugReports: true,
    hasAnnouncements: true,
  ),
];

class ProjectsRepositoryImpl implements ProjectsRepository {
  final ProjectsLocalDatasource datasource;

  ProjectsRepositoryImpl(this.datasource);

  @override
  Future<List<Project>> getProjects() async {
    final stored = datasource.read();
    if (stored.isEmpty) {
      await saveProjects(_seedProjects);
      return _seedProjects;
    }
    return stored.map(Project.fromJson).toList();
  }

  @override
  Future<void> saveProjects(List<Project> projects) async {
    await datasource.write(projects.map((p) => p.toJson()).toList());
  }
}
