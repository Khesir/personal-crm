import '../../domain/model/agent_chat_message.dart';
import '../../domain/model/agent_event.dart';
import '../../domain/model/agent_models_result.dart';
import '../../domain/model/agent_session_summary.dart';
import '../../domain/repository/agent_repository.dart';
import '../datasource/agent_datasource.dart';

class AgentRepositoryImpl extends AgentRepository {
  final AgentDatasource _datasource;

  AgentRepositoryImpl(this._datasource);

  @override
  Stream<AgentEvent> chat({
    required String? sessionId,
    required String message,
    String? localPath,
  }) =>
      _datasource.streamChat(
        sessionId: sessionId,
        message: message,
        localPath: localPath,
      );

  @override
  Future<List<AgentSessionSummary>> listSessions() async {
    final raw = await _datasource.listSessions();
    return raw
        .map((s) => AgentSessionSummary(
              id: s['id'] as String,
              title: s['title'] as String,
              createdAt: DateTime.parse(s['created_at'] as String),
              updatedAt: DateTime.parse(s['updated_at'] as String),
            ))
        .toList();
  }

  @override
  Future<List<AgentChatMessage>> getSessionMessages(String sessionId) async {
    final raw = await _datasource.getSessionMessages(sessionId);
    return raw
        .map((m) => AgentChatMessage(
              role: m['role'] == 'user' ? AgentChatRole.user : AgentChatRole.assistant,
              content: m['content'] as String,
            ))
        .toList();
  }

  @override
  Future<void> deleteSession(String sessionId) => _datasource.deleteSession(sessionId);

  @override
  Future<AgentModelsResult> listModels() async {
    final raw = await _datasource.listModels();
    final models = (raw['models'] as List)
        .cast<Map<String, dynamic>>()
        .map((m) => AgentModelInfo(
              name: m['name'] as String? ?? '',
              parameterSize: m['parameter_size'] as String? ?? '',
            ))
        .toList();
    return AgentModelsResult(provider: raw['provider'] as String, models: models);
  }

  @override
  Future<Map<String, dynamic>> getConfig() => _datasource.getConfig();

  @override
  Future<void> setConfig(Map<String, dynamic> config) => _datasource.setConfig(config);
}
