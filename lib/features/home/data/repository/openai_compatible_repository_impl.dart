import '../../domain/model/chat_message.dart';
import '../../domain/repository/chat_model_repository.dart';
import '../datasource/openai_compatible_datasource.dart';

class OpenAiCompatibleRepositoryImpl implements ChatModelRepository {
  final OpenAiCompatibleDatasource datasource;

  OpenAiCompatibleRepositoryImpl(this.datasource);

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
