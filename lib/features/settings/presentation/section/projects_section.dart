import 'package:flutter/material.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/projects_controller.dart';
import '../../domain/model/project.dart';
import '../dialogs/project_form_dialog.dart';

class ProjectsSection extends StatelessWidget {
  final ProjectsController controller;

  const ProjectsSection({super.key, required this.controller});

  void _openAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ProjectFormDialog(controller: controller),
    );
  }

  void _openEditDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (_) => ProjectFormDialog(controller: controller, project: project),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Projects', style: AppStyling.pageTitle),
                    const SizedBox(height: AppStyling.spaceXs),
                    Text(
                      'Local repositories registered for this app to operate on.',
                      style: AppStyling.pageSub,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _openAddDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyling.spaceLg,
                    vertical: AppStyling.spaceSm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                  ),
                  child: Text(
                    'Add Project',
                    style: AppStyling.bodySm.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyling.spaceXxl),
          Expanded(
            child: AsyncStreamBuilder<List<Project>>(
              state: controller,
              builder: (context, projects) {
                if (projects.isEmpty) {
                  return Center(
                    child: Text('No projects registered yet.', style: AppStyling.bodySm),
                  );
                }
                return ListView.separated(
                  itemCount: projects.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppStyling.spaceMd),
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return _ProjectCard(
                      project: project,
                      onEdit: () => _openEditDialog(context, project),
                      onDelete: () => controller.removeProject(project.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProjectCard({required this.project, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppStyling.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(project.name, style: AppStyling.headingMd),
                    const SizedBox(width: AppStyling.spaceSm),
                    Text(
                      project.projectKey,
                      style: AppStyling.monoSm.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: AppStyling.spaceXs),
                Text(
                  project.localPath,
                  style: AppStyling.monoSm.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppStyling.spaceSm),
                Row(
                  children: [
                    if (project.hasBugReports) const _Tag(label: 'Bug Reports'),
                    if (project.hasBugReports && project.hasAnnouncements)
                      const SizedBox(width: AppStyling.spaceSm),
                    if (project.hasAnnouncements) const _Tag(label: 'Announcements'),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceSm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentBg,
        borderRadius: BorderRadius.circular(AppStyling.radiusSm),
      ),
      child: Text(
        label,
        style: AppStyling.monoSm.copyWith(color: AppColors.accentLight),
      ),
    );
  }
}
