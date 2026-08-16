import '../../domain/model/project_metadata.dart';
import '../../domain/repository/project_metadata_repository.dart';
import '../datasource/project_metadata_datasource.dart';

class ProjectMetadataRepositoryImpl implements ProjectMetadataRepository {
  final ProjectMetadataDatasource datasource;

  ProjectMetadataRepositoryImpl(this.datasource);

  @override
  Future<ProjectMetadata> ensureMetadata(
    String localPath, {
    required String id,
    required String name,
  }) async {
    final existing = await datasource.read(localPath);
    if (existing != null) return existing;
    final metadata = ProjectMetadata(id: id, name: name);
    await datasource.write(localPath, metadata);
    return metadata;
  }

  @override
  Future<ProjectMetadata?> readMetadata(String localPath) => datasource.read(localPath);

  @override
  Future<void> writeName(String localPath, String name) async {
    final existing = await datasource.read(localPath);
    final updated = existing?.copyWith(name: name) ?? ProjectMetadata(id: '', name: name);
    await datasource.write(localPath, updated);
  }

  @override
  Future<String> setIcon(String localPath, String sourceImagePath) async {
    final fileName = await datasource.writeIcon(localPath, sourceImagePath);
    final existing = await datasource.read(localPath);
    final updated = (existing ?? const ProjectMetadata(id: '', name: ''))
        .copyWith(iconFileName: () => fileName);
    await datasource.write(localPath, updated);
    return fileName;
  }

  @override
  Future<void> removeIcon(String localPath) async {
    await datasource.removeIcon(localPath);
    final existing = await datasource.read(localPath);
    if (existing == null) return;
    await datasource.write(localPath, existing.copyWith(iconFileName: () => null));
  }
}
