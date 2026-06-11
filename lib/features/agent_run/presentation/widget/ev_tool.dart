import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';

class EvTool extends StatelessWidget {
  final String tool;
  final String detail;
  final bool isResult;

  const EvTool({
    super.key,
    required this.tool,
    required this.detail,
    this.isResult = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppStyling.spaceXs),
      child: Container(
        padding: const EdgeInsets.all(AppStyling.spaceMd),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isResult ? Icons.check_circle_outline : Icons.bolt_outlined,
                  size: 16,
                  color: isResult ? AppColors.success : AppColors.statusInProgress,
                ),
                const SizedBox(width: AppStyling.spaceSm),
                Text(
                  isResult ? '$tool result' : tool,
                  style: AppStyling.label,
                ),
              ],
            ),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: AppStyling.spaceXs),
              Text(detail, style: AppStyling.monoSm, maxLines: 6, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}
