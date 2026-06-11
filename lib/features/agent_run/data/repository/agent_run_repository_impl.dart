import '../../domain/model/agent_event.dart';
import '../../domain/repository/agent_run_repository.dart';
import '../datasource/agent_run_datasource.dart';

class AgentRunRepositoryImpl implements AgentRunRepository {
  final AgentRunDatasource datasource;

  AgentRunRepositoryImpl(this.datasource);

  @override
  Stream<AgentEvent> run({
    required String skill,
    required String repoPath,
    Map<String, dynamic>? context,
  }) {
    return datasource
        .runSkill(skill: skill, repoPath: repoPath, context: context)
        .map(_toAgentEvent)
        .where((event) => event != null)
        .cast<AgentEvent>();
  }

  AgentEvent? _toAgentEvent(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'thinking':
        return AgentThinking(json['text'] as String? ?? '');
      case 'tool_use':
        return AgentToolUse(
          json['tool'] as String? ?? '',
          _stringifyInput(json['input']),
        );
      case 'tool_result':
        return AgentToolResult(
          json['tool'] as String? ?? '',
          json['output'] as String? ?? '',
        );
      case 'result':
        return AgentResult(
          json['summary'] as String? ?? '',
          json['success'] as bool? ?? false,
        );
      default:
        return null;
    }
  }

  String _stringifyInput(Object? input) {
    if (input == null) return '';
    if (input is String) return input;
    return input.toString();
  }
}
