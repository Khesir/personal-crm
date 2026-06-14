import 'package:crm/core/state/state.dart';
import 'package:crm/features/brain/api.dart';
import 'package:crm/features/home/data/repository/ollama_repository_impl.dart';
import 'package:crm/features/settings/domain/model/fit_scorer.dart';
import 'package:crm/features/settings/domain/model/hardware_info.dart';
import 'package:crm/features/settings/domain/model/model_fit_result.dart';
import 'package:crm/features/settings/domain/model/model_name_parser.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';
import 'package:crm/features/settings/domain/repository/hardware_info_repository.dart';
import 'package:crm/features/settings/domain/repository/projects_repository.dart';
import 'package:crm/features/settings/domain/repository/service_cards_repository.dart';
import '../../presentation/state/chat_state.dart';
import '../model/agent_loop_constants.dart';
import '../model/chat_conversation.dart';
import '../model/chat_message.dart';
import '../model/chat_stream_event.dart';
import '../model/cookbook_entry.dart';
import '../model/tool_execution_result.dart';
import '../repository/agent_tool_repository.dart';
import '../repository/chat_conversations_repository.dart';
import '../repository/chat_model_repository.dart';
import '../repository/command_execution_repository.dart';
import '../repository/fetch_page_repository.dart';
import '../repository/web_search_repository.dart';
import 'agent_loop_runner.dart';

class ChatController extends StreamState<ChatStateData> {
  final ServiceCardsRepository serviceCardsRepository;
  final ChatModelRepository Function(ServiceCard card) repositoryFor;
  final ChatConversationsRepository conversationsRepository;
  final BrainRepository brainRepository;
  final ProjectsRepository? projectsRepository;
  final AgentToolRepository? agentToolRepository;
  final WebSearchRepository? webSearchRepository;
  final CommandExecutionRepository? commandExecutionRepository;
  final HardwareInfoRepository? hardwareInfoRepository;
  final FetchPageRepository? fetchPageRepository;

  List<ServiceCard> _cookbookCards = [];
  AgentLoopRunner? _agentLoopRunner;
  HardwareInfo? _hardwareInfo;

  ChatController(
    this.serviceCardsRepository,
    this.repositoryFor,
    this.conversationsRepository,
    this.brainRepository, {
    this.projectsRepository,
    this.agentToolRepository,
    this.webSearchRepository,
    this.commandExecutionRepository,
    this.hardwareInfoRepository,
    this.fetchPageRepository,
  }) : super(const ChatStateData()) {
    final projects = projectsRepository;
    final agentTools = agentToolRepository;
    if (projects != null && agentTools != null) {
      _agentLoopRunner = AgentLoopRunner(
        agentToolRepository: agentTools,
        projectsRepository: projects,
        webSearchRepository: webSearchRepository,
        commandExecutionRepository: commandExecutionRepository,
        fetchPageRepository: fetchPageRepository,
      );
    }
  }

  Future<void> load() async {
    final conversations = await conversationsRepository.getConversations();
    await refresh();
    emit(state.copyWith(conversations: conversations));
  }

  /// Re-aggregates the cookbook from the current Local LLM and API LLM
  /// service cards (enabled cards' reachable models, minus each card's
  /// `disabledModels`), without reloading conversations.
  ///
  /// Called by [load] at startup, and again whenever Home becomes visible
  /// (see `createChatController` in `home/di.dart`) so that changes made in
  /// Settings (toggling a model, or enabling/disabling/adding/removing a
  /// Local LLM or API LLM card) are reflected without restarting the app.
  Future<void> refresh() async {
    final cards = await serviceCardsRepository.getCards();
    _cookbookCards = cards
        .where((c) =>
            (c.category == ServiceCategory.localLlm ||
                c.category == ServiceCategory.apiLlm) &&
            c.enabled)
        .toList();

    final cookbook = <CookbookEntry>[];
    for (final card in _cookbookCards) {
      try {
        final repo = repositoryFor(card);
        final models = await repo.listModels();
        for (final model in models) {
          if (!card.disabledModels.contains(model)) {
            cookbook.add(CookbookEntry(
              cardId: card.id,
              cardName: card.name,
              cardType: card.type,
              model: model,
              supportsTools: await _supportsTools(card, repo, model),
              fitResult: card.category == ServiceCategory.localLlm
                  ? await _fitResultFor(model)
                  : null,
            ));
          }
        }
      } catch (_) {
        // A failing card contributes zero entries.
      }
    }

    final previous = state.activeEntry;
    final keepPrevious = previous != null && cookbook.contains(previous);

    emit(state.copyWith(
      cookbook: cookbook,
      activeEntry: keepPrevious
          ? previous
          : (recommendedCookbookEntry(cookbook) ??
              (cookbook.isNotEmpty ? cookbook.first : null)),
      clearActiveEntry: !keepPrevious && cookbook.isEmpty,
    ));
  }

  /// For [ServiceType.ollama] cards, queries `/api/show` for [model]'s
  /// capabilities and returns whether `"tools"` is present. Defaults to
  /// `false` (fail closed) if the request errors, so agent mode is never
  /// offered for a model whose capabilities couldn't be determined.
  ///
  /// For all other [ServiceType]s, tool support is assumed and this returns
  /// `true`.
  Future<bool> _supportsTools(ServiceCard card, ChatModelRepository repo, String model) async {
    if (card.type != ServiceType.ollama) return true;
    if (repo is! OllamaRepositoryImpl) return false;
    try {
      return await repo.supportsTools(model);
    } catch (_) {
      return false;
    }
  }

  /// Scores [model]'s name/tag against the cached [HardwareInfo] via
  /// [FitScorer]. Returns null if the name doesn't parse into a parameter
  /// count and quantization, or if [hardwareInfoRepository] isn't
  /// configured.
  Future<ModelFitResult?> _fitResultFor(String model) async {
    final paramsBillions = ModelNameParser.parseParamsBillions(model);
    final quant = ModelNameParser.parseQuant(model);
    if (paramsBillions == null || quant == null) return null;

    final hardware = await _ensureHardwareInfo();
    if (hardware == null) return null;

    return FitScorer.score(hardware: hardware, paramsBillions: paramsBillions, quant: quant);
  }

  /// Detects and caches [HardwareInfo] for the lifetime of this controller —
  /// detection involves running external processes, so it is not re-run on
  /// every [refresh].
  Future<HardwareInfo?> _ensureHardwareInfo() async {
    final repo = hardwareInfoRepository;
    if (repo == null) return null;
    final cached = _hardwareInfo;
    if (cached != null) return cached;
    final detected = await repo.detect();
    _hardwareInfo = detected;
    return detected;
  }

  void newConversation() {
    final now = DateTime.now();
    final conversation = ChatConversation(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'New chat',
      createdAt: now,
      updatedAt: now,
      messages: const [],
    );
    emit(state.copyWith(
      conversations: [conversation, ...state.conversations],
      activeConversationId: conversation.id,
    ));
    _persist();
  }

  /// Creates a new agent-mode conversation with [projectId] as its
  /// `workingProjectId` and [entry] as the active model. Mirrors
  /// [newConversation], but sets the working project and active entry at
  /// creation time — `workingProjectId` is immutable thereafter.
  void newAgentConversation(String projectId, CookbookEntry entry, {bool shellAccessEnabled = false}) {
    final now = DateTime.now();
    final conversation = ChatConversation(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'New chat',
      createdAt: now,
      updatedAt: now,
      messages: const [],
      workingProjectId: projectId,
      shellAccessEnabled: shellAccessEnabled,
    );
    emit(state.copyWith(
      conversations: [conversation, ...state.conversations],
      activeConversationId: conversation.id,
      activeEntry: entry,
    ));
    _persist();
  }

  /// Creates a new agent-mode conversation that branches off
  /// [sourceConversationId]: a deep copy of its messages at branch time,
  /// with [projectId] as the new conversation's `workingProjectId` and
  /// [entry] as its active model. The source conversation is left
  /// unchanged.
  void branchIntoAgentMode(
    String sourceConversationId,
    String projectId,
    CookbookEntry entry, {
    bool shellAccessEnabled = false,
  }) {
    final source = _findConversation(sourceConversationId);
    if (source == null) return;

    final now = DateTime.now();
    final conversation = ChatConversation(
      id: now.microsecondsSinceEpoch.toString(),
      title: source.title,
      createdAt: now,
      updatedAt: now,
      messages: [for (final message in source.messages) message.copyWith()],
      workingProjectId: projectId,
      shellAccessEnabled: shellAccessEnabled,
    );
    emit(state.copyWith(
      conversations: [conversation, ...state.conversations],
      activeConversationId: conversation.id,
      activeEntry: entry,
    ));
    _persist();
  }

  /// Creates a new Deep Research conversation with [entry] as its active
  /// model. Mirrors [newConversation], but sets `isDeepResearch: true` and
  /// the active entry at creation time — like `workingProjectId`,
  /// `isDeepResearch` is immutable thereafter.
  void newDeepResearchConversation(CookbookEntry entry) {
    final now = DateTime.now();
    final conversation = ChatConversation(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'New chat',
      createdAt: now,
      updatedAt: now,
      messages: const [],
      isDeepResearch: true,
    );
    emit(state.copyWith(
      conversations: [conversation, ...state.conversations],
      activeConversationId: conversation.id,
      activeEntry: entry,
    ));
    _persist();
  }

  void selectConversation(String id) {
    emit(state.copyWith(activeConversationId: id));
  }

  void selectEntry(CookbookEntry entry) {
    emit(state.copyWith(activeEntry: entry));
  }

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    final entry = state.activeEntry;
    if (entry == null) return;

    ServiceCard? card;
    for (final c in _cookbookCards) {
      if (c.id == entry.cardId) {
        card = c;
        break;
      }
    }
    if (card == null) return;

    var conversation = state.activeConversation;
    if (conversation == null) {
      final now = DateTime.now();
      conversation = ChatConversation(
        id: now.microsecondsSinceEpoch.toString(),
        title: _titleFromMessage(trimmed),
        createdAt: now,
        updatedAt: now,
        messages: const [],
      );
      emit(state.copyWith(
        conversations: [conversation, ...state.conversations],
        activeConversationId: conversation.id,
      ));
    }

    final userMessage = ChatMessage(role: ChatRole.user, content: trimmed);
    final assistantMessage = const ChatMessage(
      role: ChatRole.assistant,
      content: '',
      streaming: true,
    );

    final isFirstMessage = conversation.messages.isEmpty;
    final updatedMessages = [...conversation.messages, userMessage, assistantMessage];
    _updateConversation(
      conversation.id,
      messages: updatedMessages,
      title: isFirstMessage ? _titleFromMessage(trimmed) : null,
    );

    emit(state.copyWith(isStreaming: true));

    final history = [...conversation.messages, userMessage];
    final requestMessages = await _buildRequestMessages(history, deepResearch: conversation.isDeepResearch);
    final repo = repositoryFor(card);
    final runner = _agentLoopRunner;
    final isAgentMode =
        (conversation.workingProjectId != null || conversation.isDeepResearch) && runner != null;

    try {
      if (isAgentMode) {
        await runner.runTurn(_agentLoopContext(conversation.id, repo, entry.model), requestMessages);
      } else {
        await for (final event in repo.streamChat(model: entry.model, messages: requestMessages)) {
          switch (event) {
            case ChatStreamTextDelta(text: final text):
              _appendToLastMessage(conversation.id, text);
            case ChatStreamToolCallsRequested():
              break;
          }
        }
      }
    } catch (e) {
      _setErrorMessage(conversation.id, e);
    } finally {
      _finishStreaming(conversation.id);
      emit(state.copyWith(isStreaming: false));
      _persist();
    }
  }

  /// Approves the pending write/edit identified by [toolCallId] in
  /// [conversationId]'s last assistant message: applies it to disk via
  /// [AgentToolRepository.applyWrite], records the real result, and resumes
  /// the agent loop.
  Future<void> approveToolCall(String conversationId, String toolCallId) async {
    await _runApprovalStep(conversationId, (runner, ctx) {
      return runner.approveToolCall(ctx, toolCallId);
    });
  }

  /// Rejects the pending write/edit identified by [toolCallId]: records a
  /// "rejected by user" result without touching disk, and resumes the
  /// agent loop.
  Future<void> rejectToolCall(String conversationId, String toolCallId) async {
    await _runApprovalStep(conversationId, (runner, ctx) {
      return runner.rejectToolCall(ctx, toolCallId);
    });
  }

  /// Adds [projectId] to [conversationId]'s `trustedReferenceProjectIds`,
  /// re-attempts the tool call identified by [toolCallId], and resumes the
  /// agent loop with whatever result it now resolves to.
  Future<void> allowReferenceProject(String conversationId, String toolCallId, String projectId) async {
    await _runApprovalStep(conversationId, (runner, ctx) {
      return runner.allowReferenceProject(ctx, toolCallId, projectId);
    });
  }

  /// Records that read access to the reference project behind [toolCallId]
  /// was denied, and resumes the agent loop without granting access.
  Future<void> denyReferenceProject(String conversationId, String toolCallId, String projectId) async {
    await _runApprovalStep(conversationId, (runner, ctx) {
      return runner.denyReferenceProject(ctx, toolCallId);
    });
  }

  /// Read-only preview of what the pending tool call identified by
  /// [toolCallId] in [conversationId] would resolve to (e.g. a
  /// [ToolReferenceConfirmationNeeded] needing a project name for display),
  /// without mutating the conversation or touching disk. Returns `null` if
  /// [toolCallId] isn't a pending call, or if agent mode isn't configured.
  Future<ToolExecutionResult?> previewPendingToolCall(String conversationId, String toolCallId) async {
    final runner = _agentLoopRunner;
    final entry = state.activeEntry;
    if (runner == null || entry == null) return null;

    ServiceCard? card;
    for (final c in _cookbookCards) {
      if (c.id == entry.cardId) {
        card = c;
        break;
      }
    }
    if (card == null) return null;

    return runner.previewPendingToolCall(
      _agentLoopContext(conversationId, repositoryFor(card), entry.model),
      toolCallId,
    );
  }

  /// Shared setup for the four approval/rejection methods: resolves the
  /// conversation's active model/repository, runs [step], then settles
  /// `isStreaming` and persists.
  Future<void> _runApprovalStep(
    String conversationId,
    Future<void> Function(AgentLoopRunner runner, AgentLoopContext ctx) step,
  ) async {
    final runner = _agentLoopRunner;
    final entry = state.activeEntry;
    if (runner == null || entry == null) return;

    ServiceCard? card;
    for (final c in _cookbookCards) {
      if (c.id == entry.cardId) {
        card = c;
        break;
      }
    }
    if (card == null) return;

    emit(state.copyWith(isStreaming: true));
    try {
      await step(runner, _agentLoopContext(conversationId, repositoryFor(card), entry.model));
    } finally {
      _finishStreaming(conversationId);
      emit(state.copyWith(isStreaming: false));
      _persist();
    }
  }

  AgentLoopContext _agentLoopContext(String conversationId, ChatModelRepository repo, String model) {
    return AgentLoopContext(
      ops: AgentLoopOps(
        findConversation: _findConversation,
        updateConversation: (id, {messages, trustedReferenceProjectIds}) => _updateConversation(
          id,
          messages: messages,
          trustedReferenceProjectIds: trustedReferenceProjectIds,
        ),
        persist: _persist,
      ),
      conversationId: conversationId,
      repo: repo,
      model: model,
      appendToLastMessage: _appendToLastMessage,
      buildRequestMessages: (history) => _buildRequestMessages(
        history,
        deepResearch: _findConversation(conversationId)?.isDeepResearch ?? false,
      ),
    );
  }

  Future<List<ChatMessage>> _buildRequestMessages(
    List<ChatMessage> history, {
    bool deepResearch = false,
  }) async {
    final systemPrompt = await brainRepository.buildSystemPrompt();
    final systemParts = [
      if (systemPrompt != null) systemPrompt,
      if (deepResearch) kDeepResearchSystemPromptAddition,
    ];
    return systemParts.isNotEmpty
        ? [ChatMessage(role: ChatRole.system, content: systemParts.join('\n\n')), ...history]
        : history;
  }

  /// Replaces the content of the last (assistant) message with a short,
  /// user-facing error notice. Called when [sendMessage]'s `streamChat()`
  /// loop throws (e.g. the underlying repository's stream emits an error
  /// from a failed HTTP request) — surfaces the failure in the conversation
  /// instead of leaving the message stuck on "generating..." or letting the
  /// exception propagate out of `sendMessage()` unhandled.
  ///
  /// If [error] is a [ChatRequestException], its message (extracted from the
  /// provider's own error response, e.g. "Your credit balance is too low")
  /// is included so the user knows what actually went wrong.
  void _setErrorMessage(String conversationId, Object error) {
    final conversation = _findConversation(conversationId);
    if (conversation == null) return;
    final messages = [...conversation.messages];
    if (messages.isEmpty) return;
    final last = messages.last;
    if (last.role == ChatRole.assistant) {
      final detail = error is ChatRequestException ? ' (${error.message})' : '';
      messages[messages.length - 1] = last.copyWith(
        content: '⚠️ Something went wrong while generating a response.$detail Please try again.',
      );
    }
    _updateConversation(conversationId, messages: messages);
  }

  void _appendToLastMessage(String conversationId, String chunk) {
    final conversation = _findConversation(conversationId);
    if (conversation == null) return;
    final messages = [...conversation.messages];
    final last = messages.last;
    messages[messages.length - 1] = last.copyWith(content: last.content + chunk);
    _updateConversation(conversationId, messages: messages);
  }

  void _finishStreaming(String conversationId) {
    final conversation = _findConversation(conversationId);
    if (conversation == null) return;
    final messages = [...conversation.messages];
    if (messages.isEmpty) return;
    final last = messages.last;
    if (last.role == ChatRole.assistant) {
      messages[messages.length - 1] = last.copyWith(streaming: false);
    }
    _updateConversation(conversationId, messages: messages);
  }

  ChatConversation? _findConversation(String id) {
    for (final conversation in state.conversations) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  void _updateConversation(
    String id, {
    List<ChatMessage>? messages,
    String? title,
    List<String>? trustedReferenceProjectIds,
  }) {
    final now = DateTime.now();
    final conversations = [
      for (final conversation in state.conversations)
        if (conversation.id == id)
          conversation.copyWith(
            messages: messages,
            title: title,
            updatedAt: now,
            trustedReferenceProjectIds: trustedReferenceProjectIds,
          )
        else
          conversation,
    ];
    emit(state.copyWith(conversations: conversations));
  }

  Future<void> _persist() async {
    await conversationsRepository.saveConversations(state.conversations);
  }

  String _titleFromMessage(String content) {
    final singleLine = content.replaceAll('\n', ' ').trim();
    if (singleLine.length <= 40) return singleLine;
    return '${singleLine.substring(0, 40)}...';
  }
}
