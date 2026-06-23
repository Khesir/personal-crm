import '../model/agent_chat_message.dart';
import '../model/agent_event.dart';
import '../model/agent_models_result.dart';
import '../model/agent_session_summary.dart';

abstract class AgentRepository {
  Stream<AgentEvent> chat({
    required String? sessionId,
    required String message,
    String? localPath,
  });

  Future<List<AgentSessionSummary>> listSessions();

  Future<List<AgentChatMessage>> getSessionMessages(String sessionId);

  Future<void> deleteSession(String sessionId);

  Future<AgentModelsResult> listModels();

  Future<Map<String, dynamic>> getConfig();

  Future<void> setConfig(Map<String, dynamic> config);
}
