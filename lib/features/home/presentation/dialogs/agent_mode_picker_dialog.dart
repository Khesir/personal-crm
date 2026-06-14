import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/settings/domain/model/project.dart';
import '../../domain/model/cookbook_entry.dart';

const _kDialogWidth = 420.0;

/// The project + tool-capable model chosen via [AgentModePickerDialog].
class AgentModeSelection {
  final Project project;
  final CookbookEntry entry;
  final bool shellAccessEnabled;

  const AgentModeSelection({
    required this.project,
    required this.entry,
    this.shellAccessEnabled = false,
  });
}

/// Picks a registered [Project] and a tool-capable [CookbookEntry], used by
/// both the "New chat" Agent-mode flow and "Branch into agent mode".
///
/// [cookbook] must already be filtered to `supportsTools == true` entries.
class AgentModePickerDialog extends StatefulWidget {
  final List<Project> projects;
  final List<CookbookEntry> cookbook;

  const AgentModePickerDialog({
    super.key,
    required this.projects,
    required this.cookbook,
  });

  static Future<AgentModeSelection?> show(
    BuildContext context, {
    required List<Project> projects,
    required List<CookbookEntry> cookbook,
  }) {
    return showDialog<AgentModeSelection>(
      context: context,
      builder: (_) => AgentModePickerDialog(projects: projects, cookbook: cookbook),
    );
  }

  @override
  State<AgentModePickerDialog> createState() => _AgentModePickerDialogState();
}

class _AgentModePickerDialogState extends State<AgentModePickerDialog> {
  Project? _selectedProject;
  CookbookEntry? _selectedEntry;
  bool _shellAccessEnabled = false;

  @override
  void initState() {
    super.initState();
    _selectedProject = widget.projects.isNotEmpty ? widget.projects.first : null;
    _selectedEntry = recommendedCookbookEntry(widget.cookbook) ??
        (widget.cookbook.isNotEmpty ? widget.cookbook.first : null);
  }

  bool get _canConfirm => _selectedProject != null && _selectedEntry != null;

  void _confirm() {
    final project = _selectedProject;
    final entry = _selectedEntry;
    if (project == null || entry == null) return;
    Navigator.of(context).pop(AgentModeSelection(
      project: project,
      entry: entry,
      shellAccessEnabled: _shellAccessEnabled,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyling.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: SizedBox(
        width: _kDialogWidth,
        child: Padding(
          padding: const EdgeInsets.all(AppStyling.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Agent mode', style: AppStyling.headingMd),
              const SizedBox(height: AppStyling.spaceLg),
              if (widget.projects.isEmpty)
                Text(
                  'No registered projects. Add one in Settings before starting an agent-mode chat.',
                  style: AppStyling.bodySm,
                )
              else
                _ProjectPicker(
                  projects: widget.projects,
                  selected: _selectedProject,
                  onChanged: (p) => setState(() => _selectedProject = p),
                ),
              const SizedBox(height: AppStyling.spaceLg),
              if (widget.cookbook.isEmpty)
                Text(
                  'No tool-capable models available.',
                  style: AppStyling.bodySm,
                )
              else
                _ModelPicker(
                  entries: widget.cookbook,
                  selected: _selectedEntry,
                  onChanged: (e) => setState(() => _selectedEntry = e),
                ),
              const SizedBox(height: AppStyling.spaceLg),
              _ShellAccessCheckbox(
                value: _shellAccessEnabled,
                onChanged: (value) => setState(() => _shellAccessEnabled = value),
              ),
              const SizedBox(height: AppStyling.spaceXl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: AppStyling.bodySm),
                  ),
                  const SizedBox(width: AppStyling.spaceLg),
                  GestureDetector(
                    onTap: _canConfirm ? _confirm : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyling.spaceLg,
                        vertical: AppStyling.spaceSm,
                      ),
                      decoration: BoxDecoration(
                        color: _canConfirm ? AppColors.accent : AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                      ),
                      child: Text(
                        'Create',
                        style: AppStyling.bodySm.copyWith(
                          color: _canConfirm ? Colors.black : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellAccessCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ShellAccessCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: AppColors.accent,
            onChanged: (checked) => onChanged(checked ?? false),
          ),
          const SizedBox(width: AppStyling.spaceSm),
          Text('Shell access', style: AppStyling.bodySm),
        ],
      ),
    );
  }
}

class _ProjectPicker extends StatelessWidget {
  final List<Project> projects;
  final Project? selected;
  final ValueChanged<Project?> onChanged;

  const _ProjectPicker({
    required this.projects,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Project', style: AppStyling.label),
        const SizedBox(height: AppStyling.spaceSm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceMd),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppStyling.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Project>(
              value: selected,
              isExpanded: true,
              dropdownColor: AppColors.surfaceElevated,
              style: AppStyling.bodyLg,
              items: [
                for (final project in projects)
                  DropdownMenuItem(value: project, child: Text(project.name)),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModelPicker extends StatelessWidget {
  final List<CookbookEntry> entries;
  final CookbookEntry? selected;
  final ValueChanged<CookbookEntry?> onChanged;

  const _ModelPicker({
    required this.entries,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Model', style: AppStyling.label),
        const SizedBox(height: AppStyling.spaceSm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceMd),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppStyling.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CookbookEntry>(
              value: selected,
              isExpanded: true,
              dropdownColor: AppColors.surfaceElevated,
              style: AppStyling.bodyLg,
              items: [
                for (final entry in entries)
                  DropdownMenuItem(
                    value: entry,
                    child: Text('${entry.cardName} · ${entry.model}'),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
