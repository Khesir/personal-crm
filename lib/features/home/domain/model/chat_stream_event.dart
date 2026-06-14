import 'tool_call.dart';

/// An event emitted by [ChatModelRepository.streamChat]'s stream.
sealed class ChatStreamEvent {
  const ChatStreamEvent();
}

/// A chunk of assistant-message text streamed from the model.
class ChatStreamTextDelta extends ChatStreamEvent {
  final String text;

  const ChatStreamTextDelta(this.text);
}

/// The model has requested one or more tool calls for this turn.
class ChatStreamToolCallsRequested extends ChatStreamEvent {
  final List<ToolCall> toolCalls;

  const ChatStreamToolCallsRequested(this.toolCalls);
}
