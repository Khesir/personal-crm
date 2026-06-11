import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/shell_controller.dart';
import '../state/shell_state.dart';

class AppRail extends StatelessWidget {
  final ShellController controller;

  const AppRail({super.key, required this.controller});

  IconData _iconFor(AppTab tab) => switch (tab) {
        AppTab.home => Icons.chat_bubble_outline_rounded,
        AppTab.projects => Icons.space_dashboard_outlined,
        AppTab.settings => Icons.settings_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ShellStateData>(
      stream: controller.stream,
      initialData: controller.state,
      builder: (context, snapshot) {
        final shellState = snapshot.data!;
        return Container(
          width: AppStyling.railWidth,
          color: AppColors.titlebarBackground,
          child: Column(
            children: [
              const SizedBox(height: AppStyling.spaceMd),
              for (final tab in [AppTab.home, AppTab.projects])
                _RailItem(
                  tab: tab,
                  icon: _iconFor(tab),
                  selected: shellState.selectedTab == tab,
                  onTap: () => controller.selectTab(tab),
                ),
              const Spacer(),
              _RailItem(
                tab: AppTab.settings,
                icon: _iconFor(AppTab.settings),
                selected: shellState.selectedTab == AppTab.settings,
                onTap: () => controller.selectTab(AppTab.settings),
              ),
              const SizedBox(height: AppStyling.spaceMd),
            ],
          ),
        );
      },
    );
  }
}

class _RailItem extends StatefulWidget {
  final AppTab tab;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RailItem({
    required this.tab,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tab.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: AppStyling.spaceXs),
            width: AppStyling.railWidth,
            height: AppStyling.railWidth - AppStyling.spaceLg,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: widget.selected ? AppColors.accent : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.selected
                      ? AppColors.accentBg
                      : _hovered
                          ? AppColors.surfaceElevated
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                ),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: widget.selected ? AppColors.accentLight : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
