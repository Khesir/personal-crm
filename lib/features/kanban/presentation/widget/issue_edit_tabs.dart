import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../data/datasource/issue_frontmatter_parser.dart';
import 'markdown_formatting_toolbar.dart';
import 'markdown_issue_body.dart';

enum IssueEditTab { write, preview }

class IssueEditTabs extends StatefulWidget {
  final TextEditingController controller;
  final String? errorText;

  const IssueEditTabs({
    super.key,
    required this.controller,
    this.errorText,
  });

  @override
  State<IssueEditTabs> createState() => _IssueEditTabsState();
}

class _IssueEditTabsState extends State<IssueEditTabs> {
  static const _frontmatterParser = IssueFrontmatterParser();

  IssueEditTab _tab = IssueEditTab.write;

  void _selectTab(IssueEditTab tab) {
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderStrong),
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyling.spaceMd,
              vertical: AppStyling.spaceSm,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderStrong)),
            ),
            child: Row(
              children: [
                _TabButton(
                  label: 'Write',
                  selected: _tab == IssueEditTab.write,
                  onTap: () => _selectTab(IssueEditTab.write),
                ),
                const SizedBox(width: AppStyling.spaceSm),
                _TabButton(
                  label: 'Preview',
                  selected: _tab == IssueEditTab.preview,
                  onTap: () => _selectTab(IssueEditTab.preview),
                ),
                if (_tab == IssueEditTab.write) ...[
                  const SizedBox(width: AppStyling.spaceMd),
                  Expanded(child: MarkdownFormattingToolbar(controller: widget.controller)),
                ],
              ],
            ),
          ),
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppStyling.spaceMd,
                AppStyling.spaceSm,
                AppStyling.spaceMd,
                0,
              ),
              child: Text(
                widget.errorText!,
                style: AppStyling.bodySm.copyWith(color: AppColors.error),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppStyling.spaceMd),
              child: _tab == IssueEditTab.write
                  ? TextField(
                      controller: widget.controller,
                      maxLines: null,
                      expands: true,
                      style: AppStyling.mono,
                      decoration: const InputDecoration(border: InputBorder.none),
                    )
                  : SingleChildScrollView(
                      child: MarkdownIssueBody(
                        content: _frontmatterParser.splitBody(widget.controller.text),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
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
          vertical: AppStyling.spaceSm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceRaised : Colors.transparent,
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
          border: selected ? Border.all(color: AppColors.accent) : null,
        ),
        child: Text(
          label,
          style: AppStyling.bodySm.copyWith(
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
