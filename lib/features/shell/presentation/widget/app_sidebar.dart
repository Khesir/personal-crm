import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/shell_controller.dart';
import '../state/shell_state.dart';

class AppSidebar extends StatelessWidget {
  final ShellController controller;

  const AppSidebar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ShellStateData>(
      stream: controller.stream,
      initialData: controller.state,
      builder: (context, snapshot) {
        final shellState = snapshot.data!;
        return Container(
          width: AppStyling.sidebarWidth,
          color: AppColors.surface,
          child: _SettingsSidebar(
            selected: shellState.selectedSettingsSection,
            onSelect: controller.selectSettingsSection,
          ),
        );
      },
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final String label;

  const _SidebarHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppStyling.spaceLg, AppStyling.spaceLg, AppStyling.spaceLg, AppStyling.spaceSm,
      ),
      child: Text(label.toUpperCase(), style: AppStyling.label),
    );
  }
}

class _SettingsSidebar extends StatelessWidget {
  final SettingsSection selected;
  final ValueChanged<SettingsSection> onSelect;

  const _SettingsSidebar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SidebarHeader(label: 'Settings'),
        for (final section in SettingsSection.values)
          _SidebarItem(
            label: section.label,
            selected: section == selected,
            onTap: () => onSelect(section),
          ),
      ],
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.label,
    required this.selected,
    required this.onTap,
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
              Text(
                widget.label,
                style: AppStyling.bodySm.copyWith(
                  color: widget.selected
                      ? AppColors.accentLight
                      : _hovered
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                  fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
