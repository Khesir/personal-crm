import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/model/issue.dart';
import '../../domain/model/issue_status_display.dart';
import 'issue_card.dart';

class KanbanColumn extends StatefulWidget {
  final IssueStatus status;
  final List<Issue> issues;
  final void Function(Issue issue)? onIssueTap;
  final void Function(Issue issue, IssueStatus newStatus)? onMoveIssue;
  final void Function(IssueStatus status, String title)? onCreateIssue;

  const KanbanColumn({
    super.key,
    required this.status,
    required this.issues,
    this.onIssueTap,
    this.onMoveIssue,
    this.onCreateIssue,
  });

  @override
  State<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<KanbanColumn> {
  bool _isQuickAdding = false;
  final _addController = TextEditingController();
  final _addFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _addFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _addFocusNode.removeListener(_onFocusChanged);
    _addController.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_addFocusNode.hasFocus && _addController.text.trim().isEmpty) {
      _cancelAdd();
    }
  }

  void _startAdd() {
    setState(() => _isQuickAdding = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _addFocusNode.requestFocus());
  }

  void _cancelAdd() {
    if (!_isQuickAdding) return;
    _addController.clear();
    setState(() => _isQuickAdding = false);
  }

  void _submitAdd() {
    final title = _addController.text.trim();
    if (title.isEmpty) {
      _cancelAdd();
      return;
    }
    widget.onCreateIssue?.call(widget.status, title);
    _cancelAdd();
  }

  Widget _buildBody() {
    if (widget.issues.isEmpty && !_isQuickAdding) {
      return Center(child: Text('No issues', style: AppStyling.bodySm));
    }
    final itemCount = widget.issues.length + (_isQuickAdding ? 1 : 0);
    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppStyling.spaceSm),
      itemBuilder: (context, index) {
        if (_isQuickAdding && index == 0) {
          return _QuickAddCard(
            controller: _addController,
            focusNode: _addFocusNode,
            onSubmit: _submitAdd,
            onCancel: _cancelAdd,
          );
        }
        final issue = widget.issues[_isQuickAdding ? index - 1 : index];
        if (widget.onMoveIssue != null) {
          return Draggable<Issue>(
            data: issue,
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: 236,
                child: IssueCard(issue: issue),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: IssueCard(issue: issue),
            ),
            child: IssueCard(
              issue: issue,
              onTap: widget.onIssueTap == null ? null : () => widget.onIssueTap!(issue),
            ),
          );
        }
        return IssueCard(
          issue: issue,
          onTap: widget.onIssueTap == null ? null : () => widget.onIssueTap!(issue),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: AppStyling.spaceLg),
      child: DragTarget<Issue>(
        onWillAcceptWithDetails: (d) => d.data.status != widget.status,
        onAcceptWithDetails: (d) => widget.onMoveIssue?.call(d.data, widget.status),
        builder: (context, candidateData, _) {
          final isDragOver = candidateData.isNotEmpty;
          return Container(
            padding: const EdgeInsets.all(AppStyling.spaceMd),
            decoration: BoxDecoration(
              color: isDragOver ? AppColors.accentBg : AppColors.kanbanColumnBackground,
              borderRadius: BorderRadius.circular(AppStyling.radiusMd),
              border: Border.all(
                color: isDragOver ? AppColors.accentLine : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppStyling.spaceSm),
                    Text(widget.status.label, style: AppStyling.headingMd),
                    const SizedBox(width: AppStyling.spaceSm),
                    Text('${widget.issues.length}', style: AppStyling.monoSm),
                    const Spacer(),
                    if (widget.onCreateIssue != null)
                      GestureDetector(
                        onTap: _startAdd,
                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppStyling.spaceMd),
                Expanded(child: _buildBody()),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickAddCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _QuickAddCard({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppStyling.spaceSm),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppStyling.radiusSm),
        border: Border.all(color: AppColors.accentLine),
      ),
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): onCancel},
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          style: AppStyling.bodySm,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Issue title…',
            hintStyle: AppStyling.bodySm.copyWith(color: AppColors.textFaint),
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onSubmitted: (_) => onSubmit(),
        ),
      ),
    );
  }
}
