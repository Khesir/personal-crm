import 'package:flutter/material.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/chat_controller.dart';
import '../../domain/model/chat_message.dart';
import '../state/chat_state.dart';
import '../widget/chat_message_bubble.dart';
import '../widget/composer.dart';
import '../widget/model_switcher.dart';
import '../widget/suggested_prompt_chip.dart';

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
                    ? _MessageList(messages: conversation.messages)
                    : _EmptyState(controller: controller, state: state),
              ),
              if (hasMessages)
                Padding(
                  padding: const EdgeInsets.all(AppStyling.spaceLg),
                  child: Composer(
                    activeModel: state.activeModel,
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
          const SizedBox(width: AppStyling.spaceMd),
          ModelSwitcher(
            models: state.availableModels,
            activeModel: state.activeModel,
            onSelect: controller.selectModel,
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  final List<ChatMessage> messages;

  const _MessageList({required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppStyling.spaceLg),
      children: [
        for (final message in messages)
          message.role == ChatRole.user
              ? UserMsg(content: message.content)
              : BotMsg(content: message.content, streaming: message.streaming),
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
              Text('Local assistant', style: AppStyling.displayMd),
              const SizedBox(height: AppStyling.spaceSm),
              Text(
                'Chat privately with a local Ollama model. Nothing leaves this machine.',
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
                activeModel: state.activeModel,
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
