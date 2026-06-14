import '../model/agent_loop_constants.dart';
import '../model/agent_tools.dart';
import '../model/chat_conversation.dart';
import '../model/chat_message.dart';
import '../model/chat_stream_event.dart';
import '../model/tool_call.dart';
import '../model/tool_definition.dart';
import '../model/tool_execution_result.dart';
import '../repository/agent_tool_repository.dart';
import '../repository/chat_model_repository.dart';
import '../repository/command_execution_repository.dart';
import '../repository/fetch_page_repository.dart';
import '../repository/web_search_repository.dart';
import 'package:crm/features/settings/domain/model/project.dart';
import 'package:crm/features/settings/domain/repository/projects_repository.dart';

/// Mutation/persistence hooks the [AgentLoopRunner] needs from
/// [ChatController], without depending on the controller's [StreamState]
/// directly.
class AgentLoopOps {
  final ChatConversation? Function(String conversationId) findConversation;
  final void Function(
    String conversationId, {
    List<ChatMessage>? messages,
    List<String>? trustedReferenceProjectIds,
  }) updateConversation;
  final Future<void> Function() persist;

  const AgentLoopOps({
    required this.findConversation,
    required this.updateConversation,
    required this.persist,
  });
}

/// Everything [AgentLoopRunner] needs to stream a turn and mutate a
/// conversation's messages, bundled to keep method signatures short.
class AgentLoopContext {
  final AgentLoopOps ops;
  final String conversationId;
  final ChatModelRepository repo;
  final String model;
  final void Function(String conversationId, String chunk) appendToLastMessage;
  final Future<List<ChatMessage>> Function(List<ChatMessage> history) buildRequestMessages;

  const AgentLoopContext({
    required this.ops,
    required this.conversationId,
    required this.repo,
    required this.model,
    required this.appendToLastMessage,
    required this.buildRequestMessages,
  });
}

/// Runs the agent-mode tool-call loop for [ChatController.sendMessage] and
/// the approval/rejection follow-up methods.
///
/// Resolves the working/reference/registered project paths once per
/// top-level call (no caching across calls), executes [ToolCall]s via
/// [AgentToolRepository], appends `tool`-role result messages, and
/// re-invokes [ChatModelRepository.streamChat] until a turn returns a
/// final text-only response, a write/reference proposal is left pending,
/// or [kMaxAgentLoopSteps] round-trips have been made.
class AgentLoopRunner {
  final AgentToolRepository agentToolRepository;
  final ProjectsRepository projectsRepository;
  final WebSearchRepository? webSearchRepository;
  final CommandExecutionRepository? commandExecutionRepository;
  final FetchPageRepository? fetchPageRepository;

  AgentLoopRunner({
    required this.agentToolRepository,
    required this.projectsRepository,
    this.webSearchRepository,
    this.commandExecutionRepository,
    this.fetchPageRepository,
  });

  /// Streams one turn (text-delta + possible tool-calls-requested) and, if
  /// tool calls were requested, runs the agent loop until it stalls
  /// (final text, pending approval, or step limit).
  Future<void> runTurn(AgentLoopContext ctx, List<ChatMessage> requestMessages) async {
    await for (final event in ctx.repo.streamChat(
      model: ctx.model,
      messages: requestMessages,
      tools: _toolsFor(ctx),
    )) {
      switch (event) {
        case ChatStreamTextDelta(text: final text):
          ctx.appendToLastMessage(ctx.conversationId, text);
        case ChatStreamToolCallsRequested(toolCalls: final toolCalls):
          _finalizeAssistantToolCalls(ctx, toolCalls);
          await _processPendingToolCalls(ctx, toolCalls);
          await _continueIfReady(ctx, stepsSoFar: 1);
          return;
      }
    }
  }

  /// Approves the pending write/edit identified by [toolCallId]: applies it
  /// via [AgentToolRepository.applyWrite], records the real result, and
  /// resumes the loop if all calls in the turn are now answered.
  Future<void> approveToolCall(AgentLoopContext ctx, String toolCallId) async {
    final call = _findPendingToolCall(ctx, toolCallId);
    if (call == null) return;

    final result = await _executeWithResolvedPaths(ctx, call);
    final applied = switch (result) {
      ToolWriteProposal(preview: CommandExecution()) => await _applyRunCommand(result),
      ToolWriteProposal() => await agentToolRepository.applyWrite(result),
      _ => result,
    };

    await _appendToolResultMessage(ctx, call, applied);
    await _continueIfReady(ctx, stepsSoFar: 1);
  }

  Future<ToolExecutionResult> _applyRunCommand(ToolWriteProposal proposal) async {
    final commandExecutionRepository = this.commandExecutionRepository;
    if (commandExecutionRepository == null) {
      return const ToolError('Command execution is not configured.');
    }
    final preview = proposal.preview as CommandExecution;
    return commandExecutionRepository.run(preview.command, workingDirectory: preview.cwd);
  }

  /// Rejects the pending write/edit identified by [toolCallId]: records a
  /// "rejected by user" result without touching disk, and resumes the loop.
  Future<void> rejectToolCall(AgentLoopContext ctx, String toolCallId) async {
    final call = _findPendingToolCall(ctx, toolCallId);
    if (call == null) return;

    await _appendToolMessage(ctx, call, 'User rejected this change.');
    await _continueIfReady(ctx, stepsSoFar: 1);
  }

  /// Trusts [projectId] for the rest of this conversation, re-attempts the
  /// tool call identified by [toolCallId] (now permitted), and resumes the
  /// loop with whatever result it now resolves to.
  Future<void> allowReferenceProject(AgentLoopContext ctx, String toolCallId, String projectId) async {
    final call = _findPendingToolCall(ctx, toolCallId);
    if (call == null) return;

    final conversation = ctx.ops.findConversation(ctx.conversationId);
    if (conversation == null) return;
    if (!conversation.trustedReferenceProjectIds.contains(projectId)) {
      ctx.ops.updateConversation(
        ctx.conversationId,
        trustedReferenceProjectIds: [...conversation.trustedReferenceProjectIds, projectId],
      );
      await ctx.ops.persist();
    }

    final result = await _executeWithResolvedPaths(ctx, call);

    switch (result) {
      case ToolOutput() || ToolError():
        await _appendToolResultMessage(ctx, call, result);
        await _continueIfReady(ctx, stepsSoFar: 1);
      case ToolWriteProposal() || ToolReferenceConfirmationNeeded():
        // Leave pending again — awaiting a further approval decision.
        await ctx.ops.persist();
    }
  }

  /// Read-only preview of what the pending call identified by [toolCallId]
  /// would resolve to, without mutating the conversation or touching disk.
  /// Returns `null` if [toolCallId] isn't a pending call in the last
  /// assistant message.
  ///
  /// Used by the UI to distinguish a pending [ToolWriteProposal] from a
  /// pending [ToolReferenceConfirmationNeeded] (e.g. to look up the
  /// reference project's name) when re-rendering persisted conversation
  /// state.
  Future<ToolExecutionResult?> previewPendingToolCall(AgentLoopContext ctx, String toolCallId) async {
    final call = _findPendingToolCall(ctx, toolCallId);
    if (call == null) return null;
    return _executeWithResolvedPaths(ctx, call);
  }

  /// Records that read access to the reference project behind [toolCallId]
  /// was denied, and resumes the loop without granting access.
  Future<void> denyReferenceProject(AgentLoopContext ctx, String toolCallId) async {
    final call = _findPendingToolCall(ctx, toolCallId);
    if (call == null) return;

    await _appendToolMessage(ctx, call, 'User denied read access to this project.');
    await _continueIfReady(ctx, stepsSoFar: 1);
  }

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  /// The tool list to offer the model for [ctx]'s conversation:
  /// [kDeepResearchTools] for Deep Research conversations, otherwise
  /// [kAgentTools] plus [kRunCommandTool] when the conversation has
  /// `shellAccessEnabled`.
  List<ToolDefinition> _toolsFor(AgentLoopContext ctx) {
    final conversation = ctx.ops.findConversation(ctx.conversationId);
    if (conversation?.isDeepResearch ?? false) {
      return kDeepResearchTools;
    }
    if (conversation?.shellAccessEnabled ?? false) {
      return [...kAgentTools, kRunCommandTool];
    }
    return kAgentTools;
  }

  Future<ToolExecutionResult> _executeWithResolvedPaths(AgentLoopContext ctx, ToolCall call) async {
    if (call.name == 'web_search') {
      return _executeWebSearch(call);
    }
    if (call.name == 'fetch_page') {
      return _executeFetchPage(call);
    }
    if (call.name == 'run_command') {
      final conversation = ctx.ops.findConversation(ctx.conversationId);
      if (!(conversation?.shellAccessEnabled ?? false)) {
        return const ToolError('Shell access is not enabled for this conversation.');
      }
      final paths = await _resolveProjectPaths(ctx);
      return _executeRunCommand(call, paths.workingProjectPath);
    }

    final paths = await _resolveProjectPaths(ctx);
    return agentToolRepository.execute(
      call,
      workingProjectPath: paths.workingProjectPath,
      trustedReferenceProjectPaths: paths.trustedReferenceProjectPaths,
      registeredProjectPaths: paths.registeredProjectPaths,
    );
  }

  /// A `run_command` call always resolves to a pending [ToolWriteProposal]
  /// with a [CommandExecution] preview — it never auto-executes.
  Future<ToolExecutionResult> _executeRunCommand(ToolCall call, String workingProjectPath) async {
    final command = call.arguments['command'] as String? ?? '';
    return ToolWriteProposal(workingProjectPath, CommandExecution(command, workingProjectPath));
  }

  Future<ToolExecutionResult> _executeWebSearch(ToolCall call) async {
    final webSearchRepository = this.webSearchRepository;
    if (webSearchRepository == null) {
      return const ToolError(
        'Web search is not configured. Add a SearXNG service in Settings → Services.',
      );
    }

    final query = call.arguments['query'] as String? ?? '';
    final count = call.arguments['count'] as int?;
    return webSearchRepository.search(query, count: count);
  }

  Future<ToolExecutionResult> _executeFetchPage(ToolCall call) async {
    final fetchPageRepository = this.fetchPageRepository;
    if (fetchPageRepository == null) {
      return const ToolError('Page fetching is not configured.');
    }

    final url = call.arguments['url'] as String? ?? '';
    return fetchPageRepository.fetch(url);
  }

  void _finalizeAssistantToolCalls(AgentLoopContext ctx, List<ToolCall> toolCalls) {
    final conversation = ctx.ops.findConversation(ctx.conversationId);
    if (conversation == null) return;
    final messages = [...conversation.messages];
    if (messages.isEmpty) return;
    final last = messages.last;
    if (last.role != ChatRole.assistant) return;
    messages[messages.length - 1] = last.copyWith(
      toolCalls: toolCalls,
      streaming: false,
    );
    ctx.ops.updateConversation(ctx.conversationId, messages: messages);
  }

  /// Executes each requested [toolCalls] in order via
  /// [AgentToolRepository.execute], appending `tool`-role result messages
  /// for [ToolOutput]/[ToolError]. Stops at the first
  /// [ToolWriteProposal]/[ToolReferenceConfirmationNeeded], leaving it and
  /// any remaining calls unanswered (pending).
  Future<void> _processPendingToolCalls(AgentLoopContext ctx, List<ToolCall> toolCalls) async {
    for (final call in toolCalls) {
      final result = await _executeWithResolvedPaths(ctx, call);

      switch (result) {
        case ToolOutput() || ToolError():
          await _appendToolResultMessage(ctx, call, result);
        case ToolWriteProposal() || ToolReferenceConfirmationNeeded():
          await ctx.ops.persist();
          return;
      }
    }
  }

  /// If every tool call in the last assistant message's `toolCalls` now has
  /// a corresponding `tool`-role answer, re-invokes [streamChat] and repeats
  /// the loop (up to [kMaxAgentLoopSteps] total round-trips, or
  /// [kMaxDeepResearchSteps] for Deep Research conversations).
  Future<void> _continueIfReady(AgentLoopContext ctx, {required int stepsSoFar}) async {
    if (!_allToolCallsAnswered(ctx)) return;

    final conversation = ctx.ops.findConversation(ctx.conversationId);
    if (conversation == null) return;
    final isDeepResearch = conversation.isDeepResearch;
    final maxSteps = isDeepResearch ? kMaxDeepResearchSteps : kMaxAgentLoopSteps;

    if (stepsSoFar >= maxSteps) {
      await _appendNotice(
        ctx,
        isDeepResearch
            ? 'Reached the research step limit ($kMaxDeepResearchSteps round-trips) before '
                'reaching a conclusion. Here is a best-effort summary based on the sources '
                'gathered so far.'
            : 'Stopped after $kMaxAgentLoopSteps tool-call round-trips without a final response. '
                'You can continue the conversation to pick up from here.',
      );
      return;
    }

    // Start a new assistant message for the next turn.
    final history = conversation.messages;
    final requestMessages = await ctx.buildRequestMessages(history);
    ctx.ops.updateConversation(ctx.conversationId, messages: [
      ...history,
      const ChatMessage(role: ChatRole.assistant, content: '', streaming: true),
    ]);

    var producedToolCalls = false;
    await for (final event in ctx.repo.streamChat(
      model: ctx.model,
      messages: requestMessages,
      tools: _toolsFor(ctx),
    )) {
      switch (event) {
        case ChatStreamTextDelta(text: final text):
          ctx.appendToLastMessage(ctx.conversationId, text);
        case ChatStreamToolCallsRequested(toolCalls: final toolCalls):
          producedToolCalls = true;
          _finalizeAssistantToolCalls(ctx, toolCalls);
          await _processPendingToolCalls(ctx, toolCalls);
      }
    }

    if (!producedToolCalls) {
      _finishStreaming(ctx);
      await ctx.ops.persist();
      return;
    }

    await _continueIfReady(ctx, stepsSoFar: stepsSoFar + 1);
  }

  void _finishStreaming(AgentLoopContext ctx) {
    final conversation = ctx.ops.findConversation(ctx.conversationId);
    if (conversation == null) return;
    final messages = [...conversation.messages];
    if (messages.isEmpty) return;
    final last = messages.last;
    if (last.role == ChatRole.assistant) {
      messages[messages.length - 1] = last.copyWith(streaming: false);
    }
    ctx.ops.updateConversation(ctx.conversationId, messages: messages);
  }

  Future<void> _appendNotice(AgentLoopContext ctx, String text) async {
    final conversation = ctx.ops.findConversation(ctx.conversationId);
    if (conversation == null) return;
    ctx.ops.updateConversation(ctx.conversationId, messages: [
      ...conversation.messages,
      ChatMessage(role: ChatRole.assistant, content: text),
    ]);
    await ctx.ops.persist();
  }

  Future<void> _appendToolResultMessage(AgentLoopContext ctx, ToolCall call, ToolExecutionResult result) async {
    final text = switch (result) {
      ToolOutput(text: final t) => t,
      ToolError(message: final m) => m,
      _ => '',
    };
    await _appendToolMessage(ctx, call, text);
  }

  Future<void> _appendToolMessage(AgentLoopContext ctx, ToolCall call, String content) async {
    final conversation = ctx.ops.findConversation(ctx.conversationId);
    if (conversation == null) return;
    ctx.ops.updateConversation(ctx.conversationId, messages: [
      ...conversation.messages,
      ChatMessage(
        role: ChatRole.tool,
        content: content,
        toolCallId: call.id,
        toolName: call.name,
      ),
    ]);
    await ctx.ops.persist();
  }

  /// Whether the last `assistant` message's `toolCalls` (if any) each have a
  /// following `tool`-role message answering their `id`.
  bool _allToolCallsAnswered(AgentLoopContext ctx) {
    final conversation = ctx.ops.findConversation(ctx.conversationId);
    if (conversation == null) return false;
    final messages = conversation.messages;

    ChatMessage? lastAssistant;
    for (final message in messages) {
      if (message.role == ChatRole.assistant && message.toolCalls.isNotEmpty) {
        lastAssistant = message;
      }
    }
    if (lastAssistant == null || lastAssistant.toolCalls.isEmpty) return false;

    final answeredIds = messages
        .where((m) => m.role == ChatRole.tool && m.toolCallId != null)
        .map((m) => m.toolCallId)
        .toSet();

    return lastAssistant.toolCalls.every((call) => answeredIds.contains(call.id));
  }

  /// Finds [toolCallId] among the last `assistant` message's `toolCalls`,
  /// if it's still unanswered (pending).
  ToolCall? _findPendingToolCall(AgentLoopContext ctx, String toolCallId) {
    final conversation = ctx.ops.findConversation(ctx.conversationId);
    if (conversation == null) return null;
    final messages = conversation.messages;

    ChatMessage? lastAssistant;
    for (final message in messages) {
      if (message.role == ChatRole.assistant && message.toolCalls.isNotEmpty) {
        lastAssistant = message;
      }
    }
    if (lastAssistant == null) return null;

    for (final call in lastAssistant.toolCalls) {
      if (call.id != toolCallId) continue;
      final answered = messages.any((m) => m.role == ChatRole.tool && m.toolCallId == call.id);
      if (answered) return null;
      return call;
    }
    return null;
  }

  Future<_ProjectPaths> _resolveProjectPaths(AgentLoopContext ctx) async {
    final conversation = ctx.ops.findConversation(ctx.conversationId);
    final allProjects = await projectsRepository.getProjects();

    final workingProjectPath = allProjects
        .firstWhere(
          (p) => p.id == conversation?.workingProjectId,
          orElse: () => const Project(
            id: '',
            name: '',
            localPath: '',
            projectKey: '',
            hasBugReports: false,
            hasAnnouncements: false,
          ),
        )
        .localPath;

    final trustedIds = conversation?.trustedReferenceProjectIds ?? const [];
    final trustedReferenceProjectPaths = allProjects
        .where((p) => trustedIds.contains(p.id))
        .map((p) => p.localPath)
        .toList();

    final registeredProjectPaths = {for (final p in allProjects) p.localPath: p.id};

    return _ProjectPaths(
      workingProjectPath: workingProjectPath,
      trustedReferenceProjectPaths: trustedReferenceProjectPaths,
      registeredProjectPaths: registeredProjectPaths,
    );
  }
}

class _ProjectPaths {
  final String workingProjectPath;
  final List<String> trustedReferenceProjectPaths;
  final Map<String, String> registeredProjectPaths;

  const _ProjectPaths({
    required this.workingProjectPath,
    required this.trustedReferenceProjectPaths,
    required this.registeredProjectPaths,
  });
}
