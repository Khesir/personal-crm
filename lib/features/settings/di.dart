import 'package:shared_preferences/shared_preferences.dart';
import 'data/datasource/projects_local_datasource.dart';
import 'data/datasource/settings_env_datasource.dart';
import 'data/repository/projects_repository_impl.dart';
import 'data/repository/settings_repository_impl.dart';
import 'domain/controller/projects_controller.dart';
import 'domain/controller/settings_controller.dart';

Future<SettingsController> createSettingsController() async {
  final prefs = await SharedPreferences.getInstance();
  final datasource = SettingsEnvDatasource(prefs);
  final repository = SettingsRepositoryImpl(datasource);
  return SettingsController(repository);
}

Future<ProjectsController> createProjectsController() async {
  final prefs = await SharedPreferences.getInstance();
  final datasource = ProjectsLocalDatasource(prefs);
  final repository = ProjectsRepositoryImpl(datasource);
  final controller = ProjectsController(repository);
  await controller.load();
  return controller;
}
