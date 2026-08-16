import 'dart:io' show File, Platform, Process;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/settings/api.dart';
import '../../domain/controller/shell_controller.dart';
import '../state/shell_state.dart';

/// The project rail: a Discord-server-list-style icon strip with one icon
/// per registered [Project] (initials in a deterministically-colored
/// circle), a "+" button to register a project, and the Settings gear
/// pinned at the bottom. See
/// `docs/adr/0003-discord-style-project-rail.md`.
class AppRail extends StatelessWidget {
  final ShellController controller;
  final ProjectsController projectsController;

  const AppRail({
    super.key,
    required this.controller,
    required this.projectsController,
  });

  void _openAddProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ProjectFormDialog(controller: projectsController),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ShellStateData>(
      stream: controller.stream,
      initialData: controller.state,
      builder: (context, snapshot) {
        final shellState = snapshot.data!;
        return Container(
          width: AppStyling.railWidth,
          color: AppColors.titlebarBackground,
          child: Column(
            children: [
              const SizedBox(height: AppStyling.spaceMd),
              Expanded(
                child: AsyncStreamBuilder<List<Project>>(
                  state: projectsController,
                  loadingBuilder: (context) => const SizedBox.shrink(),
                  builder: (context, projects) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final project in projects)
                            _ProjectRailItem(
                              key: ValueKey(project.id),
                              project: project,
                              projectsController: projectsController,
                              selected: !shellState.showingSettings &&
                                  project.id == shellState.selectedProjectId,
                              onTap: () {
                                controller.selectProject(project.id);
                                projectsController.refreshFromDisk(project.id);
                              },
                            ),
                          _AddProjectButton(
                            onTap: () => _openAddProjectDialog(context),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _SettingsRailItem(
                selected: shellState.showingSettings,
                onTap: controller.openSettings,
              ),
              const SizedBox(height: AppStyling.spaceMd),
            ],
          ),
        );
      },
    );
  }
}

enum _ProjectRailMenuAction { edit, remove, reveal }

/// A project's avatar content: its `.avyn/<iconFileName>` image if set,
/// otherwise initials-in-a-colored-circle (see `project_avatar.dart`).
class _ProjectAvatar extends StatelessWidget {
  final Project project;

  const _ProjectAvatar({required this.project});

  @override
  Widget build(BuildContext context) {
    final iconFileName = project.iconFileName;
    if (iconFileName != null) {
      final iconFile = File(p.join(project.localPath, '.avyn', iconFileName));
      if (iconFile.existsSync()) {
        return ClipOval(
          child: Image.file(
            iconFile,
            width: 36,
            height: 36,
            fit: BoxFit.cover,
          ),
        );
      }
    }
    return Center(
      child: Text(
        projectAvatarInitials(project.name),
        style: AppStyling.bodySm.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProjectRailItem extends StatefulWidget {
  final Project project;
  final ProjectsController projectsController;
  final bool selected;
  final VoidCallback onTap;

  const _ProjectRailItem({
    super.key,
    required this.project,
    required this.projectsController,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ProjectRailItem> createState() => _ProjectRailItemState();
}

class _ProjectRailItemState extends State<_ProjectRailItem> {
  bool _hovered = false;

  Future<void> _showContextMenu(BuildContext context, Offset globalPosition) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final action = await showMenu<_ProjectRailMenuAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        overlay.size.width - globalPosition.dx,
        overlay.size.height - globalPosition.dy,
      ),
      color: AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      items: [
        const PopupMenuItem(value: _ProjectRailMenuAction.edit, child: Text('Edit')),
        PopupMenuItem(
          value: _ProjectRailMenuAction.remove,
          child: Text('Remove', style: TextStyle(color: AppColors.error)),
        ),
        const PopupMenuItem(value: _ProjectRailMenuAction.reveal, child: Text('Reveal in explorer')),
      ],
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _ProjectRailMenuAction.edit:
        await showDialog(
          context: context,
          builder: (_) => ProjectFormDialog(
            controller: widget.projectsController,
            project: widget.project,
          ),
        );
      case _ProjectRailMenuAction.remove:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => RemoveProjectConfirmDialog(projectName: widget.project.name),
        );
        if (confirmed == true) {
          await widget.projectsController.removeProject(widget.project.id);
        }
      case _ProjectRailMenuAction.reveal:
        _revealInExplorer(widget.project.localPath);
    }
  }

  void _revealInExplorer(String localPath) {
    if (Platform.isWindows) {
      Process.run('explorer.exe', [localPath]);
    } else if (Platform.isMacOS) {
      Process.run('open', [localPath]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.project.name,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: AppStyling.spaceXs),
            width: AppStyling.railWidth,
            height: AppStyling.railWidth - AppStyling.spaceLg,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: widget.selected ? AppColors.accent : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: projectAvatarColor(widget.project.id),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.selected
                        ? AppColors.accentLight
                        : _hovered
                            ? AppColors.textSecondary
                            : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: _ProjectAvatar(project: widget.project),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddProjectButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AddProjectButton({required this.onTap});

  @override
  State<_AddProjectButton> createState() => _AddProjectButtonState();
}

class _AddProjectButtonState extends State<_AddProjectButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add project',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: AppStyling.spaceXs),
            width: AppStyling.railWidth,
            height: AppStyling.railWidth - AppStyling.spaceLg,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _hovered ? AppColors.surfaceElevated : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: const Icon(
                  Icons.add,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsRailItem extends StatefulWidget {
  final bool selected;
  final VoidCallback onTap;

  const _SettingsRailItem({required this.selected, required this.onTap});

  @override
  State<_SettingsRailItem> createState() => _SettingsRailItemState();
}

class _SettingsRailItemState extends State<_SettingsRailItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Settings',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: AppStyling.spaceXs),
            width: AppStyling.railWidth,
            height: AppStyling.railWidth - AppStyling.spaceLg,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: widget.selected ? AppColors.accent : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.selected
                      ? AppColors.accentBg
                      : _hovered
                          ? AppColors.surfaceElevated
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                ),
                child: Icon(
                  Icons.settings_outlined,
                  size: 20,
                  color: widget.selected ? AppColors.accentLight : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
