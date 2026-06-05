import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/keep_track/domain/controller/support_controller.dart';
import '../../domain/controller/shell_controller.dart';
import '../state/shell_state.dart';

class AppSidebar extends StatelessWidget {
  final ShellController controller;
  final SupportController? supportCtrl;

  const AppSidebar({super.key, required this.controller, this.supportCtrl});

  Color _accentFor(AppTab tab) => switch (tab) {
        AppTab.portfolio => AppColors.accentPortfolio,
        AppTab.keepTrack => AppColors.accentKeepTrack,
        AppTab.timeTracker => AppColors.accentTimeTracker,
        AppTab.ariConnect => AppColors.accentAriConnect,
        AppTab.minecraft => AppColors.accentMinecraft,
      };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ShellStateData>(
      stream: controller.stream,
      initialData: controller.state,
      builder: (context, snapshot) {
        final shellState = snapshot.data!;
        final sections = kTabSections[shellState.selectedTab]!;
        final accent = _accentFor(shellState.selectedTab);

        final groups = kTabSectionGroups[shellState.selectedTab];

        return Container(
          width: AppStyling.sidebarWidth,
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppStyling.spaceLg),
              if (groups != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final group in groups) ...[
                          if (group.label != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppStyling.spaceLg, AppStyling.spaceMd, AppStyling.spaceLg, AppStyling.spaceXs,
                              ),
                              child: Text(group.label!.toUpperCase(), style: AppStyling.label),
                            )
                          else
                            const SizedBox(height: AppStyling.spaceXs),
                          for (final section in group.sections)
                            _SidebarItem(
                              section: section,
                              selected: shellState.selectedSection == section,
                              accent: accent,
                              onTap: () => controller.selectSection(section),
                            ),
                        ],
                      ],
                    ),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyling.spaceLg,
                    vertical: AppStyling.spaceSm,
                  ),
                  child: Text('NAVIGATION', style: AppStyling.label),
                ),
                for (final section in sections.where((s) => s != AppSection.settings))
                  _SidebarItem(
                    section: section,
                    selected: shellState.selectedSection == section,
                    accent: accent,
                    onTap: () => controller.selectSection(section),
                    badge: section == AppSection.support && supportCtrl != null
                        ? supportCtrl!.hasUnreadNotifier
                        : null,
                  ),
                const Spacer(),
              ],
              if (groups != null) const Spacer(),
              Divider(height: 1, thickness: 0.5, color: AppColors.border),
              _SidebarItem(
                section: AppSection.settings,
                selected: shellState.selectedSection == AppSection.settings,
                accent: accent,
                onTap: () => controller.selectSection(AppSection.settings),
              ),
              const SizedBox(height: AppStyling.spaceSm),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final AppSection section;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final ValueNotifier<bool>? badge;

  const _SidebarItem({
    required this.section,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.badge,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
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
                ? widget.accent.withValues(alpha: 0.12)
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
                    color: widget.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                const SizedBox(width: 3),
              const SizedBox(width: AppStyling.spaceSm),
              Text(
                widget.section.label,
                style: AppStyling.bodySm.copyWith(
                  color: widget.selected
                      ? widget.accent
                      : _hovered
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                  fontWeight:
                      widget.selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (widget.badge != null) ...[
                const Spacer(),
                ValueListenableBuilder<bool>(
                  valueListenable: widget.badge!,
                  builder: (_, hasUnread, __) => hasUnread
                      ? Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
