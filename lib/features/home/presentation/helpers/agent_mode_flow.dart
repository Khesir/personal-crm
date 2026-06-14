import 'package:flutter/material.dart';
import 'package:crm/features/settings/domain/model/project.dart';
import '../../domain/controller/chat_controller.dart';
import '../../domain/model/agent_loop_constants.dart';
import '../../domain/model/cookbook_entry.dart';
import '../dialogs/agent_mode_picker_dialog.dart';
import '../dialogs/new_chat_dialog.dart';

/// Cookbook entries filtered to those that support tool calling, i.e. the
/// only entries selectable for an agent-mode conversation.
List<CookbookEntry> agentCapableCookbook(ChatController controller) {
  return controller.state.cookbook.where((e) => e.supportsTools).toList();
}

/// Drives the "New chat" flow: shows [NewChatDialog], and either starts a
/// plain conversation or (if Agent mode was enabled and a project/model was
/// picked) an agent-mode conversation.
Future<void> startNewChat(BuildContext context, ChatController controller) async {
  if (!kAgentModeEnabled) {
    controller.newConversation();
    return;
  }

  final projectsRepository = controller.projectsRepository;
  final projects = projectsRepository != null
      ? await projectsRepository.getProjects()
      : const <Project>[];
  if (!context.mounted) return;

  final selection = await NewChatDialog.show(
    context,
    projects: projects,
    agentCapableCookbook: agentCapableCookbook(controller),
  );
  if (selection == null) return;

  final agentSelection = selection.agentModeSelection;
  if (selection.agentMode && agentSelection != null) {
    controller.newAgentConversation(
      agentSelection.project.id,
      agentSelection.entry,
      shellAccessEnabled: agentSelection.shellAccessEnabled,
    );
  } else if (!selection.agentMode) {
    controller.newConversation();
  }
}

/// Drives the "Branch into agent mode" flow: shows [AgentModePickerDialog]
/// and, if a project/model is picked, branches [sourceConversationId] into a
/// new agent-mode conversation.
Future<void> branchIntoAgentMode(
  BuildContext context,
  ChatController controller,
  String sourceConversationId,
) async {
  final projectsRepository = controller.projectsRepository;
  final projects = projectsRepository != null
      ? await projectsRepository.getProjects()
      : const <Project>[];
  if (!context.mounted) return;

  final selection = await AgentModePickerDialog.show(
    context,
    projects: projects,
    cookbook: agentCapableCookbook(controller),
  );
  if (selection == null) return;

  controller.branchIntoAgentMode(
    sourceConversationId,
    selection.project.id,
    selection.entry,
    shellAccessEnabled: selection.shellAccessEnabled,
  );
}

/// Drives the header mode toggle's "Agent" tap from a plain conversation:
/// shows [AgentModePickerDialog] directly (skipping [NewChatDialog]'s
/// initial switch, since the user already chose "Agent" by tapping the
/// toggle) and, if a project/model is picked, starts a new agent-mode
/// conversation.
Future<void> startNewAgentChat(BuildContext context, ChatController controller) async {
  final projectsRepository = controller.projectsRepository;
  final projects = projectsRepository != null
      ? await projectsRepository.getProjects()
      : const <Project>[];
  if (!context.mounted) return;

  final selection = await AgentModePickerDialog.show(
    context,
    projects: projects,
    cookbook: agentCapableCookbook(controller),
  );
  if (selection == null) return;

  controller.newAgentConversation(
    selection.project.id,
    selection.entry,
    shellAccessEnabled: selection.shellAccessEnabled,
  );
}

/// Drives the header mode toggle's "Research" tap: starts a new Deep
/// Research conversation using the local model that best fits the user's
/// hardware among tool-capable entries (see issue 020's
/// `recommendedCookbookEntry`), falling back to the first tool-capable entry.
/// Does nothing if no tool-capable model is available.
void startNewDeepResearchChat(ChatController controller) {
  final cookbook = agentCapableCookbook(controller);
  final entry = recommendedCookbookEntry(cookbook) ?? (cookbook.isNotEmpty ? cookbook.first : null);
  if (entry == null) return;

  controller.newDeepResearchConversation(entry);
}

/// Looks up [projectId]'s display name among the user's registered projects,
/// for the header mode toggle's "Agent · ProjectName" label. Returns `null`
/// if [projectId] isn't found or no [ProjectsRepository] is configured.
Future<String?> workingProjectName(ChatController controller, String projectId) async {
  final projectsRepository = controller.projectsRepository;
  if (projectsRepository == null) return null;
  final projects = await projectsRepository.getProjects();
  for (final project in projects) {
    if (project.id == projectId) return project.name;
  }
  return null;
}
