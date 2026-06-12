import 'package:shared_preferences/shared_preferences.dart';
import 'data/datasource/projects_local_datasource.dart';
import 'data/datasource/service_cards_local_datasource.dart';
import 'data/repository/health_check_repository_impl.dart';
import 'data/repository/projects_repository_impl.dart';
import 'data/repository/service_cards_repository_impl.dart';
import 'domain/controller/projects_controller.dart';
import 'domain/controller/service_cards_controller.dart';
import 'domain/model/service_cards_cache.dart';

Future<ProjectsController> createProjectsController() async {
  final prefs = await SharedPreferences.getInstance();
  final datasource = ProjectsLocalDatasource(prefs);
  final repository = ProjectsRepositoryImpl(datasource);
  final controller = ProjectsController(repository);
  await controller.load();
  return controller;
}

Future<ServiceCardsController> createServiceCardsController() async {
  final prefs = await SharedPreferences.getInstance();
  final datasource = ServiceCardsLocalDatasource(prefs);
  final repository = ServiceCardsRepositoryImpl(datasource);
  final healthCheckRepository = HealthCheckRepositoryImpl();
  final controller = ServiceCardsController(repository, healthCheckRepository);
  await controller.load();
  return controller;
}

/// Loads the persisted service-card list into [ServiceCardsCache] so
/// synchronous DI factories can read configured base URLs/secrets at
/// startup. If no cards have been configured yet, the cache falls back to
/// [kServiceTypeDefaults].
///
/// Must be called once during app startup, after [SharedPreferences] is
/// ready and before any DI factory that reads [ServiceCardsCache.instance].
Future<void> initServiceCardsCache(SharedPreferences prefs) async {
  final repository = ServiceCardsRepositoryImpl(ServiceCardsLocalDatasource(prefs));
  final cards = await repository.getCards();
  ServiceCardsCache.instance.load(cards);
}
