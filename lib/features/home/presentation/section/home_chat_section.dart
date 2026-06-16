import 'package:flutter/material.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/chat_controller.dart';
import '../../domain/model/agent_loop_constants.dart';
import '../../domain/model/cookbook_entry.dart';
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
  final bool compact;

  const HomeChatSection({super.key, required this.controller, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return StreamStateBuilder<ChatStateData>(
      state: controller,
      builder: (context, state) {
        if (compact) return _CompactLayout(controller: controller, state: state);

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

class _CompactLayout extends StatefulWidget {
  final ChatController controller;
  final ChatStateData state;

  const _CompactLayout({required this.controller, required this.state});

  @override
  State<_CompactLayout> createState() => _CompactLayoutState();
}

class _CompactLayoutState extends State<_CompactLayout> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty || widget.state.isStreaming) return;
    widget.controller.sendMessage(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final conversation = widget.state.activeConversation;
    final hasMessages = conversation != null && conversation.messages.isNotEmpty;

    return Container(
      color: AppColors.surfaceElevated,
      child: Column(
        children: [
          SizedBox(
            height: 32,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceMd),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: _ChatModelPill(
                      entries: widget.state.cookbook,
                      activeEntry: widget.state.activeEntry,
                      onSelect: widget.controller.selectEntry,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: AppColors.border),
          Expanded(
            child: hasMessages
                ? _MessageList(controller: widget.controller, conversation: conversation)
                : Center(
                    child: Text(
                      'Ask anything',
                      style: AppStyling.bodySm.copyWith(color: AppColors.textFaint),
                    ),
                  ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.all(AppStyling.spaceSm),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyling.spaceSm,
                vertical: AppStyling.spaceXs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppStyling.radiusMd),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: AppStyling.bodySm,
                      maxLines: 1,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Message Avyn…',
                        hintStyle: AppStyling.bodySm.copyWith(color: AppColors.textFaint),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: AppStyling.spaceXs),
                  GestureDetector(
                    onTap: _submit,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppStyling.radiusSm),
                      ),
                      child: const Icon(Icons.send_rounded, size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatModelPill extends StatelessWidget {
  final List<CookbookEntry> entries;
  final CookbookEntry? activeEntry;
  final ValueChanged<CookbookEntry> onSelect;

  const _ChatModelPill({
    required this.entries,
    required this.activeEntry,
    required this.onSelect,
  });

  void _showMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomLeft = box.localToGlobal(Offset(0, box.size.height), ancestor: overlay);

    final selected = await showMenu<CookbookEntry>(
      context: context,
      position: RelativeRect.fromLTRB(
        topLeft.dx,
        bottomLeft.dy + 4,
        overlay.size.width - topLeft.dx - box.size.width,
        0,
      ),
      color: AppColors.surfaceElevated,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      items: [
        for (final entry in entries)
          PopupMenuItem<CookbookEntry>(
            value: entry,
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyling.spaceMd,
              vertical: AppStyling.spaceSm,
            ),
            child: Text(
              '${entry.model} — ${entry.cardName}',
              style: AppStyling.bodySm.copyWith(
                color: entry == activeEntry ? AppColors.accentLight : AppColors.textPrimary,
              ),
            ),
          ),
      ],
    );
    if (selected != null) onSelect(selected);
  }

  @override
  Widget build(BuildContext context) {
    final label = activeEntry != null
        ? '${activeEntry!.model} — ${activeEntry!.cardName}'
        : 'Select model';

    return GestureDetector(
      onTap: entries.isEmpty ? null : () => _showMenu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceSm,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppStyling.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: AppStyling.label.copyWith(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppStyling.spaceXs),
            const Icon(Icons.expand_more_rounded, size: 12, color: AppColors.textSecondary),
          ],
        ),
      ),
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
