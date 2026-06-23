sealed class AgentEvent {
  const AgentEvent();
}

class AgentTextEvent extends AgentEvent {
  final String text;
  const AgentTextEvent(this.text);
}

class AgentUserMessageEvent extends AgentEvent {
  final String text;
  const AgentUserMessageEvent(this.text);
}

class AgentThinkingEvent extends AgentEvent {
  final String text;
  const AgentThinkingEvent(this.text);
}

class AgentToolCallEvent extends AgentEvent {
  final String tool;
  final Map<String, dynamic> input;
  const AgentToolCallEvent(this.tool, this.input);
}

class AgentToolResultEvent extends AgentEvent {
  final String tool;
  final String output;
  const AgentToolResultEvent(this.tool, this.output);
}

class AgentDoneEvent extends AgentEvent {
  final String? sessionId;
  final bool success;
  const AgentDoneEvent({this.sessionId, required this.success});
}

class AgentErrorEvent extends AgentEvent {
  final String message;
  const AgentErrorEvent(this.message);
}
