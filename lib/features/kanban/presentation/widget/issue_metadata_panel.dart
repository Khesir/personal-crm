import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/model/issue.dart';
import '../../domain/model/issue_status_display.dart';

const _kPanelWidth = 280.0;

class IssueMetadataPanel extends StatelessWidget {
  final Issue issue;
  final String rawFrontmatter;

  const IssueMetadataPanel({
    super.key,
    required this.issue,
    required this.rawFrontmatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kPanelWidth,
      padding: const EdgeInsets.all(AppStyling.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details', style: AppStyling.headingMd),
            const SizedBox(height: AppStyling.spaceLg),
            _MetadataRow(label: 'Status', child: _StatusPill(status: issue.status)),
            const SizedBox(height: AppStyling.spaceMd),
            _MetadataRow(label: 'Feature', value: issue.feature),
            const SizedBox(height: AppStyling.spaceMd),
            _MetadataRow(
              label: 'Created',
              value: issue.createdAt != null ? _formatDate(issue.createdAt!) : '—',
            ),
            const SizedBox(height: AppStyling.spaceMd),
            _MetadataRow(
              label: 'Tags',
              child: issue.tags.isEmpty
                  ? Text('—', style: AppStyling.bodySm)
                  : Wrap(
                      spacing: AppStyling.spaceXs,
                      runSpacing: AppStyling.spaceXs,
                      children: [
                        for (final tag in issue.tags) _Tag(label: tag),
                      ],
                    ),
            ),
            const SizedBox(height: AppStyling.spaceMd),
            _MetadataRow(label: 'File path', value: issue.filePath, mono: true),
            const SizedBox(height: AppStyling.spaceLg),
            Text('Frontmatter', style: AppStyling.label),
            const SizedBox(height: AppStyling.spaceSm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppStyling.spaceMd),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: SelectableText(rawFrontmatter, style: AppStyling.monoSm),
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

class _MetadataRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;
  final bool mono;

  const _MetadataRow({required this.label, this.value, this.child, this.mono = false})
      : assert(value != null || child != null);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyling.label),
        const SizedBox(height: AppStyling.spaceXs),
        child ??
            Text(
              value!,
              style: mono ? AppStyling.monoSm : AppStyling.bodySm.copyWith(color: AppColors.textPrimary),
            ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IssueStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceSm, vertical: 2),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppStyling.radiusSm),
        border: Border.all(color: status.color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppStyling.spaceXs),
          Text(status.label, style: AppStyling.bodySm.copyWith(color: status.color)),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

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
