import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/chat_controller.dart';
import '../../domain/model/chat_conversation.dart';
import '../helpers/agent_mode_flow.dart';

/// Header control showing whether the active conversation is a plain "Chat"
/// or an "Agent" (mode + working project) conversation, and letting the user
/// start a new conversation in the other mode.
///
/// `workingProjectId` is immutable per conversation (see issue 009) — this
/// toggle never changes [conversation]'s own mode, it only starts new
/// conversations.
class ChatModeToggle extends StatelessWidget {
  final ChatController controller;
  final ChatConversation? conversation;

  const ChatModeToggle({super.key, required this.controller, required this.conversation});

  @override
  Widget build(BuildContext context) {
    final workingProjectId = conversation?.workingProjectId;
    final isAgentMode = workingProjectId != null;
    final isDeepResearch = conversation?.isDeepResearch ?? false;
    final isChatMode = !isAgentMode && !isDeepResearch;

    return Container(
      padding: const EdgeInsets.all(AppStyling.spaceXs),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeSegment(
            label: 'Chat',
            selected: isChatMode,
            onTap: isChatMode ? null : controller.newConversation,
          ),
          const SizedBox(width: AppStyling.spaceXs),
          if (isAgentMode)
            _AgentSegment(
              controller: controller,
              workingProjectId: workingProjectId,
              shellAccessEnabled: conversation?.shellAccessEnabled ?? false,
            )
          else
            _ModeSegment(
              label: 'Agent',
              selected: false,
              onTap: () => startNewAgentChat(context, controller),
            ),
          const SizedBox(width: AppStyling.spaceXs),
          _ModeSegment(
            label: 'Research',
            selected: isDeepResearch,
            onTap: isDeepResearch ? null : () => startNewDeepResearchChat(controller),
          ),
        ],
      ),
    );
  }
}

class _AgentSegment extends StatelessWidget {
  final ChatController controller;
  final String workingProjectId;
  final bool shellAccessEnabled;

  const _AgentSegment({
    required this.controller,
    required this.workingProjectId,
    required this.shellAccessEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: workingProjectName(controller, workingProjectId),
      builder: (context, snapshot) {
        final projectName = snapshot.data;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeSegment(
              label: projectName != null ? 'Agent · $projectName' : 'Agent',
              selected: true,
              onTap: null,
            ),
            if (shellAccessEnabled) ...[
              const SizedBox(width: AppStyling.spaceXs),
              const Icon(
                Icons.terminal,
                size: 16,
                color: AppColors.accentLight,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ModeSegment({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceMd,
          vertical: AppStyling.spaceXs,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentBg : Colors.transparent,
          borderRadius: BorderRadius.circular(AppStyling.radiusSm),
          border: selected ? Border.all(color: AppColors.accentLine) : null,
        ),
        child: Text(
          label,
          style: AppStyling.bodySm.copyWith(
            color: selected ? AppColors.accentLight : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
