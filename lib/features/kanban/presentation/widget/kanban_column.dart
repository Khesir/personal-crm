import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/model/issue.dart';
import '../../domain/model/issue_status_display.dart';
import 'issue_card.dart';

class KanbanColumn extends StatelessWidget {
  final IssueStatus status;
  final List<Issue> issues;
  final void Function(Issue issue)? onIssueTap;

  const KanbanColumn({
    super.key,
    required this.status,
    required this.issues,
    this.onIssueTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: AppStyling.spaceLg),
      padding: const EdgeInsets.all(AppStyling.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.kanbanColumnBackground,
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppStyling.spaceSm),
              Text(status.label, style: AppStyling.headingMd),
              const SizedBox(width: AppStyling.spaceSm),
              Text('${issues.length}', style: AppStyling.monoSm),
            ],
          ),
          const SizedBox(height: AppStyling.spaceMd),
          Expanded(
            child: issues.isEmpty
                ? Center(
                    child: Text('No issues', style: AppStyling.bodySm),
                  )
                : ListView.separated(
                    itemCount: issues.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppStyling.spaceSm),
                    itemBuilder: (context, index) => IssueCard(
                      issue: issues[index],
                      onTap: onIssueTap == null ? null : () => onIssueTap!(issues[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
