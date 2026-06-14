import '../../domain/model/chat_message.dart';
import '../../domain/model/chat_stream_event.dart';
import '../../domain/model/tool_definition.dart';
import '../../domain/repository/chat_model_repository.dart';
import '../datasource/anthropic_datasource.dart';

class AnthropicRepositoryImpl implements ChatModelRepository {
  final AnthropicDatasource datasource;

  AnthropicRepositoryImpl(this.datasource);

  @override
  Future<List<String>> listModels() => datasource.listModels();

  @override
  Stream<ChatStreamEvent> streamChat({
    required String model,
    required List<ChatMessage> messages,
    List<ToolDefinition> tools = const [],
  }) {
    return datasource.streamChat(model: model, messages: messages, tools: tools);
  }
}
