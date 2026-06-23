import '../../domain/model/chat_message.dart';
import '../../domain/model/chat_stream_event.dart';
import '../../domain/model/tool_call_capability_probe.dart';
import '../../domain/model/tool_definition.dart';
import '../../domain/repository/chat_model_repository.dart';
import '../datasource/ollama_datasource.dart';

class OllamaRepositoryImpl implements ChatModelRepository {
  final OllamaDatasource datasource;

  OllamaRepositoryImpl(this.datasource);

  @override
  Future<List<String>> listModels() => datasource.listModels();

  /// Returns whether [model] actually supports tool-calling.
  /// Not part of [ChatModelRepository] — Ollama-specific.
  ///
  /// First checks whether [model] reports the `"tools"` capability via
  /// `/api/show` (cheap pre-filter — if absent, returns `false` without
  /// further requests). If present, sends a live probe request (see
  /// [OllamaDatasource.probeToolCall]) to confirm the model actually emits
  /// structured `tool_calls` rather than describing a call as plain text
  /// (see issue 014) — `/api/show`'s `"tools"` capability can be present even
  /// when a model's chat template never populates `tool_calls`.
  Future<bool> supportsTools(String model) async {
    final capabilities = await datasource.getModelCapabilities(model);
    if (!capabilities.contains('tools')) return false;

    return datasource.probeToolCall(
      model: model,
      tool: kToolCallProbeTool,
      prompt: kToolCallProbePrompt,
      maxTokens: kToolCallProbeMaxTokens,
    );
  }

  @override
  Stream<ChatStreamEvent> streamChat({
    required String model,
    required List<ChatMessage> messages,
    List<ToolDefinition> tools = const [],
  }) {
    return datasource.streamChat(model: model, messages: messages, tools: tools);
  }
}
