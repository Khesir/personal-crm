import '../../domain/model/chat_message.dart';
import '../../domain/repository/chat_model_repository.dart';
import '../datasource/ollama_datasource.dart';

class OllamaRepositoryImpl implements ChatModelRepository {
  final OllamaDatasource datasource;

  OllamaRepositoryImpl(this.datasource);

  @override
  Future<List<String>> listModels() => datasource.listModels();

  @override
  Stream<String> streamChat({
    required String model,
    required List<ChatMessage> messages,
  }) {
    return datasource.streamChat(model: model, messages: messages);
  }
}
