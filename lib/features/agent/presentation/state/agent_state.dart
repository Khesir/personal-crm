import '../../domain/model/agent_event.dart';
import '../../domain/model/agent_status.dart';
import '../../domain/model/agent_server_status.dart';
import '../../domain/model/agent_models_result.dart';
import '../../domain/model/agent_session_summary.dart';

const _sentinel = Object();

class AgentStateData {
  final AgentStatus status;
  final AgentServerStatus serverStatus;
  final String? sessionId;
  final String? localPath;
  final String? workingProjectName;
  final List<AgentEvent> events;
  final List<AgentSessionSummary> sessions;
  final bool sessionsLoading;
  final AgentModelsResult? modelsResult;
  final String? selectedModel;
  final bool resumingSession;

  const AgentStateData({
    this.status = AgentStatus.idle,
    this.serverStatus = AgentServerStatus.unknown,
    this.sessionId,
    this.localPath,
    this.workingProjectName,
    this.events = const [],
    this.sessions = const [],
    this.sessionsLoading = false,
    this.modelsResult,
    this.selectedModel,
    this.resumingSession = false,
  });

  AgentStateData copyWith({
    AgentStatus? status,
    AgentServerStatus? serverStatus,
    Object? sessionId = _sentinel,
    Object? localPath = _sentinel,
    Object? workingProjectName = _sentinel,
    List<AgentEvent>? events,
    List<AgentSessionSummary>? sessions,
    bool? sessionsLoading,
    Object? modelsResult = _sentinel,
    Object? selectedModel = _sentinel,
    bool? resumingSession,
  }) =>
      AgentStateData(
        status: status ?? this.status,
        serverStatus: serverStatus ?? this.serverStatus,
        sessionId: sessionId == _sentinel ? this.sessionId : sessionId as String?,
        localPath: localPath == _sentinel ? this.localPath : localPath as String?,
        workingProjectName: workingProjectName == _sentinel
            ? this.workingProjectName
            : workingProjectName as String?,
        events: events ?? this.events,
        sessions: sessions ?? this.sessions,
        sessionsLoading: sessionsLoading ?? this.sessionsLoading,
        modelsResult: modelsResult == _sentinel ? this.modelsResult : modelsResult as AgentModelsResult?,
        selectedModel: selectedModel == _sentinel ? this.selectedModel : selectedModel as String?,
        resumingSession: resumingSession ?? this.resumingSession,
      );
}
