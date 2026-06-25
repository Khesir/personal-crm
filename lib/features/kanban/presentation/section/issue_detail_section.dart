import 'dart:io';

import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/issues_controller.dart';
import '../../domain/helper/acceptance_criteria_parser.dart';
import '../../domain/helper/issue_raw_edit_validator.dart';
import '../../domain/model/issue.dart';
import '../dialogs/issue_delete_dialog.dart';
import '../dialogs/issue_discard_changes_dialog.dart';
import '../widget/acceptance_criteria_list.dart';
import '../widget/issue_edit_tabs.dart';
import '../widget/issue_metadata_panel.dart';
import '../widget/issue_status_picker.dart';
import '../widget/markdown_issue_body.dart';

class IssueDetailSection extends StatefulWidget {
  final IssuesController controller;
  final Issue issue;
  final VoidCallback onBack;
  final bool readOnly;
  final VoidCallback onDeleted;

  const IssueDetailSection({
    super.key,
    required this.controller,
    required this.issue,
    required this.onBack,
    required this.onDeleted,
    this.readOnly = false,
  });

  @override
  State<IssueDetailSection> createState() => _IssueDetailSectionState();
}

class _IssueDetailSectionState extends State<IssueDetailSection> {
  bool _editing = false;
  bool _committing = false;
  String? _commitError;
  late TextEditingController _rawContentController;
  late String _rawContentSeed;

  @override
  void dispose() {
    if (_editing) _rawContentController.dispose();
    super.dispose();
  }

  void _toggleCriteria(int index) {
    widget.controller.toggleAcceptanceCriteria(widget.issue, index);
  }

  void _move(IssueStatus newStatus) {
    widget.controller.moveIssue(widget.issue, newStatus);
  }

  void _enterEditMode() {
    final rawContents = File(widget.issue.filePath).readAsStringSync();
    setState(() {
      _rawContentController = TextEditingController(text: rawContents);
      _rawContentSeed = rawContents;
      _editing = true;
      _commitError = null;
    });
  }

  bool get _hasUnsavedChanges => _rawContentController.text != _rawContentSeed;

  void _handleBack(BuildContext context) {
    if (_editing && _hasUnsavedChanges) {
      showDialog(
        context: context,
        builder: (_) => IssueDiscardChangesDialog(onConfirm: widget.onBack),
      );
      return;
    }
    widget.onBack();
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _commitError = null;
    });
    _rawContentController.dispose();
  }

  Future<void> _commitEdit() async {
    final result = validateIssueRawEdit(widget.issue, _rawContentController.text);
    if (result is IssueRawEditFailure) {
      setState(() => _commitError = _commitErrorMessage(result.reason));
      return;
    }

    setState(() {
      _committing = true;
      _commitError = null;
    });
    await widget.controller.updateIssueRaw(widget.issue, _rawContentController.text);
    if (!mounted) return;
    setState(() {
      _committing = false;
      _editing = false;
    });
    _rawContentController.dispose();
  }

  String _commitErrorMessage(IssueRawEditFailureReason reason) {
    switch (reason) {
      case IssueRawEditFailureReason.parseError:
        return 'Could not parse this content. Check the frontmatter and try again.';
      case IssueRawEditFailureReason.idChanged:
        return '`id` cannot be changed.';
      case IssueRawEditFailureReason.createdAtChanged:
        return '`created_at` cannot be changed.';
      case IssueRawEditFailureReason.statusChanged:
        return '`status` cannot be changed here. Use the status picker instead.';
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => IssueDeleteDialog(
        onConfirm: () async {
          await widget.controller.deleteIssue(widget.issue);
          widget.onDeleted();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    final criteria = parseAcceptanceCriteria(issue.body);
    final bodyWithoutCriteria = removeAcceptanceCriteriaSection(issue.body);

    return Padding(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailHeader(
            issue: issue,
            onBack: () => _handleBack(context),
            onMove: _move,
            onEdit: _enterEditMode,
            onDelete: () => _confirmDelete(context),
            readOnly: widget.readOnly,
            editing: _editing,
            committing: _committing,
            onCancelEdit: _cancelEdit,
            onCommitEdit: _commitEdit,
          ),
          const SizedBox(height: AppStyling.spaceLg),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _editing
                      ? IssueEditTabs(
                          controller: _rawContentController,
                          errorText: _commitError,
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MarkdownIssueBody(content: bodyWithoutCriteria),
                              if (criteria.isNotEmpty) ...[
                                const SizedBox(height: AppStyling.spaceLg),
                                AcceptanceCriteriaList(
                                  items: criteria,
                                  onToggle: widget.readOnly ? null : _toggleCriteria,
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
  final bool readOnly;
  final bool editing;
  final bool committing;
  final VoidCallback onCancelEdit;
  final VoidCallback onCommitEdit;

  const _DetailHeader({
    required this.issue,
    required this.onBack,
    required this.onMove,
    required this.onEdit,
    required this.onDelete,
    required this.editing,
    required this.committing,
    required this.onCancelEdit,
    required this.onCommitEdit,
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
        if (!editing)
          Expanded(
            child: Text(
              issue.title,
              style: AppStyling.pageTitle,
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          const Spacer(),
        if (!readOnly && !editing) ...[
          IssueStatusPicker(status: issue.status, onChanged: onMove),
          const SizedBox(width: AppStyling.spaceMd),
          _ActionButton(label: 'Edit', icon: Icons.edit_outlined, onTap: onEdit),
          const SizedBox(width: AppStyling.spaceMd),
          _ActionButton(label: 'Delete', icon: Icons.delete_outline, onTap: onDelete, destructive: true),
        ],
        if (!readOnly && editing) ...[
          _ActionButton(label: 'Cancel', icon: Icons.close, onTap: onCancelEdit),
          const SizedBox(width: AppStyling.spaceMd),
          _ActionButton(
            label: 'Commit changes',
            icon: Icons.check,
            onTap: committing ? null : onCommitEdit,
            loading: committing,
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool destructive;
  final bool loading;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
    this.loading = false,
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
            if (loading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary),
              )
            else
              Icon(icon, size: 16, color: color),
            const SizedBox(width: AppStyling.spaceXs),
            Text(label, style: AppStyling.bodySm.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
