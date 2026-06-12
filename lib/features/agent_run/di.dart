import 'package:dio/dio.dart';
import 'package:crm/core/di/di.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';
import 'package:crm/features/settings/domain/model/service_cards_cache.dart';
import 'data/datasource/agent_run_datasource.dart';
import 'data/repository/agent_run_repository_impl.dart';
import 'domain/controller/agent_run_controller.dart';

Dio _buildN8nDio() {
  final baseUrl = ServiceCardsCache.instance.field(ServiceType.n8n, 'baseUrl');
  return Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    contentType: 'application/json',
  ));
}

AgentRunController createAgentRunController() {
  final dio = _buildN8nDio();
  final datasource = AgentRunDatasource(dio);
  final repository = AgentRunRepositoryImpl(datasource);
  return AgentRunController(repository);
}

/// Returns the currently backgrounded/foregrounded [AgentRunController], if
/// any agent run is in progress and registered with the global locator.
AgentRunController? getActiveAgentRunController() {
  if (!locator.isRegistered<AgentRunController>()) return null;
  return locator.get<AgentRunController>();
}

/// Registers [controller] with the global locator so it survives the
/// overlay being dismissed ("Run in background").
void registerActiveAgentRunController(AgentRunController controller) {
  if (locator.isRegistered<AgentRunController>()) {
    locator.unregister<AgentRunController>();
  }
  locator.registerSingleton<AgentRunController>(controller);
}

/// Removes the active [AgentRunController] from the global locator once the
/// run is finished and the overlay is closed for good.
void clearActiveAgentRunController() {
  if (locator.isRegistered<AgentRunController>()) {
    locator.unregister<AgentRunController>();
  }
}
