import 'package:flutter/material.dart';
import 'package:crm/core/state/stream_builder_widget.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/agent/api.dart';
import '../helpers/relative_time.dart';

class HomeSidebarSection extends StatefulWidget {
  final AgentController controller;

  const HomeSidebarSection({super.key, required this.controller});

  @override
  State<HomeSidebarSection> createState() => _HomeSidebarSectionState();
}

class _HomeSidebarSectionState extends State<HomeSidebarSection> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return StreamStateBuilder<AgentStateData>(
      state: widget.controller,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppStyling.spaceLg,
                AppStyling.spaceLg,
                AppStyling.spaceLg,
                AppStyling.spaceSm,
              ),
              child: _NewChatButton(onTap: widget.controller.newChat),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppStyling.spaceLg,
                AppStyling.spaceSm,
                AppStyling.spaceLg,
                AppStyling.spaceSm,
              ),
              child: Text('RECENT', style: AppStyling.label),
            ),
            if (state.sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceLg),
                child: Text('No conversations yet.', style: AppStyling.bodySm),
              )
            else
              Expanded(
                child: ListView(
                  children: [
                    for (final session in state.sessions)
                      _SessionItem(
                        title: session.title,
                        timestamp: formatRelativeTime(session.updatedAt),
                        selected: session.id == state.sessionId,
                        onTap: () => widget.controller.resumeSession(session.id),
                        onDelete: () => widget.controller.deleteSession(session.id),
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

class _NewChatButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NewChatButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppStyling.spaceSm),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 16, color: Colors.black),
            const SizedBox(width: AppStyling.spaceXs),
            Text(
              'New chat',
              style: AppStyling.bodySm.copyWith(color: Colors.black, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionItem extends StatefulWidget {
  final String title;
  final String timestamp;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionItem({
    required this.title,
    required this.timestamp,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_SessionItem> createState() => _SessionItemState();
}

class _SessionItemState extends State<_SessionItem> {
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
          margin: const EdgeInsets.symmetric(horizontal: AppStyling.spaceSm, vertical: 2),
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
              if (widget.selected)
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                const SizedBox(width: 3),
              const SizedBox(width: AppStyling.spaceSm),
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
              if (_hovered)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: const Icon(Icons.delete_outline, size: 14, color: AppColors.textTertiary),
                )
              else
                Text(
                  widget.timestamp,
                  style: AppStyling.bodySm.copyWith(color: AppColors.textTertiary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
