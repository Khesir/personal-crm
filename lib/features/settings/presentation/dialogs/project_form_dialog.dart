import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/projects_controller.dart';
import '../../domain/helper/project_slug.dart';
import '../../domain/model/project.dart';

const _kDialogWidth = 480.0;

class ProjectFormDialog extends StatefulWidget {
  final ProjectsController controller;
  final Project? project;

  const ProjectFormDialog({super.key, required this.controller, this.project});

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _pathCtrl;
  late bool _hasBugReports;
  late bool _hasAnnouncements;
  bool _saving = false;

  bool get _isEditing => widget.project != null;

  String get _previewKey {
    final name = _nameCtrl.text;
    if (name.trim().isEmpty) return '';
    if (_isEditing) return widget.project!.projectKey;

    final existingSlugs = widget.controller.data?.map((p) => p.id) ?? const <String>[];
    return uniqueSlug(name, existingSlugs);
  }

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    _nameCtrl = TextEditingController(text: project?.name ?? '');
    _pathCtrl = TextEditingController(text: project?.localPath ?? '');
    _hasBugReports = project?.hasBugReports ?? false;
    _hasAnnouncements = project?.hasAnnouncements ?? false;
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pathCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;
    setState(() => _pathCtrl.text = path);
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final path = _pathCtrl.text.trim();
    if (name.isEmpty || path.isEmpty) return;

    setState(() => _saving = true);
    if (_isEditing) {
      await widget.controller.updateProject(
        widget.project!.id,
        name: name,
        localPath: path,
        hasBugReports: _hasBugReports,
        hasAnnouncements: _hasAnnouncements,
      );
    } else {
      await widget.controller.addProject(
        name,
        path,
        hasBugReports: _hasBugReports,
        hasAnnouncements: _hasAnnouncements,
      );
    }
    if (mounted) Navigator.of(context).pop();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyling.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isEditing ? 'Edit Project' : 'Add Project', style: AppStyling.headingMd),
              const SizedBox(height: AppStyling.spaceXl),
              _NameField(controller: _nameCtrl),
              const SizedBox(height: AppStyling.spaceLg),
              _PathField(controller: _pathCtrl, onPickDirectory: _pickDirectory),
              const SizedBox(height: AppStyling.spaceLg),
              _ProjectKeyPreview(value: _previewKey),
              const SizedBox(height: AppStyling.spaceLg),
              _ToggleRow(
                label: 'Has Bug Reports',
                value: _hasBugReports,
                onChanged: (v) => setState(() => _hasBugReports = v),
              ),
              const SizedBox(height: AppStyling.spaceSm),
              _ToggleRow(
                label: 'Has Announcements',
                value: _hasAnnouncements,
                onChanged: (v) => setState(() => _hasAnnouncements = v),
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
                    onTap: _saving ? null : _submit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyling.spaceLg,
                        vertical: AppStyling.spaceSm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : Text(
                              'Save',
                              style: AppStyling.bodySm.copyWith(
                                color: Colors.black,
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

class _NameField extends StatelessWidget {
  final TextEditingController controller;

  const _NameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Name', style: AppStyling.label),
        const SizedBox(height: AppStyling.spaceSm),
        TextField(
          controller: controller,
          style: AppStyling.bodyLg,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.all(AppStyling.spaceMd),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyling.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyling.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyling.radiusMd),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
          ),
        ),
      ],
    );
  }
}

class _PathField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPickDirectory;

  const _PathField({required this.controller, required this.onPickDirectory});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Local path', style: AppStyling.label),
        const SizedBox(height: AppStyling.spaceSm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: AppStyling.mono,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(AppStyling.spaceMd),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppStyling.spaceSm),
            GestureDetector(
              onTap: onPickDirectory,
              child: Container(
                padding: const EdgeInsets.all(AppStyling.spaceMd),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.folder_open_outlined, size: 18, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProjectKeyPreview extends StatelessWidget {
  final String value;

  const _ProjectKeyPreview({required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Project key', style: AppStyling.label),
        const SizedBox(height: AppStyling.spaceSm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppStyling.spaceMd),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppStyling.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            value.isEmpty ? '—' : value,
            style: AppStyling.monoSm.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.accent,
        ),
        const SizedBox(width: AppStyling.spaceSm),
        Text(label, style: AppStyling.bodySm),
      ],
    );
  }
}
