import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/helper/markdown_toolbar_action.dart';

const _toolbarIconSize = 16.0;

class MarkdownFormattingToolbar extends StatelessWidget {
  final TextEditingController controller;

  const MarkdownFormattingToolbar({super.key, required this.controller});

  void _applyAction(MarkdownToolbarAction action) {
    final result = applyMarkdownAction(controller.text, controller.selection, action);
    controller.value = TextEditingValue(text: result.text, selection: result.selection);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ToolbarIconButton(
          icon: Icons.format_bold,
          tooltip: 'Bold',
          onTap: () => _applyAction(MarkdownToolbarAction.bold),
        ),
        _ToolbarIconButton(
          icon: Icons.format_italic,
          tooltip: 'Italic',
          onTap: () => _applyAction(MarkdownToolbarAction.italic),
        ),
        _ToolbarIconButton(
          icon: Icons.format_quote,
          tooltip: 'Quote',
          onTap: () => _applyAction(MarkdownToolbarAction.quote),
        ),
        _ToolbarIconButton(
          icon: Icons.code,
          tooltip: 'Code',
          onTap: () => _applyAction(MarkdownToolbarAction.code),
        ),
        _ToolbarIconButton(
          icon: Icons.link,
          tooltip: 'Link',
          onTap: () => _applyAction(MarkdownToolbarAction.link),
        ),
        _ToolbarIconButton(
          icon: Icons.format_list_bulleted,
          tooltip: 'Bulleted list',
          onTap: () => _applyAction(MarkdownToolbarAction.bulletedList),
        ),
        _ToolbarIconButton(
          icon: Icons.format_list_numbered,
          tooltip: 'Numbered list',
          onTap: () => _applyAction(MarkdownToolbarAction.numberedList),
        ),
        _ToolbarIconButton(
          icon: Icons.checklist,
          tooltip: 'Task list',
          onTap: () => _applyAction(MarkdownToolbarAction.taskList),
        ),
      ],
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppStyling.spaceSm),
          child: Icon(icon, size: _toolbarIconSize, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
