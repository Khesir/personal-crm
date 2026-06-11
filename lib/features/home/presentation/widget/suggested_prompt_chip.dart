import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';

class SuggestedPromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const SuggestedPromptChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyling.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceLg,
          vertical: AppStyling.spaceMd,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label, style: AppStyling.bodySm),
      ),
    );
  }
}
