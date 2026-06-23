import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:crm/core/di/service_locator.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/core/ui/desktop_title_bar.dart';
import 'package:crm/features/agent/api.dart';
import 'package:crm/features/home/api.dart';
import 'package:crm/features/kanban/api.dart';
import 'package:crm/features/settings/api.dart';
import '../../domain/controller/shell_controller.dart';
import '../state/shell_state.dart';
import '../widget/app_rail.dart';
import '../widget/app_sidebar.dart';
import '../widget/project_content_dock_overlay.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  late final ShellController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ShellController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DragToResizeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const DesktopTitleBar(),
            Container(height: 1, color: AppColors.border),
            Expanded(
              child: Row(
                children: [
                  AppRail(controller: _controller),
                  Container(width: 1, color: AppColors.border),
                  AppSidebar(controller: _controller),
                  Container(width: 1, color: AppColors.border),
                  Expanded(
                    child: StreamBuilder<ShellStateData>(
                      stream: _controller.stream,
                      initialData: _controller.state,
                      builder: (context, snapshot) {
                        final shellState = snapshot.data!;
                        return _ContentArea(shellState: shellState);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentArea extends StatelessWidget {
  final ShellStateData shellState;

  const _ContentArea({required this.shellState});

  @override
  Widget build(BuildContext context) {
    return switch (shellState.selectedTab) {
      AppTab.home => HomeChatSection(controller: locator.get<AgentController>()),
      AppTab.projects => _ProjectsPlaceholder(shellState: shellState),
      AppTab.settings => _SettingsContent(
        section: shellState.selectedSettingsSection,
      ),
    };
  }
}

class _SettingsContent extends StatelessWidget {
  final SettingsSection section;

  const _SettingsContent({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: switch (section) {
        SettingsSection.projects => const _SettingsProjectsContent(),
        SettingsSection.services => const _ServicesContent(),
        SettingsSection.brain => BrainSection(processRunner: createProcessRunner()),
        SettingsSection.agent => AgentSettingsSection(controller: locator.get<AgentController>()),
        SettingsSection.about => const AboutSection(),
      },
    );
  }
}

class _SettingsProjectsContent extends StatelessWidget {
  const _SettingsProjectsContent();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProjectsController>(
      future: createProjectsController(),
      builder: (context, snapshot) {
        final controller = snapshot.data;
        if (controller == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }
        return ProjectsSection(controller: controller);
      },
    );
  }
}

class _ServicesContent extends StatelessWidget {
  const _ServicesContent();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ServiceCardsController>(
      future: createServiceCardsController(),
      builder: (context, snapshot) {
        final controller = snapshot.data;
        if (controller == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }
        return ServicesSection(controller: controller);
      },
    );
  }
}

class _ProjectsPlaceholder extends StatelessWidget {
  final ShellStateData shellState;

  const _ProjectsPlaceholder({required this.shellState});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProjectsController>(
      future: createProjectsController(),
      builder: (context, snapshot) {
        final projectsController = snapshot.data;
        if (projectsController == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }
        return AsyncStreamBuilder<List<Project>>(
          state: projectsController,
          builder: (context, projects) {
            Project? selectedProject;
            for (final project in projects) {
              if (project.id == shellState.selectedProjectId) {
                selectedProject = project;
                break;
              }
            }
            return _ProjectsContent(
              shellState: shellState,
              selectedProject: selectedProject,
            );
          },
        );
      },
    );
  }
}

class _ProjectsContent extends StatefulWidget {
  final ShellStateData shellState;
  final Project? selectedProject;

  const _ProjectsContent({
    required this.shellState,
    required this.selectedProject,
  });

  @override
  State<_ProjectsContent> createState() => _ProjectsContentState();
}

class _ProjectsContentState extends State<_ProjectsContent> {
  late IssuesController _issuesController;
  late IssuesWatcherController _watcherController;
  late IssuesRepository _issuesRepository;
  late DockController _dockController;
  String? _loadedLocalPath;
  String? _selectedIssueId;

  String? _selectedArchive;
  IssuesController? _archiveController;
  TerminalSessionController? _terminalSessionController;

  @override
  void initState() {
    super.initState();
    _issuesController = createIssuesController();
    _watcherController = createIssuesWatcherController(_issuesController);
    _issuesRepository = createIssuesRepository();
    _dockController = createDockController();
    _loadIssuesIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _ProjectsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadIssuesIfNeeded();
  }

  @override
  void dispose() {
    _issuesController.dispose();
    _watcherController.dispose();
    _archiveController?.dispose();
    _dockController.dispose();
    _terminalSessionController?.dispose();
    super.dispose();
  }

  void _loadIssuesIfNeeded() {
    final localPath = widget.selectedProject?.localPath;
    if (localPath != null && localPath != _loadedLocalPath) {
      _loadedLocalPath = localPath;
      _issuesController.load(localPath);
      _resetArchiveSelection();
      _ensureTerminalSessionController(localPath);
      _watcherController.start(localPath);
    }
  }

  void _ensureTerminalSessionController(String localPath) {
    _terminalSessionController?.dispose();
    _terminalSessionController = createTerminalSessionController(localPath);
  }

  void _resetArchiveSelection() {
    _archiveController?.dispose();
    _archiveController = null;
    if (_selectedArchive != null) {
      setState(() => _selectedArchive = null);
    } else {
      _selectedArchive = null;
    }
  }

  Future<List<String>> _listArchives() async {
    final localPath = widget.selectedProject?.localPath;
    if (localPath == null) return [];
    return _issuesRepository.listArchives(localPath);
  }

  void _selectArchive(String? archiveName) {
    if (archiveName == _selectedArchive) return;
    final localPath = widget.selectedProject?.localPath;
    _archiveController?.dispose();
    if (archiveName == null || localPath == null) {
      setState(() {
        _selectedArchive = null;
        _archiveController = null;
      });
      return;
    }
    final controller = createIssuesController();
    controller.loadArchive(localPath, archiveName);
    setState(() {
      _selectedArchive = archiveName;
      _archiveController = controller;
    });
  }

  void _rescan() {
    final localPath = widget.selectedProject?.localPath;
    if (localPath != null) _issuesController.load(localPath);
  }

  void _openIssue(Issue issue) {
    setState(() => _selectedIssueId = issue.id);
  }

  void _closeIssue() {
    setState(() => _selectedIssueId = null);
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.selectedProject;
    final showingIssueDetail = _selectedIssueId != null;
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!showingIssueDetail)
            Padding(
              padding: const EdgeInsets.all(AppStyling.spaceXl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project?.name ?? 'Projects',
                              style: AppStyling.pageTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppStyling.spaceXs),
                            Text(
                              project == null
                                  ? 'Select a project to see its kanban board.'
                                  : _selectedArchive != null
                                  ? 'Viewing archived board: $_selectedArchive — read-only'
                                  : 'Manage this project\'s work.',
                              style: AppStyling.pageSub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (project != null) ...[
                    const SizedBox(height: AppStyling.spaceMd),
                    Row(
                      mainAxisAlignment: _selectedArchive == null
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.start,
                      children: [
                        _ArchiveDropdown(
                          selectedArchive: _selectedArchive,
                          onOpen: _listArchives,
                          onSelect: _selectArchive,
                        ),
                        if (_selectedArchive != null) ...[
                          const SizedBox(width: AppStyling.spaceMd),
                          const _ReadOnlyBadge(),
                        ] else ...[
                          Row(
                            children: [
                              StreamStateBuilder<IssuesWatcherStateData>(
                                state: _watcherController,
                                builder: (context, data) => WatchPill(
                                  watching: data.watching,
                                  lastSyncedAt: data.lastSyncedAt,
                                ),
                              ),
                              const SizedBox(width: AppStyling.spaceMd),
                              _RescanButton(onPressed: _rescan),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: project == null
                ? Center(
                    child: Text(
                      'No project selected.',
                      style: AppStyling.bodySm,
                    ),
                  )
                : ProjectContentDockOverlay(
                    dockController: _dockController,
                    projectName: project.name,
                    showDock: _selectedArchive == null,
                    terminalSessionController: _terminalSessionController,
                    content: _KanbanOrDetail(
                      issuesController: _archiveController ?? _issuesController,
                      readOnly: _selectedArchive != null,
                      selectedIssueId: _selectedIssueId,
                      onIssueTap: _openIssue,
                      onCloseIssue: _closeIssue,
                      project: project,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _KanbanOrDetail extends StatelessWidget {
  final IssuesController issuesController;
  final bool readOnly;
  final String? selectedIssueId;
  final void Function(Issue issue) onIssueTap;
  final VoidCallback onCloseIssue;
  final Project project;

  const _KanbanOrDetail({
    required this.issuesController,
    required this.readOnly,
    required this.selectedIssueId,
    required this.onIssueTap,
    required this.onCloseIssue,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    final issueId = selectedIssueId;
    if (issueId == null) {
      return KanbanSection(
        controller: issuesController,
        onIssueTap: onIssueTap,
        readOnly: readOnly,
      );
    }

    return AsyncStreamBuilder<List<Issue>>(
      state: issuesController,
      builder: (context, issues) {
        Issue? issue;
        for (final candidate in issues) {
          if (candidate.id == issueId) {
            issue = candidate;
            break;
          }
        }
        if (issue == null) {
          return Center(
            child: Text('Issue not found.', style: AppStyling.bodySm),
          );
        }
        return IssueDetailSection(
          controller: issuesController,
          issue: issue,
          onBack: onCloseIssue,
          onDeleted: onCloseIssue,
          readOnly: readOnly,
        );
      },
    );
  }
}

class _RescanButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RescanButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceMd,
          vertical: AppStyling.spaceSm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppStyling.spaceXs),
            Text('Rescan', style: AppStyling.bodySm),
          ],
        ),
      ),
    );
  }
}

class _ArchiveDropdown extends StatefulWidget {
  final String? selectedArchive;
  final Future<List<String>> Function() onOpen;
  final void Function(String? archive) onSelect;

  const _ArchiveDropdown({
    required this.selectedArchive,
    required this.onOpen,
    required this.onSelect,
  });

  @override
  State<_ArchiveDropdown> createState() => _ArchiveDropdownState();
}

class _ArchiveChoice {
  final String? archive;

  const _ArchiveChoice(this.archive);
}

class _ArchiveDropdownState extends State<_ArchiveDropdown> {
  bool _menuOpen = false;

  Future<void> _showMenu() async {
    if (_menuOpen) return;
    _menuOpen = true;

    final box = context.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset(0, box.size.height), ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final menuShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppStyling.radiusMd),
      side: const BorderSide(color: AppColors.border),
    );

    final loadingFuture = showMenu<_ArchiveChoice>(
      context: context,
      position: position,
      color: AppColors.surfaceRaised,
      shape: menuShape,
      items: const [
        PopupMenuItem<_ArchiveChoice>(enabled: false, child: Text('Loading…')),
      ],
    );

    final archives = await widget.onOpen();
    if (!mounted) {
      _menuOpen = false;
      return;
    }
    Navigator.of(context).pop();
    await loadingFuture;
    if (!mounted) {
      _menuOpen = false;
      return;
    }

    final selected = await showMenu<_ArchiveChoice>(
      context: context,
      position: position,
      color: AppColors.surfaceRaised,
      shape: menuShape,
      items: [
        const PopupMenuItem<_ArchiveChoice>(
          value: _ArchiveChoice(null),
          child: Text('Current'),
        ),
        for (final archive in archives)
          PopupMenuItem<_ArchiveChoice>(
            value: _ArchiveChoice(archive),
            child: Text(archive),
          ),
      ],
    );

    _menuOpen = false;
    if (selected != null && mounted) {
      widget.onSelect(selected.archive);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showMenu,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceMd,
          vertical: AppStyling.spaceSm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.archive_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppStyling.spaceXs),
            Text(widget.selectedArchive ?? 'Current', style: AppStyling.bodySm),
            const SizedBox(width: AppStyling.spaceXs),
            const Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyBadge extends StatelessWidget {
  const _ReadOnlyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyling.spaceMd,
        vertical: AppStyling.spaceXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppStyling.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'Read-only',
        style: AppStyling.bodySm.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
