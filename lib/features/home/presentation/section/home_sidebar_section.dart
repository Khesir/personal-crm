import 'package:flutter/material.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/chat_controller.dart';
import '../helpers/relative_time.dart';
import '../state/chat_state.dart';

class HomeSidebarSection extends StatelessWidget {
  final ChatController controller;

  const HomeSidebarSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StreamStateBuilder<ChatStateData>(
      state: controller,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppStyling.spaceMd),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.newConversation,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('New chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: AppStyling.spaceSm),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppStyling.spaceLg, AppStyling.spaceLg, AppStyling.spaceLg, AppStyling.spaceSm,
              ),
              child: Text('CONVERSATIONS', style: AppStyling.label),
            ),
            if (state.conversations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceLg),
                child: Text('No conversations yet.', style: AppStyling.bodySm),
              )
            else
              Expanded(
                child: ListView(
                  children: [
                    for (final conversation in state.conversations)
                      _ConversationItem(
                        title: conversation.title,
                        timestamp: formatRelativeTime(conversation.updatedAt),
                        selected: conversation.id == state.activeConversationId,
                        onTap: () => controller.selectConversation(conversation.id),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ConversationItem extends StatefulWidget {
  final String title;
  final String timestamp;
  final bool selected;
  final VoidCallback onTap;

  const _ConversationItem({
    required this.title,
    required this.timestamp,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ConversationItem> createState() => _ConversationItemState();
}

class _ConversationItemState extends State<_ConversationItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(
            horizontal: AppStyling.spaceSm,
            vertical: 2,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppStyling.spaceMd,
            vertical: AppStyling.spaceSm,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.accentBg
                : _hovered
                    ? AppColors.surfaceElevated
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppStyling.radiusSm),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyling.bodySm.copyWith(
                    color: widget.selected
                        ? AppColors.accentLight
                        : _hovered
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                    fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: AppStyling.spaceSm),
              Text(widget.timestamp, style: AppStyling.label),
            ],
          ),
        ),
      ),
    );
  }
}
