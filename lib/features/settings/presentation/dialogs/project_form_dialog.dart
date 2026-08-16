import 'dart:io' show File;

import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/kanban/api.dart';
import '../../domain/controller/projects_controller.dart';
import '../../domain/helper/project_avatar.dart';
import '../../domain/helper/project_slug.dart';
import '../../domain/model/project.dart';

const _kDialogWidth = 480.0;

/// Which tab is active in Add mode. Edit mode never shows the toggle and
/// always behaves as [_AddTab.open] (i.e. editing the registered path).
enum _AddTab { open, create }

class ProjectFormDialog extends StatefulWidget {
  final ProjectsController controller;
  final Project? project;

  /// Directory-picker hook; defaults to the native OS picker
  /// (`file_selector`'s `getDirectoryPath`), resolved lazily at call time
  /// rather than in the constructor so building this widget never touches
  /// the file_selector plugin (which e.g. has no test-environment
  /// implementation). Overridable so tests don't have to drive the real,
  /// blocking, native folder dialog.
  ///
  /// Deliberately `file_selector`, not `file_picker` — the latter's
  /// `getDirectoryPath()` crashes the whole app on Windows with "Lost
  /// connection to device" (a known, widely-reported native-level bug:
  /// https://github.com/flutter/flutter/issues/129005). `file_selector`
  /// (the official Flutter-team plugin) does not have this problem.
  final Future<String?> Function()? pickDirectory;

  /// Scaffolds `issues/{backlog,ready,in-progress,qa,done}/` inside a
  /// newly-created project folder; defaults to
  /// `createIssuesRepository().initializeIssuesFolder`, resolved lazily at
  /// call time for the same reason as [pickDirectory] — real IO Futures
  /// kicked off from a widget callback don't resolve under
  /// `WidgetTester.pumpAndSettle`'s fake-clock pumping, so tests must be
  /// able to swap this for a fake.
  final Future<void> Function(String localPath)? initializeIssuesFolder;

  /// Image-picker hook for the icon upload control (Edit mode only);
  /// defaults to `file_selector`'s `openFile` restricted to common image
  /// extensions, resolved lazily at call time for the same reason as
  /// [pickDirectory]. Overridable so tests don't have to drive the real
  /// native file dialog.
  final Future<String?> Function()? pickImage;

  const ProjectFormDialog({
    super.key,
    required this.controller,
    this.project,
    this.pickDirectory,
    this.initializeIssuesFolder,
    this.pickImage,
  });

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _pathCtrl;
  late final TextEditingController _parentPathCtrl;
  _AddTab _tab = _AddTab.open;
  bool _saving = false;
  String? _duplicatePathError;
  String? _folderCollisionError;
  String? _iconFileName;
  bool _iconBusy = false;
  /// A locally-picked image file not yet applied — used in Add mode, where
  /// there's no registered project to write `.avyn/icon.*` into until
  /// submit succeeds. Applied to the newly-created/registered project right
  /// after a successful [ProjectSaveSuccess].
  String? _pendingIconPath;

  bool get _isEditing => widget.project != null;

  String get _previewKey {
    final name = _nameCtrl.text;
    if (name.trim().isEmpty) return '';
    if (_isEditing) return widget.project!.projectKey;

    final existingSlugs = widget.controller.data?.map((p) => p.id) ?? const <String>[];
    return uniqueSlug(name, existingSlugs);
  }

  /// Live preview of the exact `<parent>/<slug>/` path that Create mode will
  /// create on submit. Empty until both the name and parent folder are set.
  String get _createPreviewPath {
    final parent = _parentPathCtrl.text.trim();
    final slug = _previewKey;
    if (parent.isEmpty || slug.isEmpty) return '';
    return '${p.join(parent, slug)}${p.separator}';
  }

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    _nameCtrl = TextEditingController(text: project?.name ?? '');
    _pathCtrl = TextEditingController(text: project?.localPath ?? '');
    _parentPathCtrl = TextEditingController();
    _iconFileName = project?.iconFileName;
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pathCtrl.dispose();
    _parentPathCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDirectory() async {
    final picker = widget.pickDirectory ?? file_selector.getDirectoryPath;
    final path = await picker();
    if (path == null) return;
    setState(() {
      _pathCtrl.text = path;
      _duplicatePathError = null;
    });
  }

  Future<void> _pickParentDirectory() async {
    final picker = widget.pickDirectory ?? file_selector.getDirectoryPath;
    final path = await picker();
    if (path == null) return;
    setState(() {
      _parentPathCtrl.text = path;
      _folderCollisionError = null;
    });
  }

  static Future<String?> _defaultPickImage() async {
    const typeGroup = file_selector.XTypeGroup(
      label: 'images',
      extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'],
    );
    final file = await file_selector.openFile(acceptedTypeGroups: [typeGroup]);
    return file?.path;
  }

  /// In Edit mode, icon changes are immediate side effects on the
  /// already-registered [widget.project] — not deferred to the Save button,
  /// unlike name/path — so a re-open of this dialog, or the rail/Settings
  /// list, reflects them right away without an extra save step. In Add
  /// mode (no project registered yet), the picked path is stashed in
  /// [_pendingIconPath] and applied by [_submit] after a successful save.
  Future<void> _pickIcon() async {
    final picker = widget.pickImage ?? _defaultPickImage;
    final path = await picker();
    if (path == null) return;

    if (!_isEditing) {
      setState(() => _pendingIconPath = path);
      return;
    }

    final project = widget.project!;
    setState(() => _iconBusy = true);
    await widget.controller.setProjectIcon(project.id, path);
    if (!mounted) return;
    setState(() {
      _iconFileName = _currentIconFileName(project.id);
      _iconBusy = false;
    });
  }

  Future<void> _removeIcon() async {
    if (!_isEditing) {
      setState(() => _pendingIconPath = null);
      return;
    }

    final project = widget.project!;
    setState(() => _iconBusy = true);
    await widget.controller.removeProjectIcon(project.id);
    if (!mounted) return;
    setState(() {
      _iconFileName = null;
      _iconBusy = false;
    });
  }

  /// Applies a pending Add-mode icon selection to the just-registered
  /// [project]. Best-effort — a failure here must not undo an
  /// already-successful registration.
  Future<void> _applyPendingIcon(Project project) async {
    final pending = _pendingIconPath;
    if (pending == null) return;
    try {
      await widget.controller.setProjectIcon(project.id, pending);
    } catch (_) {
      // Registration already succeeded; the icon is a nice-to-have.
    }
  }

  String? _currentIconFileName(String id) {
    final projects = widget.controller.data ?? const <Project>[];
    for (final project in projects) {
      if (project.id == id) return project.iconFileName;
    }
    return null;
  }

  void _setTab(_AddTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
  }

  bool get _canSubmit {
    if (!_isEditing && _tab == _AddTab.create) return _folderCollisionError == null;
    return _duplicatePathError == null;
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || !_canSubmit) return;

    if (_isEditing) {
      final path = _pathCtrl.text.trim();
      if (path.isEmpty) return;
      setState(() => _saving = true);
      await widget.controller.updateProject(
        widget.project!.id,
        name: name,
        localPath: path,
      );
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (_tab == _AddTab.create) {
      final parent = _parentPathCtrl.text.trim();
      if (parent.isEmpty) return;
      setState(() => _saving = true);

      final result = await widget.controller.createProject(name, parent);
      switch (result) {
        case ProjectSaveSuccess(project: final project):
          final initFolder = widget.initializeIssuesFolder ??
              (localPath) => createIssuesRepository().initializeIssuesFolder(localPath);
          try {
            await initFolder(project.localPath);
          } catch (_) {
            // The project is already created and registered; scaffolding
            // issues/ is a nice-to-have and must not leave the dialog stuck.
          }
          await _applyPendingIcon(project);
          if (mounted) Navigator.of(context).pop();
        case ProjectSaveDuplicatePath():
          // createProject never returns this variant; unreachable.
          if (mounted) setState(() => _saving = false);
        case ProjectSaveFolderCollision(path: final collidingPath):
          if (mounted) {
            setState(() {
              _saving = false;
              _folderCollisionError = 'A folder named "${p.basename(collidingPath)}" already exists here';
            });
          }
      }
      return;
    }

    final path = _pathCtrl.text.trim();
    if (path.isEmpty) return;
    setState(() => _saving = true);

    final result = await widget.controller.addProject(name, path);
    switch (result) {
      case ProjectSaveSuccess(project: final project):
        await _applyPendingIcon(project);
        if (mounted) Navigator.of(context).pop();
      case ProjectSaveDuplicatePath(existing: final existing):
        if (mounted) {
          setState(() {
            _saving = false;
            _duplicatePathError = 'This folder is already registered as "${existing.name}"';
          });
        }
      case ProjectSaveFolderCollision():
        // addProject never returns this variant; unreachable.
        if (mounted) setState(() => _saving = false);
    }
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
              if (!_isEditing) ...[
                _ModeToggle(value: _tab, onChanged: _setTab),
                const SizedBox(height: AppStyling.spaceLg),
              ],
              _NameField(controller: _nameCtrl),
              const SizedBox(height: AppStyling.spaceLg),
              _IconField(
                avatarSeedId: _isEditing ? widget.project!.id : _previewKey,
                avatarName: _nameCtrl.text,
                previewFile: _isEditing
                    ? (_iconFileName == null
                        ? null
                        : File(p.join(widget.project!.localPath, '.avyn', _iconFileName!)))
                    : (_pendingIconPath == null ? null : File(_pendingIconPath!)),
                busy: _iconBusy,
                onUpload: _pickIcon,
                onRemove: (_isEditing ? _iconFileName != null : _pendingIconPath != null) ? _removeIcon : null,
              ),
              const SizedBox(height: AppStyling.spaceLg),
              if (_isEditing || _tab == _AddTab.open) ...[
                _PathField(
                  label: 'Local path',
                  hintText: 'Choose a folder…',
                  controller: _pathCtrl,
                  onPickDirectory: _pickDirectory,
                  errorText: _duplicatePathError,
                ),
                const SizedBox(height: AppStyling.spaceLg),
                _ProjectKeyPreview(label: 'Project key', value: _previewKey),
              ] else ...[
                _PathField(
                  label: 'Parent folder',
                  hintText: 'Choose a parent folder…',
                  controller: _parentPathCtrl,
                  onPickDirectory: _pickParentDirectory,
                  errorText: _folderCollisionError,
                ),
                const SizedBox(height: AppStyling.spaceLg),
                _ProjectKeyPreview(label: 'Will create', value: _createPreviewPath),
              ],
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
                    onTap: (_saving || !_canSubmit) ? null : _submit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyling.spaceLg,
                        vertical: AppStyling.spaceSm,
                      ),
                      decoration: BoxDecoration(
                        color: (!_saving && !_canSubmit) ? AppColors.accent.withValues(alpha: 0.4) : AppColors.accent,
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

class _IconField extends StatelessWidget {
  /// Seeds the fallback avatar color — the project's `id` once registered,
  /// or the live slug preview while the project doesn't exist yet (Add
  /// mode).
  final String avatarSeedId;

  /// Seeds the fallback avatar initials — the name field's current text.
  final String avatarName;

  /// The image to preview: the existing `.avyn/<icon>` file in Edit mode,
  /// or a not-yet-applied locally-picked file in Add mode. `null` shows the
  /// initials fallback.
  final File? previewFile;

  final bool busy;
  final VoidCallback onUpload;
  final VoidCallback? onRemove;

  const _IconField({
    required this.avatarSeedId,
    required this.avatarName,
    required this.previewFile,
    required this.busy,
    required this.onUpload,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final file = previewFile;
    final hasIcon = file != null && file.existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Icon', style: AppStyling.label),
        const SizedBox(height: AppStyling.spaceSm),
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: projectAvatarColor(avatarSeedId),
                shape: BoxShape.circle,
              ),
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : hasIcon
                      ? ClipOval(
                          child: Image.file(file, width: 48, height: 48, fit: BoxFit.cover),
                        )
                      : Center(
                          child: Text(
                            projectAvatarInitials(avatarName),
                            style: AppStyling.bodyLg.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
            ),
            const SizedBox(width: AppStyling.spaceMd),
            GestureDetector(
              onTap: busy ? null : onUpload,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyling.spaceMd,
                  vertical: AppStyling.spaceSm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text('Upload', style: AppStyling.bodySm),
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: AppStyling.spaceSm),
              GestureDetector(
                onTap: busy ? null : onRemove,
                child: Container(
                  padding: const EdgeInsets.all(AppStyling.spaceSm),
                  child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PathField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final VoidCallback onPickDirectory;
  final String? errorText;

  const _PathField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.onPickDirectory,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final borderColor = hasError ? AppColors.error : AppColors.border;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyling.label),
        const SizedBox(height: AppStyling.spaceSm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                readOnly: true,
                showCursor: false,
                style: AppStyling.mono,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(AppStyling.spaceMd),
                  hintText: hintText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                    borderSide: BorderSide(color: hasError ? AppColors.error : AppColors.accent),
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
        if (hasError) ...[
          const SizedBox(height: AppStyling.spaceXs),
          Text(errorText!, style: AppStyling.bodySm.copyWith(color: AppColors.error)),
        ],
      ],
    );
  }
}

class _ProjectKeyPreview extends StatelessWidget {
  final String label;
  final String value;

  const _ProjectKeyPreview({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyling.label),
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

class _ModeToggle extends StatelessWidget {
  final _AddTab value;
  final ValueChanged<_AddTab> onChanged;

  const _ModeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _segment(context, 'Open existing', _AddTab.open)),
          Expanded(child: _segment(context, 'Create new', _AddTab.create)),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, String label, _AddTab tab) {
    final selected = value == tab;
    return GestureDetector(
      onTap: () => onChanged(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppStyling.spaceSm),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentBg : Colors.transparent,
          borderRadius: BorderRadius.circular(AppStyling.radiusSm),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppStyling.bodySm.copyWith(
            color: selected ? AppColors.accentLight : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
