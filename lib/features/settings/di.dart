import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/datasource/huggingface_datasource.dart';
import 'data/datasource/project_metadata_datasource.dart';
import 'data/datasource/projects_local_datasource.dart';
import 'data/datasource/service_cards_local_datasource.dart';
import 'data/repository/health_check_repository_impl.dart';
import 'data/repository/hardware_info_repository_impl.dart';
import 'data/repository/io_process_runner.dart';
import 'data/repository/project_metadata_repository_impl.dart';
import 'data/repository/projects_repository_impl.dart';
import 'data/repository/service_cards_repository_impl.dart';
import 'domain/controller/model_discovery_controller.dart';
import 'domain/controller/projects_controller.dart';
import 'domain/controller/service_cards_controller.dart';
import 'domain/model/service_card.dart';
import 'domain/model/service_cards_cache.dart';
import 'domain/repository/process_runner.dart';

ProcessRunner createProcessRunner() => IoProcessRunner();

Future<ProjectsController> createProjectsController() async {
  final prefs = await SharedPreferences.getInstance();
  final datasource = ProjectsLocalDatasource(prefs);
  final repository = ProjectsRepositoryImpl(datasource);
  final metadataRepository = ProjectMetadataRepositoryImpl(const ProjectMetadataDatasource());
  final controller = ProjectsController(repository, metadataRepository);
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

/// Builds a [ModelDiscoveryController] for the "Search Hugging Face" dialog.
///
/// Unlike the `Future<...>` factories above, this is synchronous (no
/// [SharedPreferences] dependency) — [ModelDiscoveryController.load] runs in
/// the background and the dialog shows the loading state via
/// `AsyncStreamBuilder`.
///
/// [cards] is the already-loaded service card list (from the
/// [ServiceCardsController] backing the Settings > Services screen that's
/// opening this dialog) — used to resolve which Ollama card [download]
/// should target.
ModelDiscoveryController createModelDiscoveryController(List<ServiceCard> cards) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://huggingface.co',
    connectTimeout: const Duration(seconds: 10),
  ));
  final datasource = HuggingFaceDatasource(dio);
  final hardwareRepository = HardwareInfoRepositoryImpl(IoProcessRunner());
  final ollamaCards = cards.where((c) => c.type == ServiceType.ollama).toList();
  final controller = ModelDiscoveryController(datasource, hardwareRepository, ollamaCards: ollamaCards);
  controller.load();
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
