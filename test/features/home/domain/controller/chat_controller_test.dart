import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/brain/api.dart';
import 'package:crm/features/home/data/datasource/ollama_datasource.dart';
import 'package:crm/features/home/data/repository/ollama_repository_impl.dart';
import 'package:crm/features/home/domain/controller/chat_controller.dart';
import 'package:crm/features/home/domain/model/agent_loop_constants.dart';
import 'package:crm/features/home/domain/model/agent_tools.dart';
import 'package:crm/features/home/domain/model/chat_conversation.dart';
import 'package:crm/features/home/domain/model/chat_message.dart';
import 'package:crm/features/home/domain/model/chat_stream_event.dart';
import 'package:crm/features/home/domain/model/cookbook_entry.dart';
import 'package:crm/features/home/domain/model/tool_call.dart';
import 'package:crm/features/home/domain/model/tool_definition.dart';
import 'package:crm/features/home/domain/model/tool_execution_result.dart';
import 'package:crm/features/home/domain/repository/agent_tool_repository.dart';
import 'package:crm/features/home/domain/repository/command_execution_repository.dart';
import 'package:crm/features/home/domain/repository/chat_conversations_repository.dart';
import 'package:crm/features/home/domain/repository/chat_model_repository.dart';
import 'package:crm/features/home/domain/repository/fetch_page_repository.dart';
import 'package:crm/features/home/domain/repository/web_search_repository.dart';
import 'package:crm/features/settings/domain/model/fit_scorer.dart';
import 'package:crm/features/settings/domain/model/hardware_info.dart';
import 'package:crm/features/settings/domain/model/project.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';
import 'package:crm/features/settings/domain/repository/hardware_info_repository.dart';
import 'package:crm/features/settings/domain/repository/projects_repository.dart';
import 'package:crm/features/settings/domain/repository/service_cards_repository.dart';

/// A minimal [HttpClientAdapter] that returns a canned [ResponseBody] for
/// every request, computed by [handler]. Used to back a real
/// [OllamaRepositoryImpl] for `supportsTools`/`/api/show` mapping tests.
class _FakeOllamaAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;

  _FakeOllamaAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

OllamaRepositoryImpl _ollamaRepoWith(ResponseBody Function(RequestOptions options) handler) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:11434'));
  dio.httpClientAdapter = _FakeOllamaAdapter(handler);
  return OllamaRepositoryImpl(OllamaDatasource(dio));
}

class FakeChatModelRepository implements ChatModelRepository {
  List<String> models;
  List<String> chunksToEmit;
  Object? listModelsError;
  List<ChatMessage>? lastMessages;
  List<List<ToolDefinition>> toolsPerCall = [];

  /// When non-null, each `streamChat()` call consumes the next sequence of
  /// [ChatStreamEvent]s from this queue (instead of [chunksToEmit]). Lets
  /// tests script tool-call-requested events across multiple loop
  /// iterations.
  List<List<ChatStreamEvent>>? scriptedTurns;
  int _turnIndex = 0;

  FakeChatModelRepository({
    this.models = const ['llama3.2'],
    this.chunksToEmit = const [],
    this.listModelsError,
    this.scriptedTurns,
  });

  @override
  Future<List<String>> listModels() async {
    if (listModelsError != null) throw listModelsError!;
    return models;
  }

  @override
  Stream<ChatStreamEvent> streamChat({
    required String model,
    required List<ChatMessage> messages,
    List<ToolDefinition> tools = const [],
  }) {
    lastMessages = messages;
    toolsPerCall.add(tools);

    final scripted = scriptedTurns;
    if (scripted != null) {
      final events = _turnIndex < scripted.length ? scripted[_turnIndex] : const <ChatStreamEvent>[];
      _turnIndex++;
      return Stream.fromIterable(events);
    }

    return Stream.fromIterable(chunksToEmit.map(ChatStreamTextDelta.new));
  }
}

/// A scriptable [AgentToolRepository] for agent-loop tests: each `execute()`
/// call consumes the next result from [resultsByCallId]'s queue for that
/// call's `id` (falling back to [defaultResult]).
class FakeAgentToolRepository implements AgentToolRepository {
  final Map<String, List<ToolExecutionResult>> resultsByCallId;
  final ToolExecutionResult Function(ToolWriteProposal proposal)? applyWriteResult;
  final List<ToolCall> executedCalls = [];
  final List<ToolWriteProposal> appliedWrites = [];

  FakeAgentToolRepository({
    this.resultsByCallId = const {},
    this.applyWriteResult,
  });

  @override
  Future<ToolExecutionResult> execute(
    ToolCall call, {
    required String workingProjectPath,
    required List<String> trustedReferenceProjectPaths,
    required Map<String, String> registeredProjectPaths,
  }) async {
    executedCalls.add(call);
    final queue = resultsByCallId[call.id];
    if (queue == null || queue.isEmpty) {
      return const ToolOutput('ok');
    }
    return queue.length == 1 ? queue.first : queue.removeAt(0);
  }

  @override
  Future<ToolExecutionResult> applyWrite(ToolWriteProposal proposal) async {
    appliedWrites.add(proposal);
    final result = applyWriteResult;
    if (result != null) return result(proposal);
    return ToolOutput('Wrote to ${proposal.path}');
  }
}

/// A scriptable [WebSearchRepository] for agent-loop tests: each `search()`
/// call records its [query]/[count] and returns [result].
class FakeWebSearchRepository implements WebSearchRepository {
  final ToolExecutionResult result;
  final List<String> queries = [];
  final List<int?> counts = [];

  FakeWebSearchRepository(this.result);

  @override
  Future<ToolExecutionResult> search(String query, {int? count}) async {
    queries.add(query);
    counts.add(count);
    return result;
  }
}

/// A scriptable [FetchPageRepository] for agent-loop tests: each `fetch()`
/// call records its [url] and returns [result].
class FakeFetchPageRepository implements FetchPageRepository {
  final ToolExecutionResult result;
  final List<String> urls = [];

  FakeFetchPageRepository(this.result);

  @override
  Future<ToolExecutionResult> fetch(String url) async {
    urls.add(url);
    return result;
  }
}

/// A scriptable [CommandExecutionRepository] for agent-loop tests: each
/// `run()` call records its [command]/[workingDirectory] and returns
/// [result].
class FakeCommandExecutionRepository implements CommandExecutionRepository {
  final ToolExecutionResult result;
  final List<String> commands = [];
  final List<String> workingDirectories = [];

  FakeCommandExecutionRepository(this.result);

  @override
  Future<ToolExecutionResult> run(String command, {required String workingDirectory}) async {
    commands.add(command);
    workingDirectories.add(workingDirectory);
    return result;
  }
}

class FakeProjectsRepository implements ProjectsRepository {
  List<Project> projects;

  FakeProjectsRepository(this.projects);

  @override
  Future<List<Project>> getProjects() async => List.unmodifiable(projects);

  @override
  Future<void> saveProjects(List<Project> projects) async {
    this.projects = List.of(projects);
  }
}

Project _project({
  required String id,
  required String name,
  required String localPath,
}) {
  return Project(
    id: id,
    name: name,
    localPath: localPath,
    projectKey: id,
    hasBugReports: false,
    hasAnnouncements: false,
  );
}

class FakeBrainRepository implements BrainRepository {
  String? prompt;

  FakeBrainRepository({this.prompt});

  @override
  Future<String?> buildSystemPrompt() async => prompt;
}

class _ManualStreamRepository implements ChatModelRepository {
  final Stream<String> chunks;

  _ManualStreamRepository(this.chunks);

  @override
  Future<List<String>> listModels() async => ['llama3.2'];

  @override
  Stream<ChatStreamEvent> streamChat({
    required String model,
    required List<ChatMessage> messages,
    List<ToolDefinition> tools = const [],
  }) {
    return chunks.map(ChatStreamTextDelta.new);
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
  Stream<ChatStreamEvent> streamChat({
    required String model,
    required List<ChatMessage> messages,
    List<ToolDefinition> tools = const [],
  }) {
    final controller = StreamController<ChatStreamEvent>();
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

class FakeHardwareInfoRepository implements HardwareInfoRepository {
  final HardwareInfo hardware;

  FakeHardwareInfoRepository(this.hardware);

  @override
  Future<HardwareInfo> detect() async => hardware;
}

const _testHardware = HardwareInfo(
  gpuName: 'NVIDIA GeForce RTX 4090',
  vramTotalMb: 24576,
  vramAvailableMb: 20000,
  cudaAvailable: true,
  ramTotalMb: 65536,
  ramAvailableMb: 32000,
  cpuCores: 16,
);

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
        FakeBrainRepository(),
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
        FakeBrainRepository(),
      );

      await controller.load();

      expect(controller.state.cookbook, [
        const CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'llama3.2',
          supportsTools: false,
        ),
        const CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'qwen2.5',
          supportsTools: false,
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
        FakeBrainRepository(),
      );

      await controller.load();

      expect(controller.state.cookbook, [
        const CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'llama3.2',
          supportsTools: false,
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

    test('load() computes fitResult for a Local LLM model with a parseable name and quant', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({
          ollama.id: FakeChatModelRepository(models: ['llama-2-7b-chat.Q4_K_M']),
        }),
        FakeChatConversationsRepository(),
        FakeBrainRepository(),
        hardwareInfoRepository: FakeHardwareInfoRepository(_testHardware),
      );

      await controller.load();

      final expectedFit = FitScorer.score(
        hardware: _testHardware,
        paramsBillions: 7,
        quant: 'Q4_K_M',
      );

      expect(controller.state.cookbook, [
        CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'llama-2-7b-chat.Q4_K_M',
          supportsTools: false,
          fitResult: expectedFit,
        ),
      ]);

      controller.dispose();
    });

    test('load() leaves fitResult null for a Local LLM model whose name does not parse', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({
          ollama.id: FakeChatModelRepository(models: ['llama3.2']),
        }),
        FakeChatConversationsRepository(),
        FakeBrainRepository(),
        hardwareInfoRepository: FakeHardwareInfoRepository(_testHardware),
      );

      await controller.load();

      expect(controller.state.cookbook.single.fitResult, isNull);

      controller.dispose();
    });

    test('load() leaves fitResult null for an API LLM model even with a parseable name', () async {
      final claude = _claudeCard(id: 'claude-1', name: 'Claude');

      final controller = ChatController(
        FakeServiceCardsRepository([claude]),
        _repositoryFor({
          claude.id: FakeChatModelRepository(models: ['claude-7b.Q4_K_M']),
        }),
        FakeChatConversationsRepository(),
        FakeBrainRepository(),
        hardwareInfoRepository: FakeHardwareInfoRepository(_testHardware),
      );

      await controller.load();

      expect(controller.state.cookbook.single.fitResult, isNull);

      controller.dispose();
    });

    test('load() leaves fitResult null when no hardwareInfoRepository is configured', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({
          ollama.id: FakeChatModelRepository(models: ['llama-2-7b-chat.Q4_K_M']),
        }),
        FakeChatConversationsRepository(),
        FakeBrainRepository(),
      );

      await controller.load();

      expect(controller.state.cookbook.single.fitResult, isNull);

      controller.dispose();
    });

    test('load() defaults activeEntry to the local entry with the highest fitResult.score, '
        'not the first cookbook entry', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({
          // Listed first, but a 70b model is too big for the test hardware
          // (low fitResult.score) — the 7b model that follows fits
          // perfectly and should be preferred instead.
          ollama.id: FakeChatModelRepository(
            models: ['llama-2-70b-chat.Q4_K_M', 'llama-2-7b-chat.Q4_K_M'],
          ),
        }),
        FakeChatConversationsRepository(),
        FakeBrainRepository(),
        hardwareInfoRepository: FakeHardwareInfoRepository(_testHardware),
      );

      await controller.load();

      final recommended = controller.state.cookbook
          .firstWhere((e) => e.model == 'llama-2-7b-chat.Q4_K_M');
      expect(controller.state.activeEntry, recommended);
      expect(controller.state.activeEntry, isNot(controller.state.cookbook.first));

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
        FakeBrainRepository(),
      );

      await controller.load();

      expect(controller.state.cookbook, [
        const CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'llama3.2',
          supportsTools: false,
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
        FakeBrainRepository(),
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
        FakeBrainRepository(),
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
        FakeBrainRepository(),
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
        FakeBrainRepository(),
      );

      await controller.load();

      expect(controller.state.cookbook, [
        const CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'llama3.2',
          supportsTools: false,
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
        FakeBrainRepository(),
      );

      await controller.load();

      expect(controller.state.cookbook, [
        const CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'llama3.2',
          supportsTools: false,
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
        FakeBrainRepository(),
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
        FakeBrainRepository(),
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
        FakeBrainRepository(),
      );
      await controller.load();

      expect(controller.state.cookbook, [
        const CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'llama3.2',
          supportsTools: false,
        ),
        const CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'qwen2.5',
          supportsTools: false,
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
          supportsTools: false,
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
        FakeBrainRepository(),
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

    test('refresh() sets supportsTools: true for an Ollama model whose /api/show capabilities include '
        '"tools" and whose probe request returns a tool_calls response', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');
      final ollamaRepo = _ollamaRepoWith((options) {
        if (options.path == '/api/tags') {
          return ResponseBody.fromString(
            jsonEncode({'models': [{'name': 'llama3.2'}]}),
            200,
            headers: {Headers.contentTypeHeader: ['application/json']},
          );
        }
        if (options.path == '/api/show') {
          return ResponseBody.fromString(
            jsonEncode({'capabilities': ['completion', 'tools']}),
            200,
            headers: {Headers.contentTypeHeader: ['application/json']},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({
            'message': {
              'role': 'assistant',
              'content': '',
              'tool_calls': [
                {'function': {'name': '__capability_probe__', 'arguments': {}}},
              ],
            },
            'done': true,
          }),
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        );
      });

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: ollamaRepo}),
        FakeChatConversationsRepository(),
        FakeBrainRepository(),
      );
      await controller.load();

      expect(controller.state.cookbook, [
        const CookbookEntry(
          cardId: 'ollama-1',
          cardName: 'Ollama',
          cardType: ServiceType.ollama,
          model: 'llama3.2',
          supportsTools: true,
        ),
      ]);

      controller.dispose();
    });

    test('refresh() sets supportsTools: false for an Ollama model whose /api/show capabilities omit "tools" '
        '(no probe request sent)', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');
      var chatRequests = 0;
      final ollamaRepo = _ollamaRepoWith((options) {
        if (options.path == '/api/tags') {
          return ResponseBody.fromString(
            jsonEncode({'models': [{'name': 'llama3.2'}]}),
            200,
            headers: {Headers.contentTypeHeader: ['application/json']},
          );
        }
        if (options.path == '/api/show') {
          return ResponseBody.fromString(
            jsonEncode({'capabilities': ['completion']}),
            200,
            headers: {Headers.contentTypeHeader: ['application/json']},
          );
        }
        chatRequests++;
        return ResponseBody.fromString('{}', 200);
      });

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: ollamaRepo}),
        FakeChatConversationsRepository(),
        FakeBrainRepository(),
      );
      await controller.load();

      expect(controller.state.cookbook.single.supportsTools, isFalse);
      expect(chatRequests, 0);

      controller.dispose();
    });

    test('refresh() sets supportsTools: false for an Ollama model whose /api/show capabilities include "tools" '
        'but whose probe request returns plain text instead of tool_calls', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');
      final ollamaRepo = _ollamaRepoWith((options) {
        if (options.path == '/api/tags') {
          return ResponseBody.fromString(
            jsonEncode({'models': [{'name': 'llama3.2'}]}),
            200,
            headers: {Headers.contentTypeHeader: ['application/json']},
          );
        }
        if (options.path == '/api/show') {
          return ResponseBody.fromString(
            jsonEncode({'capabilities': ['completion', 'tools']}),
            200,
            headers: {Headers.contentTypeHeader: ['application/json']},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({
            'message': {
              'role': 'assistant',
              'content': '{"type": "function", "name": "__capability_probe__", "parameters": {}}',
            },
            'done': true,
          }),
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        );
      });

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: ollamaRepo}),
        FakeChatConversationsRepository(),
        FakeBrainRepository(),
      );
      await controller.load();

      expect(controller.state.cookbook.single.supportsTools, isFalse);

      controller.dispose();
    });

    test('refresh() fails closed (supportsTools: false) when /api/show errors for an Ollama model', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');
      final ollamaRepo = _ollamaRepoWith((options) {
        if (options.path == '/api/tags') {
          return ResponseBody.fromString(
            jsonEncode({'models': [{'name': 'llama3.2'}]}),
            200,
            headers: {Headers.contentTypeHeader: ['application/json']},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'error': 'model not found'}),
          404,
          headers: {Headers.contentTypeHeader: ['application/json']},
        );
      });

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: ollamaRepo}),
        FakeChatConversationsRepository(),
        FakeBrainRepository(),
      );
      await controller.load();

      expect(controller.state.cookbook.single.supportsTools, isFalse);

      controller.dispose();
    });

    test('refresh() defaults supportsTools: true for non-Ollama cards', () async {
      final claude = _claudeCard(id: 'claude-1', name: 'Claude');

      final controller = ChatController(
        FakeServiceCardsRepository([claude]),
        _repositoryFor({
          claude.id: FakeChatModelRepository(models: ['claude-3-5-sonnet-20241022']),
        }),
        FakeChatConversationsRepository(),
        FakeBrainRepository(),
      );
      await controller.load();

      expect(controller.state.cookbook.single.supportsTools, isTrue);

      controller.dispose();
    });

    test('newAgentConversation creates a conversation with workingProjectId set and the chosen entry active', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');
      final claude = _claudeCard(id: 'claude-1', name: 'Claude');

      final controller = ChatController(
        FakeServiceCardsRepository([ollama, claude]),
        _repositoryFor({
          ollama.id: FakeChatModelRepository(models: ['llama3.2']),
          claude.id: FakeChatModelRepository(models: ['claude-3-5-sonnet-20241022']),
        }),
        FakeChatConversationsRepository(),
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([_project(id: 'proj-1', name: 'crm', localPath: '/work/crm')]),
        agentToolRepository: FakeAgentToolRepository(),
      );
      await controller.load();

      final claudeEntry = controller.state.cookbook.firstWhere((e) => e.cardId == 'claude-1');
      controller.newAgentConversation('proj-1', claudeEntry);

      final conversation = controller.state.activeConversation!;
      expect(conversation.workingProjectId, 'proj-1');
      expect(conversation.messages, isEmpty);
      expect(controller.state.activeEntry, claudeEntry);

      controller.dispose();
    });

    test('branchIntoAgentMode copies messages from the source conversation without mutating it', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');
      final claude = _claudeCard(id: 'claude-1', name: 'Claude');

      const sourceId = 'source-convo';
      final now = DateTime.now();
      final sourceMessagesBefore = [
        const ChatMessage(role: ChatRole.user, content: 'Hello'),
        const ChatMessage(role: ChatRole.assistant, content: 'Hi'),
      ];
      final conversationsRepo = FakeChatConversationsRepository([
        ChatConversation(
          id: sourceId,
          title: 'Source chat',
          createdAt: now,
          updatedAt: now,
          messages: sourceMessagesBefore,
        ),
      ]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama, claude]),
        _repositoryFor({
          ollama.id: FakeChatModelRepository(models: ['llama3.2'], chunksToEmit: ['Hi']),
          claude.id: FakeChatModelRepository(models: ['claude-3-5-sonnet-20241022']),
        }),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([_project(id: 'proj-1', name: 'crm', localPath: '/work/crm')]),
        agentToolRepository: FakeAgentToolRepository(),
      );
      await controller.load();

      final claudeEntry = controller.state.cookbook.firstWhere((e) => e.cardId == 'claude-1');
      controller.branchIntoAgentMode(sourceId, 'proj-1', claudeEntry);

      // A new conversation was added alongside the source.
      expect(controller.state.conversations, hasLength(2));

      final branched = controller.state.activeConversation!;
      expect(branched.id, isNot(sourceId));
      expect(branched.workingProjectId, 'proj-1');
      expect(branched.messages.map((m) => m.content), sourceMessagesBefore.map((m) => m.content));
      expect(controller.state.activeEntry, claudeEntry);

      // The source conversation's messages remain unchanged.
      final source = controller.state.conversations.firstWhere((c) => c.id == sourceId);
      expect(source.messages, sourceMessagesBefore);
      expect(source.messages, isNot(same(branched.messages)));

      controller.dispose();
    });

    test('branchIntoAgentMode does nothing if the source conversation does not exist', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: FakeChatModelRepository(models: ['llama3.2'])}),
        FakeChatConversationsRepository(),
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([_project(id: 'proj-1', name: 'crm', localPath: '/work/crm')]),
        agentToolRepository: FakeAgentToolRepository(),
      );
      await controller.load();

      final entry = controller.state.cookbook.first;
      controller.branchIntoAgentMode('missing-id', 'proj-1', entry);

      expect(controller.state.conversations, isEmpty);

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
        FakeBrainRepository(),
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
        FakeBrainRepository(),
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
        FakeBrainRepository(),
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
        FakeBrainRepository(),
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
        FakeBrainRepository(),
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
        FakeBrainRepository(),
      );
      await firstController.load();
      firstController.newConversation();
      firstController.dispose();

      final secondController = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: FakeChatModelRepository()}),
        conversationsRepo,
        FakeBrainRepository(),
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
        FakeBrainRepository(),
      );
      await controller.load();
      controller.newConversation();

      await controller.sendMessage('Hi');

      final reloaded = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: FakeChatModelRepository()}),
        conversationsRepo,
        FakeBrainRepository(),
      );
      await reloaded.load();

      final messages = reloaded.state.conversations.first.messages;
      expect(messages, hasLength(2));
      expect(messages[1].content, 'Hello');
      expect(messages[1].streaming, isFalse);

      controller.dispose();
      reloaded.dispose();
    });

    test('sendMessage prepends the brain\'s system prompt to the messages sent to streamChat', () async {
      final ollama = _ollamaCard();
      final modelRepo = FakeChatModelRepository(chunksToEmit: ['Hi']);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        FakeChatConversationsRepository(),
        FakeBrainRepository(prompt: 'You are a helpful assistant.'),
      );
      await controller.load();
      controller.newConversation();

      await controller.sendMessage('Hello');

      final sentMessages = modelRepo.lastMessages!;
      expect(sentMessages.first.role, ChatRole.system);
      expect(sentMessages.first.content, 'You are a helpful assistant.');
      expect(sentMessages.length, 2);
      expect(sentMessages[1].role, ChatRole.user);
      expect(sentMessages[1].content, 'Hello');

      controller.dispose();
    });

    test('sendMessage leaves messages sent to streamChat unchanged when buildSystemPrompt returns null', () async {
      final ollama = _ollamaCard();
      final modelRepo = FakeChatModelRepository(chunksToEmit: ['Hi']);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        FakeChatConversationsRepository(),
        FakeBrainRepository(),
      );
      await controller.load();
      controller.newConversation();

      await controller.sendMessage('Hello');

      final sentMessages = modelRepo.lastMessages!;
      expect(sentMessages.length, 1);
      expect(sentMessages[0].role, ChatRole.user);
      expect(sentMessages[0].content, 'Hello');

      controller.dispose();
    });

    test('the prepended brain system message never appears in conversation.messages or persisted data', () async {
      final ollama = _ollamaCard();
      final conversationsRepo = FakeChatConversationsRepository();
      final modelRepo = FakeChatModelRepository(chunksToEmit: ['Hi']);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(prompt: 'You are a helpful assistant.'),
      );
      await controller.load();
      controller.newConversation();

      await controller.sendMessage('Hello');

      final messages = controller.state.activeConversation!.messages;
      expect(messages.any((m) => m.role == ChatRole.system), isFalse);

      final persisted = conversationsRepo.stored.first.messages;
      expect(persisted.any((m) => m.role == ChatRole.system), isFalse);

      controller.dispose();
    });
  });

  group('ChatController agent loop', () {
    final workingProject = _project(id: 'proj-1', name: 'crm', localPath: '/work/crm');
    final referenceProject = _project(id: 'proj-2', name: 'backend', localPath: '/work/backend');

    ChatConversation agentConversation({
      List<String> trustedReferenceProjectIds = const [],
      bool shellAccessEnabled = false,
    }) {
      final now = DateTime.now();
      return ChatConversation(
        id: 'agent-convo',
        title: 'Agent chat',
        createdAt: now,
        updatedAt: now,
        messages: const [],
        workingProjectId: workingProject.id,
        trustedReferenceProjectIds: trustedReferenceProjectIds,
        shellAccessEnabled: shellAccessEnabled,
      );
    }

    test('an agent-mode sendMessage passes the v1 tool definitions to streamChat', () async {
      final ollama = _ollamaCard();
      final modelRepo = FakeChatModelRepository(chunksToEmit: ['Hi']);
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: FakeAgentToolRepository(),
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Hello');

      expect(modelRepo.toolsPerCall.first, isNotEmpty);

      controller.dispose();
    });

    test('the tool list omits kRunCommandTool when shellAccessEnabled is false', () async {
      final ollama = _ollamaCard();
      final modelRepo = FakeChatModelRepository(chunksToEmit: ['Hi']);
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: FakeAgentToolRepository(),
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Hello');

      expect(modelRepo.toolsPerCall.first, kAgentTools);
      expect(modelRepo.toolsPerCall.first, isNot(contains(kRunCommandTool)));

      controller.dispose();
    });

    test('the tool list includes kRunCommandTool when shellAccessEnabled is true', () async {
      final ollama = _ollamaCard();
      final modelRepo = FakeChatModelRepository(chunksToEmit: ['Hi']);
      final conversationsRepo = FakeChatConversationsRepository([agentConversation(shellAccessEnabled: true)]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: FakeAgentToolRepository(),
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Hello');

      expect(modelRepo.toolsPerCall.first, [...kAgentTools, kRunCommandTool]);

      controller.dispose();
    });

    test('a run_command call resolves to a "not enabled" ToolError when shellAccessEnabled is false, and the loop continues', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'run_command', arguments: {'command': 'flutter test'});

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
        [const ChatStreamTextDelta('I cannot run shell commands here.')],
      ]);
      final agentToolRepo = FakeAgentToolRepository();
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: agentToolRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Run the tests');

      final messages = controller.state.activeConversation!.messages;
      expect(messages[2].role, ChatRole.tool);
      expect(messages[2].content, 'Shell access is not enabled for this conversation.');
      expect(messages[3].content, 'I cannot run shell commands here.');
      expect(agentToolRepo.executedCalls, isEmpty);

      controller.dispose();
    });

    test('a text-only turn behaves like a normal conversation turn', () async {
      final ollama = _ollamaCard();
      final modelRepo = FakeChatModelRepository(chunksToEmit: ['Hello', ' there']);
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: FakeAgentToolRepository(),
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Hi');

      final messages = controller.state.activeConversation!.messages;
      expect(messages, hasLength(2));
      expect(messages[1].role, ChatRole.assistant);
      expect(messages[1].content, 'Hello there');
      expect(messages[1].streaming, isFalse);
      expect(messages[1].toolCalls, isEmpty);
      expect(controller.state.isStreaming, isFalse);

      controller.dispose();
    });

    test('a turn requesting a tool call resolving to ToolOutput re-invokes streamChat and loops to a final answer', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'read_file', arguments: {'path': 'lib/main.dart'});

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
        [const ChatStreamTextDelta('All done.')],
      ]);
      final agentToolRepo = FakeAgentToolRepository(resultsByCallId: {
        'call-1': [const ToolOutput('file contents')],
      });
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: agentToolRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Read main.dart');

      final messages = controller.state.activeConversation!.messages;
      expect(messages, hasLength(4));
      expect(messages[0].role, ChatRole.user);
      expect(messages[1].role, ChatRole.assistant);
      expect(messages[1].toolCalls, [call]);
      expect(messages[1].streaming, isFalse);
      expect(messages[2].role, ChatRole.tool);
      expect(messages[2].toolCallId, 'call-1');
      expect(messages[2].toolName, 'read_file');
      expect(messages[2].content, 'file contents');
      expect(messages[3].role, ChatRole.assistant);
      expect(messages[3].content, 'All done.');
      expect(messages[3].toolCalls, isEmpty);

      expect(modelRepo.toolsPerCall, hasLength(2));
      expect(agentToolRepo.executedCalls, [call]);

      controller.dispose();
    });

    test('a ToolError result is fed back as a tool message and the loop continues', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'read_file', arguments: {'path': 'missing.dart'});

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
        [const ChatStreamTextDelta('That file does not exist.')],
      ]);
      final agentToolRepo = FakeAgentToolRepository(resultsByCallId: {
        'call-1': [const ToolError('File not found: missing.dart')],
      });
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: agentToolRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Read missing.dart');

      final messages = controller.state.activeConversation!.messages;
      expect(messages[2].role, ChatRole.tool);
      expect(messages[2].content, 'File not found: missing.dart');
      expect(messages[3].content, 'That file does not exist.');

      controller.dispose();
    });

    test('a web_search call is dispatched to WebSearchRepository, not AgentToolRepository', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'web_search', arguments: {'query': 'flutter news'});

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
        [const ChatStreamTextDelta('Here is what I found.')],
      ]);
      final agentToolRepo = FakeAgentToolRepository();
      final webSearchRepo = FakeWebSearchRepository(const ToolOutput('Title 1\nhttps://example.com\nSnippet 1'));
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: agentToolRepo,
        webSearchRepository: webSearchRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Search for flutter news');

      final messages = controller.state.activeConversation!.messages;
      expect(messages[2].role, ChatRole.tool);
      expect(messages[2].toolCallId, 'call-1');
      expect(messages[2].toolName, 'web_search');
      expect(messages[2].content, 'Title 1\nhttps://example.com\nSnippet 1');
      expect(messages[3].content, 'Here is what I found.');

      expect(webSearchRepo.queries, ['flutter news']);
      expect(agentToolRepo.executedCalls, isEmpty);

      // The second streamChat call (after the tool result) must receive the
      // full history, including the assistant message's toolCalls and the
      // tool result message — otherwise the model has no record of having
      // called web_search and cannot produce a grounded final response.
      final secondCallMessages = modelRepo.lastMessages!;
      final assistantWithToolCall = secondCallMessages.firstWhere(
        (m) => m.role == ChatRole.assistant && m.toolCalls.isNotEmpty,
      );
      expect(assistantWithToolCall.toolCalls, hasLength(1));
      expect(assistantWithToolCall.toolCalls.first.id, 'call-1');
      expect(assistantWithToolCall.toolCalls.first.name, 'web_search');

      final toolResultMessage = secondCallMessages.firstWhere(
        (m) => m.role == ChatRole.tool && m.toolCallId == 'call-1',
      );
      expect(toolResultMessage.content, 'Title 1\nhttps://example.com\nSnippet 1');

      controller.dispose();
    });

    test('a web_search call resolves to a "not configured" ToolError when no WebSearchRepository is set, and the loop continues', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'web_search', arguments: {'query': 'flutter news'});

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
        [const ChatStreamTextDelta('I cannot search right now.')],
      ]);
      final agentToolRepo = FakeAgentToolRepository();
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: agentToolRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Search for flutter news');

      final messages = controller.state.activeConversation!.messages;
      expect(messages[2].role, ChatRole.tool);
      expect(messages[2].content, contains('not configured'));
      expect(messages[3].content, 'I cannot search right now.');

      controller.dispose();
    });

    test('a fetch_page call is dispatched to FetchPageRepository, not AgentToolRepository', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'fetch_page', arguments: {'url': 'https://example.com/article'});

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
        [const ChatStreamTextDelta('Here is what the page says.')],
      ]);
      final agentToolRepo = FakeAgentToolRepository();
      final fetchPageRepo = FakeFetchPageRepository(const ToolOutput('Article body text.'));
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: agentToolRepo,
        fetchPageRepository: fetchPageRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Fetch https://example.com/article');

      final messages = controller.state.activeConversation!.messages;
      expect(messages[2].role, ChatRole.tool);
      expect(messages[2].toolCallId, 'call-1');
      expect(messages[2].toolName, 'fetch_page');
      expect(messages[2].content, 'Article body text.');
      expect(messages[3].content, 'Here is what the page says.');

      expect(fetchPageRepo.urls, ['https://example.com/article']);
      expect(agentToolRepo.executedCalls, isEmpty);

      controller.dispose();
    });

    test('a fetch_page call resolves to a "not configured" ToolError when no FetchPageRepository is set, and the loop continues', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'fetch_page', arguments: {'url': 'https://example.com/article'});

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
        [const ChatStreamTextDelta('I cannot fetch pages right now.')],
      ]);
      final agentToolRepo = FakeAgentToolRepository();
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: agentToolRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Fetch https://example.com/article');

      final messages = controller.state.activeConversation!.messages;
      expect(messages[2].role, ChatRole.tool);
      expect(messages[2].content, contains('not configured'));
      expect(messages[3].content, 'I cannot fetch pages right now.');

      controller.dispose();
    });

    test('a write_file call resolving to ToolWriteProposal stops the loop with the call left unanswered', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'write_file', arguments: {'path': 'new.dart', 'content': 'hello'});

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
      ]);
      final agentToolRepo = FakeAgentToolRepository(resultsByCallId: {
        'call-1': [const ToolWriteProposal('/work/crm/new.dart', WriteFileCreation('hello'))],
      });
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: agentToolRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Create new.dart');

      final messages = controller.state.activeConversation!.messages;
      expect(messages, hasLength(2));
      expect(messages[1].toolCalls, [call]);
      // No tool-role answer yet — pending.
      expect(messages.any((m) => m.role == ChatRole.tool), isFalse);
      expect(modelRepo.toolsPerCall, hasLength(1));

      controller.dispose();
    });

    test('approveToolCall applies the pending write, appends its result, and resumes the loop', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'write_file', arguments: {'path': 'new.dart', 'content': 'hello'});
      const proposal = ToolWriteProposal('/work/crm/new.dart', WriteFileCreation('hello'));

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
        [const ChatStreamTextDelta('Created the file.')],
      ]);
      final agentToolRepo = FakeAgentToolRepository(
        resultsByCallId: {'call-1': [proposal]},
        applyWriteResult: (p) => ToolOutput('Wrote ${(p.preview as WriteFileCreation).content.length} bytes to ${p.path}'),
      );
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: agentToolRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Create new.dart');
      await controller.approveToolCall('agent-convo', 'call-1');

      final messages = controller.state.activeConversation!.messages;
      expect(agentToolRepo.appliedWrites, [proposal]);
      expect(messages[2].role, ChatRole.tool);
      expect(messages[2].toolCallId, 'call-1');
      expect(messages[2].content, 'Wrote 5 bytes to /work/crm/new.dart');
      expect(messages[3].content, 'Created the file.');

      controller.dispose();
    });

    test('rejectToolCall records a rejection and resumes the loop without writing to disk', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'write_file', arguments: {'path': 'new.dart', 'content': 'hello'});
      const proposal = ToolWriteProposal('/work/crm/new.dart', WriteFileCreation('hello'));

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
        [const ChatStreamTextDelta('Okay, skipped.')],
      ]);
      final agentToolRepo = FakeAgentToolRepository(resultsByCallId: {'call-1': [proposal]});
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: agentToolRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Create new.dart');
      await controller.rejectToolCall('agent-convo', 'call-1');

      final messages = controller.state.activeConversation!.messages;
      expect(agentToolRepo.appliedWrites, isEmpty);
      expect(messages[2].role, ChatRole.tool);
      expect(messages[2].toolCallId, 'call-1');
      expect(messages[2].content, 'User rejected this change.');
      expect(messages[3].content, 'Okay, skipped.');

      controller.dispose();
    });

    test('a run_command call resolves to ToolWriteProposal with a CommandExecution preview and stops the loop', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'run_command', arguments: {'command': 'flutter test'});

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
      ]);
      final agentToolRepo = FakeAgentToolRepository();
      final conversationsRepo = FakeChatConversationsRepository([agentConversation(shellAccessEnabled: true)]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: agentToolRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Run the tests');

      final messages = controller.state.activeConversation!.messages;
      expect(messages, hasLength(2));
      expect(messages[1].toolCalls, [call]);
      // No tool-role answer yet — pending.
      expect(messages.any((m) => m.role == ChatRole.tool), isFalse);

      controller.dispose();
    });

    test('approveToolCall for run_command executes via CommandExecutionRepository and feeds back the result', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'run_command', arguments: {'command': 'flutter test'});

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
        [const ChatStreamTextDelta('Tests passed.')],
      ]);
      final agentToolRepo = FakeAgentToolRepository();
      final commandExecutionRepo =
          FakeCommandExecutionRepository(const ToolOutput('Exit code: 0\n\nstdout:\nok\n\nstderr:\n'));
      final conversationsRepo = FakeChatConversationsRepository([agentConversation(shellAccessEnabled: true)]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: agentToolRepo,
        commandExecutionRepository: commandExecutionRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Run the tests');
      await controller.approveToolCall('agent-convo', 'call-1');

      final messages = controller.state.activeConversation!.messages;
      expect(commandExecutionRepo.commands, ['flutter test']);
      expect(commandExecutionRepo.workingDirectories, [workingProject.localPath]);
      expect(messages[2].role, ChatRole.tool);
      expect(messages[2].toolCallId, 'call-1');
      expect(messages[2].content, 'Exit code: 0\n\nstdout:\nok\n\nstderr:\n');
      expect(messages[3].content, 'Tests passed.');

      // The second streamChat call (which produced "Tests passed.") must
      // receive the full history, including the assistant's tool_calls and
      // the tool result — otherwise the model has no record of what command
      // ran or what it returned.
      expect(modelRepo.toolsPerCall, hasLength(2));
      final secondCallMessages = modelRepo.lastMessages!;
      final assistantWithToolCalls =
          secondCallMessages.firstWhere((m) => m.role == ChatRole.assistant && m.toolCalls.isNotEmpty);
      expect(assistantWithToolCalls.toolCalls, [call]);
      final toolResultMessage = secondCallMessages.firstWhere((m) => m.role == ChatRole.tool);
      expect(toolResultMessage.toolCallId, 'call-1');
      expect(toolResultMessage.content, 'Exit code: 0\n\nstdout:\nok\n\nstderr:\n');

      controller.dispose();
    });

    test('rejectToolCall for run_command records a rejection without executing', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'run_command', arguments: {'command': 'flutter test'});

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
        [const ChatStreamTextDelta('Okay, skipped.')],
      ]);
      final agentToolRepo = FakeAgentToolRepository();
      final commandExecutionRepo = FakeCommandExecutionRepository(const ToolOutput('Exit code: 0'));
      final conversationsRepo = FakeChatConversationsRepository([agentConversation(shellAccessEnabled: true)]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: agentToolRepo,
        commandExecutionRepository: commandExecutionRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Run the tests');
      await controller.rejectToolCall('agent-convo', 'call-1');

      final messages = controller.state.activeConversation!.messages;
      expect(commandExecutionRepo.commands, isEmpty);
      expect(messages[2].role, ChatRole.tool);
      expect(messages[2].toolCallId, 'call-1');
      expect(messages[2].content, 'User rejected this change.');
      expect(messages[3].content, 'Okay, skipped.');

      controller.dispose();
    });

    test('a tool call resolving to ToolReferenceConfirmationNeeded stops the loop pending allow/deny', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'read_file', arguments: {'path': '/work/backend/main.ts'});

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
      ]);
      final agentToolRepo = FakeAgentToolRepository(resultsByCallId: {
        'call-1': [const ToolReferenceConfirmationNeeded('proj-2', '/work/backend/main.ts')],
      });
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject, referenceProject]),
        agentToolRepository: agentToolRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Read backend/main.ts');

      final messages = controller.state.activeConversation!.messages;
      expect(messages, hasLength(2));
      expect(messages[1].toolCalls, [call]);
      expect(messages.any((m) => m.role == ChatRole.tool), isFalse);

      controller.dispose();
    });

    test('allowReferenceProject trusts the project, re-attempts the call, and does not re-prompt for it again', () async {
      final ollama = _ollamaCard();
      const call1 = ToolCall(id: 'call-1', name: 'read_file', arguments: {'path': '/work/backend/main.ts'});
      const call2 = ToolCall(id: 'call-2', name: 'read_file', arguments: {'path': '/work/backend/other.ts'});

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call1])],
        [const ChatStreamTextDelta('Got it.')],
        [const ChatStreamToolCallsRequested([call2])],
        [const ChatStreamTextDelta('Got the other one too.')],
      ]);
      final agentToolRepo = FakeAgentToolRepository(resultsByCallId: {
        'call-1': [const ToolReferenceConfirmationNeeded('proj-2', '/work/backend/main.ts'), const ToolOutput('main.ts contents')],
        'call-2': [const ToolOutput('other.ts contents')],
      });
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject, referenceProject]),
        agentToolRepository: agentToolRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Read backend/main.ts');
      await controller.allowReferenceProject('agent-convo', 'call-1', 'proj-2');

      var messages = controller.state.activeConversation!.messages;
      expect(controller.state.activeConversation!.trustedReferenceProjectIds, contains('proj-2'));
      expect(messages[2].role, ChatRole.tool);
      expect(messages[2].content, 'main.ts contents');
      expect(messages[3].content, 'Got it.');

      // A later call into the now-trusted reference project is not re-prompted.
      await controller.sendMessage('Read backend/other.ts too');

      messages = controller.state.activeConversation!.messages;
      final toolMessages = messages.where((m) => m.role == ChatRole.tool).toList();
      expect(toolMessages.last.content, 'other.ts contents');
      expect(messages.last.content, 'Got the other one too.');

      controller.dispose();
    });

    test('denyReferenceProject records a denial and resumes the loop without granting access', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'read_file', arguments: {'path': '/work/backend/main.ts'});

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
        [const ChatStreamTextDelta('Okay, I will not read that.')],
      ]);
      final agentToolRepo = FakeAgentToolRepository(resultsByCallId: {
        'call-1': [const ToolReferenceConfirmationNeeded('proj-2', '/work/backend/main.ts')],
      });
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject, referenceProject]),
        agentToolRepository: agentToolRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Read backend/main.ts');
      await controller.denyReferenceProject('agent-convo', 'call-1', 'proj-2');

      final messages = controller.state.activeConversation!.messages;
      expect(controller.state.activeConversation!.trustedReferenceProjectIds, isNot(contains('proj-2')));
      expect(messages[2].role, ChatRole.tool);
      expect(messages[2].content, 'User denied read access to this project.');
      expect(messages[3].content, 'Okay, I will not read that.');

      controller.dispose();
    });

    test('the loop stops and appends a notice after kMaxAgentLoopSteps round-trips', () async {
      final ollama = _ollamaCard();

      // Build kMaxAgentLoopSteps + 1 scripted turns, each immediately
      // requesting another tool call resolving to ToolOutput.
      final scriptedTurns = <List<ChatStreamEvent>>[];
      for (var i = 0; i < kMaxAgentLoopSteps + 1; i++) {
        scriptedTurns.add([ChatStreamToolCallsRequested([ToolCall(id: 'call-$i', name: 'read_file', arguments: {'path': 'f$i.dart'})])]);
      }

      final modelRepo = FakeChatModelRepository(scriptedTurns: scriptedTurns);
      final agentToolRepo = FakeAgentToolRepository(); // defaults every call to ToolOutput('ok')
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: agentToolRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Loop forever');

      final messages = controller.state.activeConversation!.messages;
      final last = messages.last;
      expect(last.role, ChatRole.assistant);
      expect(last.content, contains('$kMaxAgentLoopSteps'));
      // streamChat was invoked once for the initial turn plus once per
      // completed round-trip, capped at kMaxAgentLoopSteps total turns.
      expect(modelRepo.toolsPerCall.length, kMaxAgentLoopSteps);

      controller.dispose();
    });

    test('a pending write proposal survives a simulated restart', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'write_file', arguments: {'path': 'new.dart', 'content': 'hello'});

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
      ]);
      final agentToolRepo = FakeAgentToolRepository(resultsByCallId: {
        'call-1': [const ToolWriteProposal('/work/crm/new.dart', WriteFileCreation('hello'))],
      });
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: agentToolRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Create new.dart');
      controller.dispose();

      // Simulate an app restart with a fresh controller backed by the same
      // persisted conversations repository.
      final reloaded = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: FakeChatModelRepository()}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: FakeAgentToolRepository(),
      );
      await reloaded.load();

      final reloadedConversation = reloaded.state.conversations.firstWhere((c) => c.id == 'agent-convo');
      expect(reloadedConversation.messages, hasLength(2));
      expect(reloadedConversation.messages[1].toolCalls, [call]);
      expect(reloadedConversation.messages.any((m) => m.role == ChatRole.tool), isFalse);

      reloaded.dispose();
    });

    test('previewPendingToolCall returns the resolved ToolWriteProposal for a pending write_file call', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'write_file', arguments: {'path': 'new.dart', 'content': 'hello'});
      const proposal = ToolWriteProposal('/work/crm/new.dart', WriteFileCreation('hello'));

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
      ]);
      final agentToolRepo = FakeAgentToolRepository(resultsByCallId: {'call-1': [proposal]});
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: agentToolRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Create new.dart');
      final preview = await controller.previewPendingToolCall('agent-convo', 'call-1');

      expect(preview, isA<ToolWriteProposal>());
      expect((preview as ToolWriteProposal).path, '/work/crm/new.dart');
      expect((preview.preview as WriteFileCreation).content, 'hello');
      // Read-only: no write applied and the call is still pending.
      expect(agentToolRepo.appliedWrites, isEmpty);
      expect(controller.state.activeConversation!.messages.any((m) => m.role == ChatRole.tool), isFalse);

      controller.dispose();
    });

    test('previewPendingToolCall returns ToolReferenceConfirmationNeeded with the project id for a pending reference read', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'read_file', arguments: {'path': '/work/backend/main.ts'});

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
      ]);
      final agentToolRepo = FakeAgentToolRepository(resultsByCallId: {
        'call-1': [const ToolReferenceConfirmationNeeded('proj-2', '/work/backend/main.ts')],
      });
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject, referenceProject]),
        agentToolRepository: agentToolRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Read backend/main.ts');
      final preview = await controller.previewPendingToolCall('agent-convo', 'call-1');

      expect(preview, isA<ToolReferenceConfirmationNeeded>());
      expect((preview as ToolReferenceConfirmationNeeded).projectId, 'proj-2');
      expect(preview.path, '/work/backend/main.ts');

      controller.dispose();
    });

    test('previewPendingToolCall returns null once the call has been answered', () async {
      final ollama = _ollamaCard();
      const call = ToolCall(id: 'call-1', name: 'read_file', arguments: {'path': 'main.dart'});

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([call])],
        [const ChatStreamTextDelta('Done.')],
      ]);
      final agentToolRepo = FakeAgentToolRepository(resultsByCallId: {
        'call-1': [const ToolOutput('file contents')],
      });
      final conversationsRepo = FakeChatConversationsRepository([agentConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([workingProject]),
        agentToolRepository: agentToolRepo,
      );
      await controller.load();
      controller.selectConversation('agent-convo');

      await controller.sendMessage('Read main.dart');
      final preview = await controller.previewPendingToolCall('agent-convo', 'call-1');

      expect(preview, isNull);

      controller.dispose();
    });
  });

  group('ChatController Deep Research mode', () {
    ChatConversation deepResearchConversation() {
      final now = DateTime.now();
      return ChatConversation(
        id: 'research-convo',
        title: 'Research chat',
        createdAt: now,
        updatedAt: now,
        messages: const [],
        isDeepResearch: true,
      );
    }

    test('a Deep Research sendMessage passes kDeepResearchTools to streamChat', () async {
      final ollama = _ollamaCard();
      final modelRepo = FakeChatModelRepository(chunksToEmit: ['Hi']);
      final conversationsRepo = FakeChatConversationsRepository([deepResearchConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([]),
        agentToolRepository: FakeAgentToolRepository(),
      );
      await controller.load();
      controller.selectConversation('research-convo');

      await controller.sendMessage('Research flutter state management options');

      expect(modelRepo.toolsPerCall.first, kDeepResearchTools);

      controller.dispose();
    });

    test('the system prompt for a Deep Research conversation includes kDeepResearchSystemPromptAddition', () async {
      final ollama = _ollamaCard();
      final modelRepo = FakeChatModelRepository(chunksToEmit: ['Hi']);
      final conversationsRepo = FakeChatConversationsRepository([deepResearchConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([]),
        agentToolRepository: FakeAgentToolRepository(),
      );
      await controller.load();
      controller.selectConversation('research-convo');

      await controller.sendMessage('Research flutter state management options');

      final systemMessage = modelRepo.lastMessages!.firstWhere((m) => m.role == ChatRole.system);
      expect(systemMessage.content, contains(kDeepResearchSystemPromptAddition));

      controller.dispose();
    });

    test('a Deep Research turn dispatches web_search and fetch_page across several round-trips', () async {
      final ollama = _ollamaCard();

      final modelRepo = FakeChatModelRepository(scriptedTurns: [
        [const ChatStreamToolCallsRequested([
          ToolCall(id: 'call-1', name: 'web_search', arguments: {'query': 'flutter state management'}),
        ])],
        [const ChatStreamToolCallsRequested([
          ToolCall(id: 'call-2', name: 'fetch_page', arguments: {'url': 'https://example.com/article'}),
        ])],
        [const ChatStreamTextDelta('Based on my research, here is the summary, citing https://example.com/article.')],
      ]);
      final webSearchRepo = FakeWebSearchRepository(const ToolOutput('Title 1\nhttps://example.com/article\nSnippet 1'));
      final fetchPageRepo = FakeFetchPageRepository(const ToolOutput('Article body text.'));
      final conversationsRepo = FakeChatConversationsRepository([deepResearchConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([]),
        agentToolRepository: FakeAgentToolRepository(),
        webSearchRepository: webSearchRepo,
        fetchPageRepository: fetchPageRepo,
      );
      await controller.load();
      controller.selectConversation('research-convo');

      await controller.sendMessage('Research flutter state management options');

      expect(webSearchRepo.queries, ['flutter state management']);
      expect(fetchPageRepo.urls, ['https://example.com/article']);
      expect(modelRepo.toolsPerCall, hasLength(3));
      expect(modelRepo.toolsPerCall, everyElement(kDeepResearchTools));

      final messages = controller.state.activeConversation!.messages;
      expect(messages, hasLength(6));

      expect(messages[0].role, ChatRole.user);

      expect(messages[1].role, ChatRole.assistant);
      expect(messages[1].toolCalls, [const ToolCall(id: 'call-1', name: 'web_search', arguments: {'query': 'flutter state management'})]);
      expect(messages[1].streaming, isFalse);

      expect(messages[2].role, ChatRole.tool);
      expect(messages[2].toolCallId, 'call-1');
      expect(messages[2].toolName, 'web_search');
      expect(messages[2].content, contains('https://example.com/article'));

      expect(messages[3].role, ChatRole.assistant);
      expect(messages[3].toolCalls, [const ToolCall(id: 'call-2', name: 'fetch_page', arguments: {'url': 'https://example.com/article'})]);
      expect(messages[3].streaming, isFalse);

      expect(messages[4].role, ChatRole.tool);
      expect(messages[4].toolCallId, 'call-2');
      expect(messages[4].toolName, 'fetch_page');
      expect(messages[4].content, 'Article body text.');

      final last = messages[5];
      expect(last.role, ChatRole.assistant);
      expect(last.toolCalls, isEmpty);
      expect(last.streaming, isFalse);
      expect(last.content, contains('https://example.com/article'));

      controller.dispose();
    });

    test('the loop stops and appends a best-effort notice after kMaxDeepResearchSteps round-trips', () async {
      final ollama = _ollamaCard();

      final scriptedTurns = <List<ChatStreamEvent>>[];
      for (var i = 0; i < kMaxDeepResearchSteps + 1; i++) {
        scriptedTurns.add([ChatStreamToolCallsRequested([ToolCall(id: 'call-$i', name: 'web_search', arguments: {'query': 'topic $i'})])]);
      }

      final modelRepo = FakeChatModelRepository(scriptedTurns: scriptedTurns);
      final webSearchRepo = FakeWebSearchRepository(const ToolOutput('Title\nhttps://example.com\nSnippet'));
      final conversationsRepo = FakeChatConversationsRepository([deepResearchConversation()]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
        projectsRepository: FakeProjectsRepository([]),
        agentToolRepository: FakeAgentToolRepository(),
        webSearchRepository: webSearchRepo,
      );
      await controller.load();
      controller.selectConversation('research-convo');

      await controller.sendMessage('Research forever');

      final messages = controller.state.activeConversation!.messages;
      final last = messages.last;
      expect(last.role, ChatRole.assistant);
      expect(last.content, contains('$kMaxDeepResearchSteps'));
      expect(modelRepo.toolsPerCall.length, kMaxDeepResearchSteps);

      controller.dispose();
    });

    test('newDeepResearchConversation creates a conversation with isDeepResearch true and the given entry active', () async {
      final ollama = _ollamaCard(id: 'ollama-1', name: 'Ollama');
      final modelRepo = FakeChatModelRepository();
      final conversationsRepo = FakeChatConversationsRepository([]);

      final controller = ChatController(
        FakeServiceCardsRepository([ollama]),
        _repositoryFor({ollama.id: modelRepo}),
        conversationsRepo,
        FakeBrainRepository(),
      );
      await controller.load();

      const entry = CookbookEntry(
        cardId: 'ollama-1',
        cardName: 'Ollama',
        cardType: ServiceType.ollama,
        model: 'llama3.2',
        supportsTools: true,
      );

      controller.newDeepResearchConversation(entry);

      final conversation = controller.state.activeConversation!;
      expect(conversation.isDeepResearch, isTrue);
      expect(controller.state.activeEntry, entry);

      controller.dispose();
    });
  });
}
