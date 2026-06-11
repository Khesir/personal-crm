import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/model/issue.dart';

class IssueCard extends StatelessWidget {
  final Issue issue;
  final VoidCallback? onTap;

  const IssueCard({super.key, required this.issue, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyling.radiusMd),
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
            Text(issue.title, style: AppStyling.bodyLg),
            const SizedBox(height: AppStyling.spaceSm),
            Row(
              children: [
                const Icon(Icons.label_outline, size: 14, color: AppColors.accentLight),
                const SizedBox(width: AppStyling.spaceXs),
                Text(
                  issue.feature,
                  style: AppStyling.monoSm.copyWith(color: AppColors.accentLight),
                ),
              ],
            ),
            if (issue.tags.isNotEmpty) ...[
              const SizedBox(height: AppStyling.spaceSm),
              Wrap(
                spacing: AppStyling.spaceXs,
                runSpacing: AppStyling.spaceXs,
                children: [
                  for (final tag in issue.tags) _IssueTag(label: tag),
                ],
              ),
            ],
            const SizedBox(height: AppStyling.spaceSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(issue.id, style: AppStyling.monoSm),
                if (issue.createdAt != null)
                  Text(_formatDate(issue.createdAt!), style: AppStyling.monoSm),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _IssueTag extends StatelessWidget {
  final String label;

  const _IssueTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceSm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppStyling.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: AppStyling.monoSm),
    );
  }
}
