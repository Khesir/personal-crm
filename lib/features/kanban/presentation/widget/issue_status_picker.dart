import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/model/issue.dart';
import '../../domain/model/issue_status_display.dart';

class IssueStatusPicker extends StatelessWidget {
  final IssueStatus status;
  final ValueChanged<IssueStatus> onChanged;

  const IssueStatusPicker({super.key, required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<IssueStatus>(
          value: status,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          dropdownColor: AppColors.surfaceElevated,
          style: AppStyling.bodySm,
          onChanged: (value) {
            if (value != null && value != status) onChanged(value);
          },
          items: [
            for (final value in IssueStatus.values)
              DropdownMenuItem(
                value: value,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: value.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: AppStyling.spaceSm),
                    Text(value.label, style: AppStyling.bodySm.copyWith(color: AppColors.textPrimary)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
