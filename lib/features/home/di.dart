import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm/features/settings/data/datasource/service_cards_local_datasource.dart';
import 'package:crm/features/settings/data/repository/service_cards_repository_impl.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';
import 'data/datasource/anthropic_datasource.dart';
import 'data/datasource/chat_local_datasource.dart';
import 'data/datasource/ollama_datasource.dart';
import 'data/datasource/openai_compatible_datasource.dart';
import 'data/repository/anthropic_repository_impl.dart';
import 'data/repository/chat_conversations_repository_impl.dart';
import 'data/repository/ollama_repository_impl.dart';
import 'data/repository/openai_compatible_repository_impl.dart';
import 'domain/controller/chat_controller.dart';
import 'domain/repository/chat_model_repository.dart';

ChatModelRepository _repositoryFor(ServiceCard card) {
  final baseDio = Dio(BaseOptions(
    baseUrl: card.fields['baseUrl'] ?? '',
    connectTimeout: const Duration(seconds: 10),
    contentType: 'application/json',
  ));
  return switch (card.type) {
    ServiceType.ollama => OllamaRepositoryImpl(OllamaDatasource(baseDio)),
    ServiceType.customLocal => OpenAiCompatibleRepositoryImpl(OpenAiCompatibleDatasource(baseDio)),
    ServiceType.customApi => OpenAiCompatibleRepositoryImpl(OpenAiCompatibleDatasource(Dio(BaseOptions(
        baseUrl: card.fields['baseUrl'] ?? '',
        connectTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
        headers: {'Authorization': 'Bearer ${card.fields['apiKey'] ?? ''}'},
      )))),
    ServiceType.claudeAnthropic => AnthropicRepositoryImpl(AnthropicDatasource(Dio(BaseOptions(
        baseUrl: 'https://api.anthropic.com',
        connectTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
        headers: {
          'x-api-key': card.fields['apiKey'] ?? '',
          'anthropic-version': '2023-06-01',
        },
      )))),
    _ => throw ArgumentError('${card.type} is not a chat-capable type'),
  };
}

ChatController? _chatController;
Future<ChatController>? _chatControllerCreation;

/// Returns a shared [ChatController] instance so the Home sidebar and
/// content area stay in sync (e.g. selecting a conversation in the
/// sidebar updates the active conversation shown in the content area).
///
/// On every call after the first, re-aggregates the cookbook from the
/// current Local LLM service cards (without reloading conversations) so
/// that Settings changes — toggling a model, or
/// enabling/disabling/adding/removing a Local LLM card — are reflected the
/// next time Home becomes visible, without requiring an app restart.
///
/// `_HomePlaceholder` and `_HomeSidebar` both call this in the same frame
/// (e.g. on first navigation to Home). Without coordination, both calls
/// would see `_chatController == null` and each construct its own
/// [ChatController] — leaving the sidebar and content area on divergent
/// instances, only one of which becomes the singleton. The in-flight
/// [_chatControllerCreation] future ensures only one instance is ever
/// created and every caller awaits (and receives) that same instance.
Future<ChatController> createChatController() async {
  final existing = _chatController;
  if (existing != null) {
    await existing.refresh();
    return existing;
  }

  final inFlight = _chatControllerCreation;
  if (inFlight != null) {
    final controller = await inFlight;
    await controller.refresh();
    return controller;
  }

  final creation = _createChatController();
  _chatControllerCreation = creation;
  try {
    return await creation;
  } finally {
    _chatControllerCreation = null;
  }
}

Future<ChatController> _createChatController() async {
  final prefs = await SharedPreferences.getInstance();
  final serviceCardsRepository = ServiceCardsRepositoryImpl(ServiceCardsLocalDatasource(prefs));
  final conversationsRepository = ChatConversationsRepositoryImpl(ChatLocalDatasource(prefs));

  final controller = ChatController(serviceCardsRepository, _repositoryFor, conversationsRepository);
  await controller.load();
  _chatController = controller;
  return controller;
}
