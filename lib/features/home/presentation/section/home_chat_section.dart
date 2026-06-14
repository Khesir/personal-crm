import 'package:flutter/material.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/chat_controller.dart';
import '../../domain/model/agent_loop_constants.dart';
import '../../domain/model/chat_conversation.dart';
import '../../domain/model/chat_message.dart';
import '../state/chat_state.dart';
import '../widget/chat_message_bubble.dart';
import '../widget/chat_mode_toggle.dart';
import '../widget/composer.dart';
import '../widget/model_switcher.dart';
import '../widget/suggested_prompt_chip.dart';
import 'agent_step_list.dart';

const _suggestedPrompts = [
  'Summarize this codebase',
  'Help me debug an error',
  'Write a commit message',
  'Explain this concept',
];

class HomeChatSection extends StatelessWidget {
  final ChatController controller;

  const HomeChatSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StreamStateBuilder<ChatStateData>(
      state: controller,
      builder: (context, state) {
        final conversation = state.activeConversation;
        final hasMessages = conversation != null && conversation.messages.isNotEmpty;

        return Container(
          color: AppColors.background,
          child: Column(
            children: [
              _Header(
                title: conversation?.title ?? 'New chat',
                state: state,
                controller: controller,
              ),
              Container(height: 1, color: AppColors.border),
              Expanded(
                child: hasMessages
                    ? _MessageList(controller: controller, conversation: conversation)
                    : _EmptyState(controller: controller, state: state),
              ),
              if (hasMessages)
                Padding(
                  padding: const EdgeInsets.all(AppStyling.spaceLg),
                  child: Composer(
                    activeModel: state.activeEntry?.model,
                    isStreaming: state.isStreaming,
                    onSend: controller.sendMessage,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final ChatStateData state;
  final ChatController controller;

  const _Header({required this.title, required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppStyling.spaceLg),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyling.pageTitle,
            ),
          ),
          if (kAgentModeEnabled) ...[
            const SizedBox(width: AppStyling.spaceMd),
            ChatModeToggle(controller: controller, conversation: state.activeConversation),
          ],
          const SizedBox(width: AppStyling.spaceMd),
          ModelSwitcher(
            entries: state.cookbook,
            activeEntry: state.activeEntry,
            onSelect: controller.selectEntry,
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  final ChatController controller;
  final ChatConversation conversation;

  const _MessageList({required this.controller, required this.conversation});

  @override
  Widget build(BuildContext context) {
    final messages = conversation.messages;
    final showStepCards = kAgentModeEnabled &&
        (conversation.workingProjectId != null || conversation.isDeepResearch);

    return ListView(
      padding: const EdgeInsets.all(AppStyling.spaceLg),
      children: [
        for (final message in messages) ...[
          if (message.role == ChatRole.user)
            UserMsg(content: message.content)
          else if (message.role == ChatRole.assistant) ...[
            if (showStepCards && message.toolCalls.isNotEmpty) ...[
              AgentStepList(
                controller: controller,
                conversationId: conversation.id,
                conversationMessages: messages,
                message: message,
              ),
              if (message.content.isNotEmpty)
                BotMsg(content: message.content, streaming: message.streaming),
            ] else
              BotMsg(content: message.content, streaming: message.streaming),
          ],
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ChatController controller;
  final ChatStateData state;

  const _EmptyState({required this.controller, required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(AppStyling.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Assistant', style: AppStyling.displayMd),
              const SizedBox(height: AppStyling.spaceSm),
              Text(
                'Chat with your configured models — local or API.',
                textAlign: TextAlign.center,
                style: AppStyling.pageSub,
              ),
              const SizedBox(height: AppStyling.spaceXl),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppStyling.spaceSm,
                runSpacing: AppStyling.spaceSm,
                children: [
                  for (final prompt in _suggestedPrompts)
                    SuggestedPromptChip(
                      label: prompt,
                      onTap: () => controller.sendMessage(prompt),
                    ),
                ],
              ),
              const SizedBox(height: AppStyling.spaceXl),
              Composer(
                activeModel: state.activeEntry?.model,
                isStreaming: state.isStreaming,
                onSend: controller.sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
