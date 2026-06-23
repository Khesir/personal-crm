import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/features/kanban/api.dart';
import 'package:crm/features/settings/api.dart';
import '../../domain/controller/bug_reports_controller.dart';
import '../../domain/helper/bug_report_to_issue.dart';
import '../../domain/model/bug_report.dart';

class BugReportsSection extends StatefulWidget {
  final BugReportsController controller;
  final IssuesController issuesController;
  final Project project;

  const BugReportsSection({
    super.key,
    required this.controller,
    required this.issuesController,
    required this.project,
  });

  @override
  State<BugReportsSection> createState() => _BugReportsSectionState();
}

class _BugReportsSectionState extends State<BugReportsSection> {
  BugSeverity? _severityFilter;
  String? _selectedReportId;

  void _selectReport(String id) {
    setState(() => _selectedReportId = id);
  }

  void _closeDetail() {
    setState(() => _selectedReportId = null);
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<BugReport>>(
      state: widget.controller,
      loadingBuilder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      errorBuilder: (_, __) => Center(
        child: Text('Could not load bug reports.', style: AppStyling.bodySm),
      ),
      builder: (context, reports) {
        final reportId = _selectedReportId;
        if (reportId != null) {
          BugReport? report;
          for (final candidate in reports) {
            if (candidate.id == reportId) {
              report = candidate;
              break;
            }
          }
          if (report == null) {
            return Center(
              child: Text('Bug report not found.', style: AppStyling.bodySm),
            );
          }
          return BugDetailSection(
            report: report,
            controller: widget.controller,
            issuesController: widget.issuesController,
            project: widget.project,
            onBack: _closeDetail,
          );
        }

        return BugInboxSection(
          reports: reports,
          severityFilter: _severityFilter,
          onSeverityFilterChanged: (severity) =>
              setState(() => _severityFilter = severity),
          onReportTap: (report) => _selectReport(report.id),
        );
      },
    );
  }
}

class BugInboxSection extends StatelessWidget {
  final List<BugReport> reports;
  final BugSeverity? severityFilter;
  final ValueChanged<BugSeverity?> onSeverityFilterChanged;
  final ValueChanged<BugReport> onReportTap;

  const BugInboxSection({
    super.key,
    required this.reports,
    required this.severityFilter,
    required this.onSeverityFilterChanged,
    required this.onReportTap,
  });

  List<BugReport> get _filteredReports {
    if (severityFilter == null) return reports;
    return reports.where((r) => r.severity == severityFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredReports;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SeverityFilterBar(
          selected: severityFilter,
          onChanged: onSeverityFilterChanged,
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text('No bug reports', style: AppStyling.bodySm),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppStyling.spaceXl),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppStyling.spaceMd),
                  itemBuilder: (context, i) => _BugReportCard(
                    report: filtered[i],
                    onTap: () => onReportTap(filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _SeverityFilterBar extends StatelessWidget {
  final BugSeverity? selected;
  final ValueChanged<BugSeverity?> onChanged;

  const _SeverityFilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyling.spaceXl,
        vertical: AppStyling.spaceLg,
      ),
      child: Row(
        children: [
          _SeverityPill(
            label: 'All',
            color: AppColors.textSecondary,
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: AppStyling.spaceSm),
          for (final severity in BugSeverity.values) ...[
            _SeverityPill(
              label: severity.label,
              color: severityColor(severity),
              selected: selected == severity,
              onTap: () => onChanged(severity),
            ),
            const SizedBox(width: AppStyling.spaceSm),
          ],
        ],
      ),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SeverityPill({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceMd,
          vertical: AppStyling.spaceXs,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppStyling.radiusSm),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Text(
          label,
          style: AppStyling.bodySm.copyWith(
            color: selected ? color : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _BugReportCard extends StatelessWidget {
  final BugReport report;
  final VoidCallback onTap;

  const _BugReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = severityColor(report.severity);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppStyling.spaceLg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyling.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyling.spaceSm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppStyling.radiusSm),
                  ),
                  child: Text(
                    report.severity.label.toUpperCase(),
                    style: AppStyling.monoSm.copyWith(color: color),
                  ),
                ),
                if (report.resolved) ...[
                  const SizedBox(width: AppStyling.spaceSm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppStyling.spaceSm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppStyling.radiusSm),
                    ),
                    child: Text(
                      'RESOLVED',
                      style: AppStyling.monoSm.copyWith(color: AppColors.success),
                    ),
                  ),
                ],
                const Spacer(),
                Text(formatBugReportDate(report.createdAt), style: AppStyling.monoSm),
              ],
            ),
            const SizedBox(height: AppStyling.spaceMd),
            Text(report.message, style: AppStyling.headingMd),
            if (report.source != null) ...[
              const SizedBox(height: AppStyling.spaceSm),
              Text(report.source!, style: AppStyling.monoSm),
            ],
          ],
        ),
      ),
    );
  }
}

class BugDetailSection extends StatelessWidget {
  final BugReport report;
  final BugReportsController controller;
  final IssuesController issuesController;
  final Project project;
  final VoidCallback onBack;

  const BugDetailSection({
    super.key,
    required this.report,
    required this.controller,
    required this.issuesController,
    required this.project,
    required this.onBack,
  });

  Future<void> _convertToIssue(BuildContext context) async {
    await issuesController.createIssue(
      project.localPath,
      mapBugReportToIssue(report),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Issue created in backlog.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = severityColor(report.severity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppStyling.spaceXl),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: const Icon(Icons.arrow_back, size: 18, color: AppColors.textMuted),
              ),
              const SizedBox(width: AppStyling.spaceMd),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyling.spaceSm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppStyling.radiusSm),
                ),
                child: Text(
                  report.severity.label.toUpperCase(),
                  style: AppStyling.monoSm.copyWith(color: color),
                ),
              ),
              const Spacer(),
              _ActionButton(
                label: 'Convert to issue',
                onTap: () => _convertToIssue(context),
              ),
              const SizedBox(width: AppStyling.spaceSm),
              if (!report.resolved) ...[
                _ActionButton(
                  label: 'Resolve',
                  onTap: () => controller.resolve(report.id),
                ),
                const SizedBox(width: AppStyling.spaceSm),
              ],
              _ActionButton(
                label: 'Delete',
                destructive: true,
                onTap: () {
                  controller.delete(report.id);
                  onBack();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceXl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.message, style: AppStyling.headingLg),
                const SizedBox(height: AppStyling.spaceSm),
                Text(formatBugReportDate(report.createdAt), style: AppStyling.monoSm),
                if (report.source != null) ...[
                  const SizedBox(height: AppStyling.spaceLg),
                  Text('Source', style: AppStyling.label),
                  const SizedBox(height: AppStyling.spaceXs),
                  Text(report.source!, style: AppStyling.bodySm),
                ],
                if (report.stackTrace != null) ...[
                  const SizedBox(height: AppStyling.spaceLg),
                  Text('Stack Trace', style: AppStyling.label),
                  const SizedBox(height: AppStyling.spaceXs),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppStyling.spaceMd),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(report.stackTrace!, style: AppStyling.mono),
                  ),
                ],
                const SizedBox(height: AppStyling.spaceXl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceLg,
          vertical: AppStyling.spaceSm,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        ),
        child: Text(
          label,
          style: AppStyling.bodySm.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

Color severityColor(BugSeverity severity) => switch (severity) {
      BugSeverity.info => AppColors.severityInfo,
      BugSeverity.warning => AppColors.severityWarning,
      BugSeverity.error => AppColors.severityError,
      BugSeverity.critical => AppColors.severityCritical,
    };

String formatBugReportDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}
