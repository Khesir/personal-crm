import 'package:crm/core/state/stream_state.dart';
import '../model/agent_chat_message.dart';
import '../model/agent_event.dart';
import '../model/agent_server_status.dart';
import '../model/agent_status.dart';
import '../repository/agent_repository.dart';
import '../../presentation/state/agent_state.dart';

class AgentController extends StreamState<AgentStateData> {
  final AgentRepository _repository;

  AgentController(this._repository) : super(const AgentStateData());

  Future<void> sendMessage(String message) async {
    if (state.status == AgentStatus.running) return;

    emit(state.copyWith(status: AgentStatus.running));
    final priorSessionId = state.sessionId;

    try {
      await for (final event in _repository.chat(
        sessionId: state.sessionId,
        message: message,
        localPath: state.localPath,
      )) {
        if (event is AgentDoneEvent) {
          final newSessionId = event.sessionId ?? state.sessionId;
          emit(state.copyWith(
            events: [...state.events, event],
            sessionId: newSessionId,
            status: AgentStatus.done,
          ));
          if (newSessionId != null && newSessionId != priorSessionId) {
            await loadSessions();
          }
          return;
        }
        emit(state.copyWith(events: [...state.events, event]));
      }
    } catch (e) {
      emit(state.copyWith(
        events: [...state.events, AgentErrorEvent(e.toString())],
        status: AgentStatus.error,
      ));
    }
  }

  void setLocalPath(String? path) {
    emit(state.copyWith(localPath: path));
  }

  void setWorkingProject(String? name, String? localPath) {
    emit(state.copyWith(workingProjectName: name, localPath: localPath));
  }

  void setServerStatus(AgentServerStatus status) {
    emit(state.copyWith(serverStatus: status));
  }

  Future<void> loadSessions() async {
    emit(state.copyWith(sessionsLoading: true));
    final sessions = await _repository.listSessions();
    emit(state.copyWith(sessions: sessions, sessionsLoading: false));
  }

  void newChat() {
    emit(state.copyWith(sessionId: null, events: const [], status: AgentStatus.idle));
  }

  Future<void> resumeSession(String sessionId) async {
    emit(state.copyWith(resumingSession: true));
    final messages = await _repository.getSessionMessages(sessionId);
    final events = messages
        .map<AgentEvent>((m) => m.role == AgentChatRole.user
            ? AgentUserMessageEvent(m.content)
            : AgentTextEvent(m.content))
        .toList();
    emit(state.copyWith(
      sessionId: sessionId,
      events: events,
      status: AgentStatus.idle,
      resumingSession: false,
    ));
  }

  Future<void> deleteSession(String sessionId) async {
    await _repository.deleteSession(sessionId);
    emit(state.copyWith(
      sessions: state.sessions.where((s) => s.id != sessionId).toList(),
    ));
    if (state.sessionId == sessionId) newChat();
  }

  Future<void> loadModels() async {
    final result = await _repository.listModels();
    emit(state.copyWith(
      modelsResult: result,
      selectedModel: state.selectedModel ?? (result.models.isEmpty ? null : result.models.first.name),
    ));
  }

  Future<void> selectModel(String modelName) async {
    final config = await _repository.getConfig();
    await _repository.setConfig({...config, 'model': modelName});
    emit(state.copyWith(selectedModel: modelName));
  }

  Future<Map<String, dynamic>> getConfig() => _repository.getConfig();

  Future<void> setConfig(Map<String, dynamic> config) => _repository.setConfig(config);

  void stop() => reset();

  void reset() {
    emit(AgentStateData(
      sessionId: state.sessionId,
      localPath: state.localPath,
    ));
  }
}
