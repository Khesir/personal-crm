import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/domain/controller/chat_controller.dart';
import 'package:crm/features/home/domain/model/chat_conversation.dart';
import 'package:crm/features/home/domain/model/chat_message.dart';
import 'package:crm/features/home/domain/model/cookbook_entry.dart';
import 'package:crm/features/home/domain/repository/chat_conversations_repository.dart';
import 'package:crm/features/home/domain/repository/chat_model_repository.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';
import 'package:crm/features/settings/domain/repository/service_cards_repository.dart';

class FakeChatModelRepository implements ChatModelRepository {
  List<String> models;
  List<String> chunksToEmit;
  Object? listModelsError;

  FakeChatModelRepository({
    this.models = const ['llama3.2'],
    this.chunksToEmit = const [],
    this.listModelsError,
  });

  @override
  Future<List<String>> listModels() async {
    if (listModelsError != null) throw listModelsError!;
    return models;
  }

  @override
  Stream<String> streamChat({
    required String model,
    required List<ChatMessage> messages,
  }) {
    return Stream.fromIterable(chunksToEmit);
  }
}

class _ManualStreamRepository implements ChatModelRepository {
  final Stream<String> chunks;

  _ManualStreamRepository(this.chunks);

  @override
  Future<List<String>> listModels() async => ['llama3.2'];

  @override
  Stream<String> streamChat({
    required String model,
    required List<ChatMessage> messages,
  }) {
    return chunks;
  }
}

/// A repository whose `streamChat()` returns a stream that emits an error
/// and then closes — mirroring how `AnthropicDatasource.streamChat()`
/// forwards a `DioException` via `controller.addError(...)` followed by
/// `controller.close()` (see anthropic_datasource.dart's catch block).
class _ErroringStreamRepository implements ChatModelRepository {
  final Object error;

  _ErroringStreamRepository(this.error);

  @override
  Future<List<String>> listModels() async => ['claude-3-5-sonnet-20241022'];

  @override
  Stream<String> streamChat({
    required String model,
    required List<ChatMessage> messages,
  }) {
    final controller = StreamController<String>();
    controller.addError(error);
    unawaited(controller.close());
    return controller.stream;
  }
}

class FakeServiceCardsRepository implements ServiceCardsRepository {
  List<ServiceCard> cards;

  FakeServiceCardsRepository(this.cards);

  @override
  Future<List<ServiceCard>> getCards() async => List.unmodifiable(cards);

  @override
  Future<void> saveCards(List<ServiceCard> cards) async {
    this.cards = List.of(cards);
  }
}

class FakeChatConversationsRepository implements ChatConversationsRepository {
  List<ChatConversation> stored;

  FakeChatConversationsRepository([List<ChatConversation>? initial])
      : stored = initial ?? [];

  @override
  Future<List<ChatConversation>> getConversations() async =>
      List.unmodifiable(stored);

  @override
  Future<void> saveConversations(List<ChatConversation> conversations) async {
    stored = List.of(conversations);
  }
}

ServiceCard _ollamaCard({
  String id = 'ollama-1',
  String name = 'Ollama',
  bool enabled = true,
  List<String> disabledModels = const [],
}) {
  return ServiceCard(
    id: id,
    category: ServiceCategory.localLlm,
    type: ServiceType.ollama,
    name: name,
    fields: const {'baseUrl': 'http://localhost:11434'},
    enabled: enabled,
    disabledModels: disabledModels,
  );
}

ServiceCard _customLocalCard({
  String id = 'custom-1',
  String name = 'LM Studio',
  bool enabled = true,
  List<String> disabledModels = const [],
}) {
  return ServiceCard(
    id: id,
    category: ServiceCategory.localLlm,
    type: ServiceType.customLocal,
    name: name,
    fields: const {'baseUrl': 'http://localhost:1234'},
    enabled: enabled,
    disabledModels: disabledModels,
  );
}

ServiceCard _claudeCard({
  String id = 'claude-1',
  String name = 'Claude',
  bool enabled = true,
  List<String> disabledModels = const [],
}) {
  return ServiceCard(
    id: id,
    category: ServiceCategory.apiLlm,
    type: ServiceType.claudeAnthropic,
    name: name,
    fields: const {'apiKey': 'sk-ant-test'},
    enabled: enabled,
    disabledModels: disabledModels,
  );
}

/// Builds a `repositoryFor` function backed by a fixed cardId -> repo map.
ChatModelRepository Function(ServiceCard card) _repositoryFor(
  Map<String, ChatModelRepository> byCardId,
) {
  return (card) => byCardId[card.id] ?? FakeChatModelRepository();
}

void main() {
  group('ChatController', () {
    test('newConversation adds a new conversation to state and selects it', () async {
      final card = _ollamaCard();
      final controller = ChatController(
        FakeServiceCardsRepository([card]),
        _repositoryFor({card.id: FakeChatModelRepository()}),
        FakeChatConversationsRepository(),
      );
      await controller.load();

      controller.newConversation();

      expect(controller.state.conversations, hasLength(1));
      expect(controller.state.activeConversationId, controller.state.conversations.first.id);

      controller.dispose();
    });

    test('load() populates the cookbook from two enabled Local LLM cards', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');
      final custom = _customLocalCard(id: 'custom-1', name: 'LM Studio');

      final controller = ChatController(
        FakeServiceCardsRepository([ollama, custom]),
        _repositoryFor({
          ollama.id: FakeChatModelRepository(models: ['llama3.2', 'qwen2.5']),
          custom.id: FakeChatModelRepository(models: ['mistral-7b']),
        }),
        FakeChatConversationsRepository(),
      );

      await controller.load();

      expect(controller.state.cookbook, [
        const CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'llama3.2',
        ),
        const CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'qwen2.5',
        ),
        const CookbookEntry(
          cardId: 'custom-1',
          cardName: 'LM Studio',
          cardType: ServiceType.customLocal,
          model: 'mistral-7b',
        ),
      ]);
      expect(controller.state.activeEntry, controller.state.cookbook.first);

      controller.dispose();
    });

    test('load() populates the cookbook from an enabled Local LLM card and an enabled API LLM card', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');
      final claude = _claudeCard(id: 'claude-1', name: 'Claude');

      final controller = ChatController(
        FakeServiceCardsRepository([ollama, claude]),
        _repositoryFor({
          ollama.id: FakeChatModelRepository(models: ['llama3.2']),
          claude.id: FakeChatModelRepository(models: ['claude-3-5-sonnet-20241022']),
        }),
        FakeChatConversationsRepository(),
      );

      await controller.load();

      expect(controller.state.cookbook, [
        const CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'llama3.2',
        ),
        const CookbookEntry(
          cardId: 'claude-1',
          cardName: 'Claude',
          cardType: ServiceType.claudeAnthropic,
          model: 'claude-3-5-sonnet-20241022',
        ),
      ]);

      controller.dispose();
    });

    test('a disabled API LLM card contributes zero entries; Local LLM entries still populate', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');
      final claude = _claudeCard(id: 'claude-1', name: 'Claude', enabled: false);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama, claude]),
        _repositoryFor({
          ollama.id: FakeChatModelRepository(models: ['llama3.2']),
          claude.id: FakeChatModelRepository(models: ['should-not-appear']),
        }),
        FakeChatConversationsRepository(),
      );

      await controller.load();

      expect(controller.state.cookbook, [
        const CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'llama3.2',
        ),
      ]);

      controller.dispose();
    });

    test('disabledModels filters models out of the cookbook for an API LLM card', () async {
      final claude = _claudeCard(
        id: 'claude-1',
        name: 'Claude',
        disabledModels: ['claude-3-opus-20240229'],
      );

      final controller = ChatController(
        FakeServiceCardsRepository([claude]),
        _repositoryFor({
          claude.id: FakeChatModelRepository(
            models: ['claude-3-5-sonnet-20241022', 'claude-3-opus-20240229'],
          ),
        }),
        FakeChatConversationsRepository(),
      );

      await controller.load();

      expect(controller.state.cookbook, [
        const CookbookEntry(
          cardId: 'claude-1',
          cardName: 'Claude',
          cardType: ServiceType.claudeAnthropic,
          model: 'claude-3-5-sonnet-20241022',
        ),
      ]);

      controller.dispose();
    });

    test('sendMessage routes to an API LLM card\'s repository when its entry is active', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');
      final claude = _claudeCard(id: 'claude-1', name: 'Claude');

      final ollamaRepo = FakeChatModelRepository(
        models: ['llama3.2'],
        chunksToEmit: ['from-', 'ollama'],
      );
      final claudeRepo = FakeChatModelRepository(
        models: ['claude-3-5-sonnet-20241022'],
        chunksToEmit: ['from-', 'claude'],
      );

      final controller = ChatController(
        FakeServiceCardsRepository([ollama, claude]),
        _repositoryFor({ollama.id: ollamaRepo, claude.id: claudeRepo}),
        FakeChatConversationsRepository(),
      );
      await controller.load();
      controller.newConversation();

      final claudeEntry = controller.state.cookbook.firstWhere((e) => e.cardId == 'claude-1');
      controller.selectEntry(claudeEntry);

      await controller.sendMessage('Hi');

      final messages = controller.state.activeConversation!.messages;
      expect(messages[1].content, 'from-claude');

      controller.dispose();
    });

    test('selectEntry switches the active entry', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');
      final custom = _customLocalCard(id: 'custom-1', name: 'LM Studio');

      final controller = ChatController(
        FakeServiceCardsRepository([ollama, custom]),
        _repositoryFor({
          ollama.id: FakeChatModelRepository(models: ['llama3.2']),
          custom.id: FakeChatModelRepository(models: ['mistral-7b']),
        }),
        FakeChatConversationsRepository(),
      );
      await controller.load();

      final customEntry = controller.state.cookbook.firstWhere((e) => e.cardId == 'custom-1');
      controller.selectEntry(customEntry);

      expect(controller.state.activeEntry, customEntry);

      controller.dispose();
    });

    test('a disabled card and an unreachable card contribute zero entries; the rest still populates', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama'); // enabled, reachable
      final disabled = _customLocalCard(id: 'custom-1', name: 'Disabled LM', enabled: false);
      final unreachable = _customLocalCard(id: 'custom-2', name: 'Unreachable LM');

      final controller = ChatController(
        FakeServiceCardsRepository([ollama, disabled, unreachable]),
        _repositoryFor({
          ollama.id: FakeChatModelRepository(models: ['llama3.2']),
          disabled.id: FakeChatModelRepository(models: ['should-not-appear']),
          unreachable.id: FakeChatModelRepository(listModelsError: Exception('connection refused')),
        }),
        FakeChatConversationsRepository(),
      );

      await controller.load();

      expect(controller.state.cookbook, [
        const CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'llama3.2',
        ),
      ]);

      controller.dispose();
    });

    test('disabledModels filters models out of the cookbook', () async {
      final ollama = _ollamaCard(
        id: 'ollama-1',
        name: 'Ollama',
        disabledModels: ['qwen2.5'],
      );

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({
          ollama.id: FakeChatModelRepository(models: ['llama3.2', 'qwen2.5']),
        }),
        FakeChatConversationsRepository(),
      );

      await controller.load();

      expect(controller.state.cookbook, [
        const CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'llama3.2',
        ),
      ]);

      controller.dispose();
    });

    test('load() keeps the previously active entry if still present after reload', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');
      final custom = _customLocalCard(id: 'custom-1', name: 'LM Studio');

      final cardsRepo = FakeServiceCardsRepository([ollama, custom]);
      final repoFor = _repositoryFor({
        ollama.id: FakeChatModelRepository(models: ['llama3.2']),
        custom.id: FakeChatModelRepository(models: ['mistral-7b']),
      });

      final controller = ChatController(
        cardsRepo,
        repoFor,
        FakeChatConversationsRepository(),
      );
      await controller.load();

      final customEntry = controller.state.cookbook.firstWhere((e) => e.cardId == 'custom-1');
      controller.selectEntry(customEntry);

      // Reload — both cards still present, previous active entry should be kept.
      await controller.load();

      expect(controller.state.activeEntry, customEntry);

      controller.dispose();
    });

    test('load() falls back to the first entry if the previously active entry is gone', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');
      final custom = _customLocalCard(id: 'custom-1', name: 'LM Studio');

      final cards = [ollama, custom];
      final cardsRepo = FakeServiceCardsRepository(cards);
      final repoFor = _repositoryFor({
        ollama.id: FakeChatModelRepository(models: ['llama3.2']),
        custom.id: FakeChatModelRepository(models: ['mistral-7b']),
      });

      final controller = ChatController(
        cardsRepo,
        repoFor,
        FakeChatConversationsRepository(),
      );
      await controller.load();

      final customEntry = controller.state.cookbook.firstWhere((e) => e.cardId == 'custom-1');
      controller.selectEntry(customEntry);

      // Now the custom-1 card is disabled, removing its entries from the cookbook.
      cardsRepo.cards = [ollama, custom.copyWith(enabled: false)];
      await controller.load();

      expect(controller.state.activeEntry, controller.state.cookbook.first);
      expect(controller.state.activeEntry!.cardId, 'ollama-1');

      controller.dispose();
    });

    test('refresh() re-aggregates the cookbook after a card\'s disabledModels change, without reloading conversations', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');

      final cardsRepo = FakeServiceCardsRepository([ollama]);
      final repoFor = _repositoryFor({
        ollama.id: FakeChatModelRepository(models: ['llama3.2', 'qwen2.5']),
      });

      final controller = ChatController(
        cardsRepo,
        repoFor,
        FakeChatConversationsRepository(),
      );
      await controller.load();

      expect(controller.state.cookbook, [
        const CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'llama3.2',
        ),
        const CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'qwen2.5',
        ),
      ]);

      // Simulate Settings disabling 'qwen2.5' on the Ollama card's checklist.
      cardsRepo.cards = [ollama.copyWith(disabledModels: ['qwen2.5'])];

      // Without calling refresh(), the cookbook stays stale.
      expect(controller.state.cookbook, hasLength(2));

      // refresh() re-aggregates against the now-updated card, without
      // re-constructing the controller.
      await controller.refresh();

      expect(controller.state.cookbook, [
        const CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'llama3.2',
        ),
      ]);

      controller.dispose();
    });

    test('load() leaves activeEntry null if the cookbook ends up empty', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');
      final cardsRepo = FakeServiceCardsRepository([ollama]);
      final repoFor = _repositoryFor({
        ollama.id: FakeChatModelRepository(models: ['llama3.2']),
      });

      final controller = ChatController(
        cardsRepo,
        repoFor,
        FakeChatConversationsRepository(),
      );
      await controller.load();
      expect(controller.state.activeEntry, isNotNull);

      // Disable the only card; cookbook becomes empty.
      cardsRepo.cards = [ollama.copyWith(enabled: false)];
      await controller.load();

      expect(controller.state.cookbook, isEmpty);
      expect(controller.state.activeEntry, isNull);

      controller.dispose();
    });

    test('sendMessage routes to the active entry\'s card repository', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');
      final custom = _customLocalCard(id: 'custom-1', name: 'LM Studio');

      final ollamaRepo = FakeChatModelRepository(
        models: ['llama3.2'],
        chunksToEmit: ['from-', 'ollama'],
      );
      final customRepo = FakeChatModelRepository(
        models: ['mistral-7b'],
        chunksToEmit: ['from-', 'custom'],
      );

      final controller = ChatController(
        FakeServiceCardsRepository([ollama, custom]),
        _repositoryFor({ollama.id: ollamaRepo, custom.id: customRepo}),
        FakeChatConversationsRepository(),
      );
      await controller.load();
      controller.newConversation();

      // Default active entry is the first one (ollama).
      await controller.sendMessage('Hi');

      var messages = controller.state.activeConversation!.messages;
      expect(messages[1].content, 'from-ollama');

      // Switch to the custom-local entry and send another message.
      final customEntry = controller.state.cookbook.firstWhere((e) => e.cardId == 'custom-1');
      controller.selectEntry(customEntry);

      await controller.sendMessage('Hi again');

      messages = controller.state.activeConversation!.messages;
      expect(messages[3].content, 'from-custom');

      controller.dispose();
    });

    test('sendMessage streams tokens and accumulates them into the assistant message', () async {
      final ollama = _ollamaCard();
      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({
          ollama.id: FakeChatModelRepository(chunksToEmit: ['Hel', 'lo', ' world']),
        }),
        FakeChatConversationsRepository(),
      );
      await controller.load();
      controller.newConversation();

      await controller.sendMessage('Hi there');

      final messages = controller.state.activeConversation!.messages;
      expect(messages, hasLength(2));
      expect(messages[0].role, ChatRole.user);
      expect(messages[0].content, 'Hi there');
      expect(messages[1].role, ChatRole.assistant);
      expect(messages[1].content, 'Hello world');
      expect(messages[1].streaming, isFalse);
      expect(controller.state.isStreaming, isFalse);

      controller.dispose();
    });

    test('sendMessage marks the assistant message as streaming while tokens arrive', () async {
      final ollama = _ollamaCard();
      final chunkController = StreamController<String>();
      final conversationsRepo = FakeChatConversationsRepository();

      final streamingController = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: _ManualStreamRepository(chunkController.stream)}),
        conversationsRepo,
      );
      await streamingController.load();
      streamingController.newConversation();

      final future = streamingController.sendMessage('Hi');
      await Future<void>.delayed(Duration.zero);

      expect(streamingController.state.isStreaming, isTrue);
      final messages = streamingController.state.activeConversation!.messages;
      expect(messages.last.streaming, isTrue);

      chunkController.add('partial');
      await chunkController.close();
      await future;

      expect(streamingController.state.isStreaming, isFalse);
      streamingController.dispose();
    });

    test('sendMessage surfaces a stream error from the repository as an error message instead of crashing', () async {
      final claude = _claudeCard();
      final controller = ChatController(
        FakeServiceCardsRepository([claude]),
        _repositoryFor({
          claude.id: _ErroringStreamRepository(
            Exception('DioException [bad response]: status code 400'),
          ),
        }),
        FakeChatConversationsRepository(),
      );
      await controller.load();
      controller.newConversation();

      // Must not throw / leave an unhandled Future rejection.
      await controller.sendMessage('Hi');

      final messages = controller.state.activeConversation!.messages;
      expect(messages, hasLength(2));
      expect(messages[1].role, ChatRole.assistant);
      expect(messages[1].content, isNotEmpty);
      expect(messages[1].streaming, isFalse);
      expect(controller.state.isStreaming, isFalse);

      controller.dispose();
    });

    test('sendMessage includes the provider\'s error message when the repository surfaces a ChatRequestException', () async {
      final claude = _claudeCard();
      final controller = ChatController(
        FakeServiceCardsRepository([claude]),
        _repositoryFor({
          claude.id: _ErroringStreamRepository(
            const ChatRequestException(
              'Your credit balance is too low to access the Anthropic API. Please go to Plans & Billing to upgrade or purchase credits.',
            ),
          ),
        }),
        FakeChatConversationsRepository(),
      );
      await controller.load();
      controller.newConversation();

      await controller.sendMessage('Hi');

      final messages = controller.state.activeConversation!.messages;
      expect(messages[1].content, contains('Your credit balance is too low'));

      controller.dispose();
    });

    test('persistence round trip via the fake repository', () async {
      final ollama = _ollamaCard();
      final conversationsRepo = FakeChatConversationsRepository();

      final firstController = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: FakeChatModelRepository()}),
        conversationsRepo,
      );
      await firstController.load();
      firstController.newConversation();
      firstController.dispose();

      final secondController = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: FakeChatModelRepository()}),
        conversationsRepo,
      );
      await secondController.load();

      expect(secondController.state.conversations, hasLength(1));
      expect(
        secondController.state.conversations.first.id,
        firstController.state.conversations.first.id,
      );

      secondController.dispose();
    });

    test('sendMessage persists the conversation with the final assistant message', () async {
      final ollama = _ollamaCard();
      final conversationsRepo = FakeChatConversationsRepository();

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: FakeChatModelRepository(chunksToEmit: ['Hello'])}),
        conversationsRepo,
      );
      await controller.load();
      controller.newConversation();

      await controller.sendMessage('Hi');

      final reloaded = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: FakeChatModelRepository()}),
        conversationsRepo,
      );
      await reloaded.load();

      final messages = reloaded.state.conversations.first.messages;
      expect(messages, hasLength(2));
      expect(messages[1].content, 'Hello');
      expect(messages[1].streaming, isFalse);

      controller.dispose();
      reloaded.dispose();
    });
  });
}
