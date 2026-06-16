import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';

class IssueDeleteDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const IssueDeleteDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyling.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppStyling.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete issue?', style: AppStyling.headingMd),
            const SizedBox(height: AppStyling.spaceSm),
            Text("This can't be undone.", style: AppStyling.bodySm),
            const SizedBox(height: AppStyling.spaceXl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: AppStyling.bodySm),
                ),
                const SizedBox(width: AppStyling.spaceLg),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppStyling.spaceLg,
                      vertical: AppStyling.spaceSm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                    ),
                    child: Text(
                      'Delete',
                      style: AppStyling.bodySm.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
