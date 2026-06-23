enum AgentChatRole { user, assistant }

class AgentChatMessage {
  final AgentChatRole role;
  final String content;

  const AgentChatMessage({required this.role, required this.content});
}
