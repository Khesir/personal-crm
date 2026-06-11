import '../model/agent_event.dart';

abstract class AgentRunRepository {
  Stream<AgentEvent> run({
    required String skill,
    required String repoPath,
    Map<String, dynamic>? context,
  });
}
