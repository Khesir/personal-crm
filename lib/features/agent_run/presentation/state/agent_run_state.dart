import '../../domain/model/agent_event.dart';
import '../../domain/model/agent_skill.dart';

enum AgentRunStatus { idle, running, done, error, stopped }

class AgentRunStateData {
  final AgentSkill? skill;
  final String? projectName;
  final String? repoPath;
  final List<AgentEvent> events;
  final AgentRunStatus status;
  final DateTime? startedAt;
  final bool isBackgrounded;

  const AgentRunStateData({
    this.skill,
    this.projectName,
    this.repoPath,
    this.events = const [],
    this.status = AgentRunStatus.idle,
    this.startedAt,
    this.isBackgrounded = false,
  });

  AgentRunStateData copyWith({
    AgentSkill? skill,
    String? projectName,
    String? repoPath,
    List<AgentEvent>? events,
    AgentRunStatus? status,
    DateTime? startedAt,
    bool? isBackgrounded,
  }) {
    return AgentRunStateData(
      skill: skill ?? this.skill,
      projectName: projectName ?? this.projectName,
      repoPath: repoPath ?? this.repoPath,
      events: events ?? this.events,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      isBackgrounded: isBackgrounded ?? this.isBackgrounded,
    );
  }
}
