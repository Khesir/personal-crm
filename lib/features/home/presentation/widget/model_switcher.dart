import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';

class ModelSwitcher extends StatelessWidget {
  final List<String> models;
  final String? activeModel;
  final ValueChanged<String> onSelect;

  const ModelSwitcher({
    super.key,
    required this.models,
    required this.activeModel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) {
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
        child: DropdownButton<String>(
          value: models.contains(activeModel) ? activeModel : null,
          hint: Text('Select model', style: AppStyling.bodySm),
          dropdownColor: AppColors.surfaceRaised,
          icon: const Icon(Icons.expand_more_rounded, color: AppColors.textSecondary, size: 18),
          style: AppStyling.bodySm.copyWith(color: AppColors.textPrimary),
          items: [
            for (final model in models)
              DropdownMenuItem(value: model, child: Text(model)),
          ],
          onChanged: (value) {
            if (value != null) onSelect(value);
          },
        ),
      ),
    );
  }
}
