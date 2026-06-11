import 'package:flutter/material.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/issues_controller.dart';
import '../../domain/model/issue.dart';
import '../widget/kanban_column.dart';

class KanbanSection extends StatelessWidget {
  final IssuesController controller;
  final void Function(Issue issue)? onIssueTap;

  const KanbanSection({super.key, required this.controller, this.onIssueTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      child: AsyncStreamBuilder<List<Issue>>(
        state: controller,
        builder: (context, issues) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final status in IssueStatus.values)
                  SizedBox(
                    height: 600,
                    child: KanbanColumn(
                      status: status,
                      issues: issues.where((issue) => issue.status == status).toList(),
                      onIssueTap: onIssueTap,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
