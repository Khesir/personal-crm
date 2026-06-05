import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/shell_controller.dart';
import '../state/shell_state.dart';

class AppTabBar extends StatelessWidget {
  final ShellController controller;

  const AppTabBar({super.key, required this.controller});

  Color _accentFor(AppTab tab) => switch (tab) {
        AppTab.portfolio => AppColors.accentPortfolio,
        AppTab.keepTrack => AppColors.accentKeepTrack,
        AppTab.timeTracker => AppColors.accentTimeTracker,
        AppTab.ariConnect => AppColors.accentAriConnect,
        AppTab.minecraft => AppColors.accentMinecraft,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppStyling.tabBarHeight,
      color: AppColors.surface,
      child: Row(
        children: [
          for (final tab in AppTab.values) _Tab(
            tab: tab,
            accent: _accentFor(tab),
            controller: controller,
          ),
          const Spacer(),
          Container(width: 1, height: 24, color: AppColors.border),
          const SizedBox(width: AppStyling.spaceMd),
        ],
      ),
    );
  }
}

class _Tab extends StatefulWidget {
  final AppTab tab;
  final Color accent;
  final ShellController controller;

  const _Tab({
    required this.tab,
    required this.accent,
    required this.controller,
  });

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ShellStateData>(
      stream: widget.controller.stream,
      initialData: widget.controller.state,
      builder: (context, snapshot) {
        final selected = snapshot.data?.selectedTab == widget.tab;
        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () => widget.controller.selectTab(widget.tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyling.spaceXl,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected
                        ? widget.accent
                        : _hovered
                            ? widget.accent.withValues(alpha: 0.4)
                            : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  widget.tab.label,
                  style: AppStyling.bodySm.copyWith(
                    color: selected
                        ? widget.accent
                        : _hovered
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
