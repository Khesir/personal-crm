import 'package:flutter/material.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/core/ui/desktop_title_bar.dart';
import 'package:crm/features/home/api.dart';
import 'package:crm/features/kanban/api.dart';
import 'package:crm/features/projects/api.dart';
import 'package:crm/features/settings/api.dart';
import '../../domain/controller/shell_controller.dart';
import '../state/shell_state.dart';
import '../widget/app_rail.dart';
import '../widget/app_sidebar.dart';

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
    return Scaffold(
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
                      return _ContentArea(
                        shellState: shellState,
                        controller: _controller,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentArea extends StatelessWidget {
  final ShellStateData shellState;
  final ShellController controller;

  const _ContentArea({required this.shellState, required this.controller});

  @override
  Widget build(BuildContext context) {
    return switch (shellState.selectedTab) {
      AppTab.home => const _HomePlaceholder(),
      AppTab.projects => _ProjectsPlaceholder(shellState: shellState, controller: controller),
      AppTab.settings => _SettingsContent(section: shellState.selectedSettingsSection),
    };
  }
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChatController>(
      future: createChatController(),
      builder: (context, snapshot) {
        final controller = snapshot.data;
        if (controller == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }
        return HomeChatSection(controller: controller);
      },
    );
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
    return FutureBuilder<SettingsController>(
      future: createSettingsController(),
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
  final ShellController controller;

  const _ProjectsPlaceholder({required this.shellState, required this.controller});

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
              controller: controller,
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
  final ShellController controller;
  final Project? selectedProject;

  const _ProjectsContent({
    required this.shellState,
    required this.controller,
    required this.selectedProject,
  });

  @override
  State<_ProjectsContent> createState() => _ProjectsContentState();
}

class _ProjectsContentState extends State<_ProjectsContent> {
  late IssuesController _issuesController;
  String? _loadedLocalPath;
  String? _selectedIssueId;
  AnnouncementsController? _announcementsController;
  String? _announcementsProjectKey;
  BugReportsController? _bugReportsController;
  String? _bugReportsProjectKey;

  @override
  void initState() {
    super.initState();
    _issuesController = createIssuesController();
    _loadIssuesIfNeeded();
    _ensureAnnouncementsController();
    _ensureBugReportsController();
  }

  @override
  void didUpdateWidget(covariant _ProjectsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadIssuesIfNeeded();
    _ensureAnnouncementsController();
    _ensureBugReportsController();
  }

  @override
  void dispose() {
    _issuesController.dispose();
    _announcementsController?.dispose();
    _bugReportsController?.dispose();
    super.dispose();
  }

  void _loadIssuesIfNeeded() {
    final localPath = widget.selectedProject?.localPath;
    if (localPath != null && localPath != _loadedLocalPath) {
      _loadedLocalPath = localPath;
      _issuesController.load(localPath);
    }
  }

  void _ensureAnnouncementsController() {
    final projectKey = widget.selectedProject?.projectKey;
    if (projectKey == null || projectKey == _announcementsProjectKey) return;
    _announcementsProjectKey = projectKey;
    _announcementsController?.dispose();
    _announcementsController = createAnnouncementsController(projectKey);
    _announcementsController!.load();
  }

  void _ensureBugReportsController() {
    final projectKey = widget.selectedProject?.projectKey;
    if (projectKey == null || projectKey == _bugReportsProjectKey) return;
    _bugReportsProjectKey = projectKey;
    _bugReportsController?.dispose();
    _bugReportsController = createBugReportsController(projectKey);
    _bugReportsController!.load();
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
    final shellState = widget.shellState;
    final controller = widget.controller;
    final showingIssueDetail = _selectedIssueId != null;
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!showingIssueDetail)
            Padding(
              padding: const EdgeInsets.all(AppStyling.spaceXl),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project?.name ?? 'Projects', style: AppStyling.pageTitle),
                      const SizedBox(height: AppStyling.spaceXs),
                      Text(
                        project == null
                            ? 'Select a project to see its kanban board.'
                            : 'Manage this project\'s work.',
                        style: AppStyling.pageSub,
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (project != null &&
                      shellState.selectedProjectSection == ProjectSection.kanban) ...[
                    _RescanButton(onPressed: _rescan),
                    const SizedBox(width: AppStyling.spaceMd),
                  ],
                  if (project != null)
                    _ProjectSectionSwitcher(
                      project: project,
                      selected: shellState.selectedProjectSection,
                      onSelect: controller.selectProjectSection,
                    ),
                ],
              ),
            ),
          Expanded(
            child: project == null
                ? Center(
                    child: Text('No project selected.', style: AppStyling.bodySm),
                  )
                : _ProjectSectionContent(
                    section: shellState.selectedProjectSection,
                    issuesController: _issuesController,
                    selectedIssueId: _selectedIssueId,
                    onIssueTap: _openIssue,
                    onCloseIssue: _closeIssue,
                    announcementsController: _announcementsController,
                    bugReportsController: _bugReportsController,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProjectSectionContent extends StatelessWidget {
  final ProjectSection section;
  final IssuesController issuesController;
  final String? selectedIssueId;
  final void Function(Issue issue) onIssueTap;
  final VoidCallback onCloseIssue;
  final AnnouncementsController? announcementsController;
  final BugReportsController? bugReportsController;

  const _ProjectSectionContent({
    required this.section,
    required this.issuesController,
    required this.selectedIssueId,
    required this.onIssueTap,
    required this.onCloseIssue,
    required this.announcementsController,
    required this.bugReportsController,
  });

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      ProjectSection.kanban => _KanbanOrDetail(
          issuesController: issuesController,
          selectedIssueId: selectedIssueId,
          onIssueTap: onIssueTap,
          onCloseIssue: onCloseIssue,
        ),
      ProjectSection.bugReports => bugReportsController == null
          ? Center(
              child: Text('Loading bug reports...', style: AppStyling.bodySm),
            )
          : BugReportsSection(controller: bugReportsController!),
      ProjectSection.announcements => announcementsController == null
          ? Center(
              child: Text('Loading announcements...', style: AppStyling.bodySm),
            )
          : AnnouncementsSection(controller: announcementsController!),
    };
  }
}

class _KanbanOrDetail extends StatelessWidget {
  final IssuesController issuesController;
  final String? selectedIssueId;
  final void Function(Issue issue) onIssueTap;
  final VoidCallback onCloseIssue;

  const _KanbanOrDetail({
    required this.issuesController,
    required this.selectedIssueId,
    required this.onIssueTap,
    required this.onCloseIssue,
  });

  @override
  Widget build(BuildContext context) {
    final issueId = selectedIssueId;
    if (issueId == null) {
      return KanbanSection(controller: issuesController, onIssueTap: onIssueTap);
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

class _ProjectSectionSwitcher extends StatelessWidget {
  final Project project;
  final ProjectSection selected;
  final void Function(ProjectSection, {Set<ProjectSection>? enabledSections}) onSelect;

  const _ProjectSectionSwitcher({
    required this.project,
    required this.selected,
    required this.onSelect,
  });

  Set<ProjectSection> get _enabledSections => {
        ProjectSection.kanban,
        if (project.hasBugReports) ProjectSection.bugReports,
        if (project.hasAnnouncements) ProjectSection.announcements,
      };

  @override
  Widget build(BuildContext context) {
    final enabled = _enabledSections;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final section in ProjectSection.values)
            if (enabled.contains(section))
              _Pill(
                label: section.label,
                selected: selected == section,
                onTap: () => onSelect(section, enabledSections: enabled),
              ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceMd,
          vertical: AppStyling.spaceXs,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentBg : Colors.transparent,
          borderRadius: BorderRadius.circular(AppStyling.radiusSm),
        ),
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
