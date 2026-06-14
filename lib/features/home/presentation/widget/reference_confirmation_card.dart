import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/model/tool_execution_result.dart';

/// A confirmation card for a [ToolReferenceConfirmationNeeded] result:
/// "Allow read access to [projectName]?" with Allow/Deny buttons.
class ReferenceConfirmationCard extends StatelessWidget {
  final String projectName;
  final String path;
  final VoidCallback? onAllow;
  final VoidCallback? onDeny;

  const ReferenceConfirmationCard({
    super.key,
    required this.projectName,
    required this.path,
    this.onAllow,
    this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: AppStyling.spaceXs),
        padding: const EdgeInsets.all(AppStyling.spaceLg),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppStyling.radiusLg),
          border: Border.all(color: AppColors.accentLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline, size: 16, color: AppColors.accentLight),
                const SizedBox(width: AppStyling.spaceSm),
                Expanded(
                  child: Text(
                    'Allow read access to $projectName?',
                    style: AppStyling.headingMd,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyling.spaceXs),
            Text(path, style: AppStyling.monoSm),
            const SizedBox(height: AppStyling.spaceMd),
            Row(
              children: [
                FilledButton(
                  onPressed: onAllow,
                  child: const Text('Allow'),
                ),
                const SizedBox(width: AppStyling.spaceSm),
                OutlinedButton(
                  onPressed: onDeny,
                  child: const Text('Deny'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
