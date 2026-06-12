import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/model/cookbook_entry.dart';

class ModelSwitcher extends StatelessWidget {
  final List<CookbookEntry> entries;
  final CookbookEntry? activeEntry;
  final ValueChanged<CookbookEntry> onSelect;

  const ModelSwitcher({
    super.key,
    required this.entries,
    required this.activeEntry,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text('No models found', style: AppStyling.bodySm);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CookbookEntry>(
          value: entries.contains(activeEntry) ? activeEntry : null,
          hint: Text('Select model', style: AppStyling.bodySm),
          dropdownColor: AppColors.surfaceRaised,
          icon: const Icon(Icons.expand_more_rounded, color: AppColors.textSecondary, size: 18),
          style: AppStyling.bodySm.copyWith(color: AppColors.textPrimary),
          items: [
            for (final entry in entries)
              DropdownMenuItem(
                value: entry,
                child: Text('${entry.model} — ${entry.cardName}'),
              ),
          ],
          onChanged: (value) {
            if (value != null) onSelect(value);
          },
        ),
      ),
    );
  }
}
