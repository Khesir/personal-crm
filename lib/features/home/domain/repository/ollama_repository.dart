import '../model/chat_message.dart';

abstract class OllamaRepository {
  Future<List<String>> listModels();

  Stream<String> streamChat({
    required String model,
    required List<ChatMessage> messages,
  });
}
