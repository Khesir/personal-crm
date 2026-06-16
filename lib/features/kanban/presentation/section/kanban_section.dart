import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/issues_controller.dart';
import '../../domain/model/issue.dart';
import '../widget/kanban_column.dart';

class KanbanSection extends StatefulWidget {
  final IssuesController controller;
  final void Function(Issue issue)? onIssueTap;
  final bool readOnly;

  const KanbanSection({
    super.key,
    required this.controller,
    this.onIssueTap,
    this.readOnly = false,
  });

  @override
  State<KanbanSection> createState() => _KanbanSectionState();
}

class _KanbanSectionState extends State<KanbanSection> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final delta = event.scrollDelta.dy != 0 ? event.scrollDelta.dy : event.scrollDelta.dx;
    final target = (_scrollController.offset + delta).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(target);
  }

  void _createIssue(IssueStatus status, String title) {
    final localPath = widget.controller.localPath;
    if (localPath == null) return;
    final id = 'issue-${DateTime.now().millisecondsSinceEpoch}';
    final issue = Issue(
      id: id,
      title: title,
      feature: 'general',
      status: status,
      createdAt: DateTime.now(),
      tags: const [],
      body: '',
      filePath: '',
    );
    widget.controller.createIssue(localPath, issue);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      child: AsyncStreamBuilder<List<Issue>>(
        state: widget.controller,
        builder: (context, issues) {
          return Listener(
            onPointerSignal: _handlePointerSignal,
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
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
                          onIssueTap: widget.onIssueTap,
                          onMoveIssue: widget.readOnly
                              ? null
                              : (issue, newStatus) =>
                                  widget.controller.moveIssue(issue, newStatus),
                          onCreateIssue: widget.readOnly ? null : _createIssue,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
