import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/model/health_status.dart';
import '../../domain/model/service_card.dart';

/// Horizontally scrollable row of filter chips for the Local LLM "Models"
/// list: an "All" chip plus one chip per engine [ServiceCard], each showing
/// a colored dot for its current [HealthStatus] (same mapping as
/// `_StatusBadge` in `services_section.dart`).
class EngineFilterChips extends StatelessWidget {
  final List<ServiceCard> engines;
  final Map<String, HealthStatus> healthStatuses;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  const EngineFilterChips({
    super.key,
    required this.engines,
    required this.healthStatuses,
    required this.selectedId,
    required this.onSelect,
  });

  Color _dotColor(String cardId) => switch (healthStatuses[cardId]) {
        HealthStatus.online => AppColors.success,
        HealthStatus.offline => AppColors.textMuted,
        HealthStatus.error => AppColors.error,
        HealthStatus.checking => AppColors.warning,
        null => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: selectedId == null,
            onTap: () => onSelect(null),
          ),
          for (final card in engines)
            Padding(
              padding: const EdgeInsets.only(left: AppStyling.spaceSm),
              child: _FilterChip(
                label: card.name,
                selected: selectedId == card.id,
                dotColor: _dotColor(card.id),
                dotKey: ValueKey('engine-chip-dot-${card.id}'),
                onTap: () => onSelect(selectedId == card.id ? null : card.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? dotColor;
  final Key? dotKey;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
    this.dotKey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceMd,
          vertical: AppStyling.spaceSm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentBg : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
          border: Border.all(color: selected ? AppColors.accentLine : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                key: dotKey,
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppStyling.spaceXs),
            ],
            Text(
              label,
              style: AppStyling.bodySm.copyWith(
                color: selected ? AppColors.accentLight : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
