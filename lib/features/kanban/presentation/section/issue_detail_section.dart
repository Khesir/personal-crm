import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/issues_controller.dart';
import '../../domain/helper/acceptance_criteria_parser.dart';
import '../../domain/model/issue.dart';
import '../dialogs/issue_delete_dialog.dart';
import '../dialogs/issue_edit_dialog.dart';
import '../widget/acceptance_criteria_list.dart';
import '../widget/issue_metadata_panel.dart';
import '../widget/issue_status_picker.dart';
import '../widget/markdown_issue_body.dart';

class IssueDetailSection extends StatelessWidget {
  final IssuesController controller;
  final Issue issue;
  final VoidCallback onBack;
  final VoidCallback onRunSkill;
  final bool readOnly;
  final VoidCallback onDeleted;

  const IssueDetailSection({
    super.key,
    required this.controller,
    required this.issue,
    required this.onBack,
    required this.onRunSkill,
    required this.onDeleted,
    this.readOnly = false,
  });

  void _toggleCriteria(int index) {
    controller.toggleAcceptanceCriteria(issue, index);
  }

  void _move(IssueStatus newStatus) {
    controller.moveIssue(issue, newStatus);
  }

  void _edit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => IssueEditDialog(controller: controller, issue: issue),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => IssueDeleteDialog(
        onConfirm: () async {
          await controller.deleteIssue(issue);
          onDeleted();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final criteria = parseAcceptanceCriteria(issue.body);
    final bodyWithoutCriteria = removeAcceptanceCriteriaSection(issue.body);

    return Padding(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailHeader(
            issue: issue,
            onBack: onBack,
            onMove: _move,
            onEdit: () => _edit(context),
            onDelete: () => _confirmDelete(context),
            onRunSkill: onRunSkill,
            readOnly: readOnly,
          ),
          const SizedBox(height: AppStyling.spaceLg),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarkdownIssueBody(content: bodyWithoutCriteria),
                        if (criteria.isNotEmpty) ...[
                          const SizedBox(height: AppStyling.spaceLg),
                          AcceptanceCriteriaList(
                            items: criteria,
                            onToggle: readOnly ? null : _toggleCriteria,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppStyling.spaceLg),
                IssueMetadataPanel(
                  issue: issue,
                  rawFrontmatter: _buildFrontmatterPreview(issue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildFrontmatterPreview(Issue issue) {
    final tags = issue.tags.map((tag) => tag).join(', ');
    final createdAt = issue.createdAt != null
        ? '${issue.createdAt!.year.toString().padLeft(4, '0')}-'
            '${issue.createdAt!.month.toString().padLeft(2, '0')}-'
            '${issue.createdAt!.day.toString().padLeft(2, '0')}'
        : '';
    return '''
---
id: ${issue.id}
title: ${issue.title}
feature: ${issue.feature}
status: ${issue.status.name}
created_at: $createdAt
tags: [$tags]
---'''
        .trim();
  }
}

class _DetailHeader extends StatelessWidget {
  final Issue issue;
  final VoidCallback onBack;
  final ValueChanged<IssueStatus> onMove;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRunSkill;
  final bool readOnly;

  const _DetailHeader({
    required this.issue,
    required this.onBack,
    required this.onMove,
    required this.onEdit,
    required this.onDelete,
    required this.onRunSkill,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onBack,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppStyling.spaceXs),
              Text('Back to board', style: AppStyling.bodySm),
            ],
          ),
        ),
        const SizedBox(width: AppStyling.spaceLg),
        Expanded(
          child: Text(
            issue.title,
            style: AppStyling.pageTitle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!readOnly) ...[
          IssueStatusPicker(status: issue.status, onChanged: onMove),
          const SizedBox(width: AppStyling.spaceMd),
          _ActionButton(label: 'Run skill', icon: Icons.smart_toy_outlined, onTap: onRunSkill),
          const SizedBox(width: AppStyling.spaceMd),
          _ActionButton(label: 'Edit', icon: Icons.edit_outlined, onTap: onEdit),
          const SizedBox(width: AppStyling.spaceMd),
          _ActionButton(label: 'Delete', icon: Icons.delete_outline, onTap: onDelete, destructive: true),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceMd,
          vertical: AppStyling.spaceSm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
          border: Border.all(color: destructive ? AppColors.error.withValues(alpha: 0.4) : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppStyling.spaceXs),
            Text(label, style: AppStyling.bodySm.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
