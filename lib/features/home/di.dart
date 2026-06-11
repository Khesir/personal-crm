import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/datasource/chat_local_datasource.dart';
import 'data/datasource/ollama_datasource.dart';
import 'data/repository/chat_conversations_repository_impl.dart';
import 'data/repository/ollama_repository_impl.dart';
import 'domain/controller/chat_controller.dart';

Dio _buildOllamaDio() {
  final baseUrl = dotenv.env['OLLAMA_BASE_URL'] ?? 'http://localhost:11434';
  return Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    contentType: 'application/json',
  ));
}

ChatController? _chatController;

/// Returns a shared [ChatController] instance so the Home sidebar and
/// content area stay in sync (e.g. selecting a conversation in the
/// sidebar updates the active conversation shown in the content area).
Future<ChatController> createChatController() async {
  final existing = _chatController;
  if (existing != null) return existing;

  final dio = _buildOllamaDio();
  final ollamaRepository = OllamaRepositoryImpl(OllamaDatasource(dio));

  final prefs = await SharedPreferences.getInstance();
  final conversationsRepository =
      ChatConversationsRepositoryImpl(ChatLocalDatasource(prefs));

  final controller = ChatController(ollamaRepository, conversationsRepository);
  await controller.load();
  _chatController = controller;
  return controller;
}
