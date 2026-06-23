import 'package:crm/core/di/service_locator.dart';
import 'data/datasource/agent_datasource.dart';
import 'data/repository/agent_repository_impl.dart';
import 'domain/controller/agent_controller.dart';
import 'domain/service/agent_server_manager.dart';

void registerAgentDependencies() {
  final datasource = AgentDatasource();
  final repository = AgentRepositoryImpl(datasource);
  locator.registerSingleton<AgentController>(AgentController(repository));
  locator.registerSingleton<AgentServerManager>(AgentServerManager());
}
