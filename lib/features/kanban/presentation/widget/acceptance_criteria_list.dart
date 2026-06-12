import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/helper/acceptance_criteria_parser.dart';

class AcceptanceCriteriaList extends StatelessWidget {
  final List<AcceptanceCriteriaItem> items;
  final void Function(int index)? onToggle;

  const AcceptanceCriteriaList({
    super.key,
    required this.items,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final onToggle = this.onToggle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppStyling.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Acceptance criteria', style: AppStyling.headingMd),
          const SizedBox(height: AppStyling.spaceMd),
          for (var i = 0; i < items.length; i++) _CriteriaItem(
            item: items[i],
            onToggle: onToggle == null ? null : () => onToggle(i),
          ),
        ],
      ),
    );
  }
}

class _CriteriaItem extends StatelessWidget {
  final AcceptanceCriteriaItem item;
  final VoidCallback? onToggle;

  const _CriteriaItem({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final onToggle = this.onToggle;
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppStyling.spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.checked,
            onChanged: onToggle == null ? null : (_) => onToggle(),
            activeColor: AppColors.accent,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppStyling.spaceSm),
              child: Text(
                item.text,
                style: AppStyling.bodyLg.copyWith(
                  color: item.checked ? AppColors.textSecondary : AppColors.textPrimary,
                  decoration: item.checked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (onToggle == null) return content;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppStyling.radiusSm),
      child: content,
    );
  }
}
