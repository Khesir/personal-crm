sealed class AgentEvent {
  const AgentEvent();
}

class AgentThinking extends AgentEvent {
  final String text;

  const AgentThinking(this.text);
}

class AgentToolUse extends AgentEvent {
  final String tool;
  final String input;

  const AgentToolUse(this.tool, this.input);
}

class AgentToolResult extends AgentEvent {
  final String tool;
  final String output;

  const AgentToolResult(this.tool, this.output);
}

class AgentResult extends AgentEvent {
  final String summary;
  final bool success;

  const AgentResult(this.summary, this.success);
}
