import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';

/// A generic collapsible card shell for rendering one step of an agent
/// loop turn (a tool call, or a confirmation prompt). [header] is always
/// visible and toggles [body]'s visibility when tapped.
class StepCard extends StatefulWidget {
  final Widget header;
  final Widget body;
  final bool initiallyExpanded;

  const StepCard({
    super.key,
    required this.header,
    required this.body,
    this.initiallyExpanded = false,
  });

  @override
  State<StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<StepCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: AppStyling.spaceXs),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppStyling.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(AppStyling.radiusLg),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyling.spaceLg,
                  vertical: AppStyling.spaceMd,
                ),
                child: Row(
                  children: [
                    Expanded(child: widget.header),
                    const SizedBox(width: AppStyling.spaceSm),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppStyling.spaceLg,
                  0,
                  AppStyling.spaceLg,
                  AppStyling.spaceLg,
                ),
                child: widget.body,
              ),
          ],
        ),
      ),
    );
  }
}
