import '../model/chat_message.dart';
import '../model/chat_stream_event.dart';
import '../model/tool_definition.dart';

/// Contract satisfied by any chat-capable backend — Local LLM servers
/// (Ollama, OpenAI-compatible custom local servers) and API LLM providers
/// (Claude Anthropic, OpenAI-compatible custom APIs) — that can list its
/// available models and stream chat completions.
abstract class ChatModelRepository {
  Future<List<String>> listModels();

  Stream<ChatStreamEvent> streamChat({
    required String model,
    required List<ChatMessage> messages,
    List<ToolDefinition> tools = const [],
  });
}

/// A [streamChat] failure whose [message] was extracted from the
/// provider's own error response (e.g. "Your credit balance is too low" or
/// "invalid x-api-key") and is safe to show to the user as-is.
class ChatRequestException implements Exception {
  final String message;

  const ChatRequestException(this.message);

  @override
  String toString() => message;
}
