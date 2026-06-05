import 'package:flutter/material.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/portfolio/domain/controller/portfolio_content_controller.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_blog.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_experience.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_post.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_project.dart';

// ── Shared list UI ────────────────────────────────────────────────────────────

class _CmsListSection<T> extends StatelessWidget {
  final String title;
  final StreamState<AsyncState<List<T>>> ctrl;
  final VoidCallback onRefresh;
  final String Function(T) titleOf;
  final String? Function(T) subtitleOf;
  final bool Function(T) isDraft;
  final List<_Action<T>> actions;

  const _CmsListSection({
    super.key,
    required this.title,
    required this.ctrl,
    required this.onRefresh,
    required this.titleOf,
    required this.subtitleOf,
    required this.isDraft,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppStyling.spaceXl, AppStyling.spaceXl, AppStyling.spaceXl, AppStyling.spaceLg,
          ),
          child: Row(
            children: [
              Text(title, style: AppStyling.displayMd),
              const Spacer(),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 18, color: AppColors.textSecondary),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        Container(height: 1, color: AppColors.border),
        Expanded(
          child: StreamBuilder<AsyncState<List<T>>>(
            stream: ctrl.stream,
            initialData: ctrl.state,
            builder: (context, snap) {
              final state = snap.data!;
              if (state is AsyncLoading) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              if (state is AsyncError<List<T>>) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message, style: AppStyling.bodySm.copyWith(color: AppColors.error)),
                      const SizedBox(height: AppStyling.spaceLg),
                      TextButton(onPressed: onRefresh, child: const Text('Retry')),
                    ],
                  ),
                );
              }
              final items = (state as AsyncData<List<T>>).data;
              if (items.isEmpty) {
                return Center(
                  child: Text('No $title yet', style: AppStyling.bodySm),
                );
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => Container(height: 1, color: AppColors.borderSubtle),
                itemBuilder: (context, i) => _ListItem(
                  item: items[i],
                  title: titleOf(items[i]),
                  subtitle: subtitleOf(items[i]),
                  draft: isDraft(items[i]),
                  actions: actions,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ListItem<T> extends StatefulWidget {
  final T item;
  final String title;
  final String? subtitle;
  final bool draft;
  final List<_Action<T>> actions;

  const _ListItem({
    required this.item,
    required this.title,
    required this.subtitle,
    required this.draft,
    required this.actions,
  });

  @override
  State<_ListItem<T>> createState() => _ListItemState<T>();
}

class _ListItemState<T> extends State<_ListItem<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered ? AppColors.surfaceElevated : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceXl,
          vertical: AppStyling.spaceMd,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.title,
                          style: AppStyling.bodyLg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.draft) ...[
                        const SizedBox(width: AppStyling.spaceSm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppStyling.radiusSm),
                          ),
                          child: Text(
                            'draft',
                            style: AppStyling.monoSm.copyWith(color: AppColors.warning),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: AppStyling.bodySm,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<int>(
              icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.textSecondary),
              color: AppColors.surfaceElevated,
              itemBuilder: (_) => widget.actions.asMap().entries.map((e) {
                final a = e.value;
                return PopupMenuItem<int>(
                  value: e.key,
                  child: Row(
                    children: [
                      Icon(a.icon, size: 16, color: a.destructive ? AppColors.error : AppColors.textSecondary),
                      const SizedBox(width: AppStyling.spaceSm),
                      Text(
                        a.label,
                        style: AppStyling.bodySm.copyWith(
                          color: a.destructive ? AppColors.error : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onSelected: (i) => widget.actions[i].onTap(widget.item),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action<T> {
  final String label;
  final IconData icon;
  final bool destructive;
  final Future<void> Function(T) onTap;

  const _Action({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });
}

// ── Blogs section ─────────────────────────────────────────────────────────────

class PortfolioBlogsSection extends StatelessWidget {
  final PortfolioBlogController ctrl;

  const PortfolioBlogsSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _CmsListSection<PortfolioBlog>(
      title: 'Blogs',
      ctrl: ctrl,
      onRefresh: ctrl.load,
      titleOf: (b) => b.name,
      subtitleOf: (b) {
        final parts = <String>[];
        if (b.releasedDate != null && b.releasedDate!.isNotEmpty) parts.add(b.releasedDate!);
        if (b.minRead != null) parts.add('${b.minRead} min read');
        if (b.tags.isNotEmpty) parts.add(b.tags.take(3).join(', '));
        return parts.join(' · ');
      },
      isDraft: (b) => b.draft,
      actions: [
        _Action(
          label: 'Toggle Draft',
          icon: Icons.edit_outlined,
          onTap: (b) => ctrl.toggleDraft(b.id, !b.draft),
        ),
        _Action(
          label: 'Delete',
          icon: Icons.delete_outline,
          destructive: true,
          onTap: (b) => ctrl.delete(b.id),
        ),
      ],
    );
  }
}

// ── Projects section ──────────────────────────────────────────────────────────

class PortfolioProjectsSection extends StatelessWidget {
  final PortfolioProjectController ctrl;

  const PortfolioProjectsSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _CmsListSection<PortfolioProject>(
      title: 'Projects',
      ctrl: ctrl,
      onRefresh: ctrl.load,
      titleOf: (p) => p.name,
      subtitleOf: (p) {
        final parts = <String>[];
        if (p.releasedDate != null && p.releasedDate!.isNotEmpty) parts.add(p.releasedDate!);
        if (p.languages.isNotEmpty) parts.add(p.languages.take(4).join(', '));
        if (p.pinned) parts.add('📌 pinned');
        return parts.join(' · ');
      },
      isDraft: (p) => p.draft,
      actions: [
        _Action(
          label: 'Toggle Draft',
          icon: Icons.edit_outlined,
          onTap: (p) => ctrl.toggleDraft(p.id, !p.draft),
        ),
        _Action(
          label: 'Toggle Pinned',
          icon: Icons.push_pin_outlined,
          onTap: (p) => ctrl.togglePinned(p.id, !p.pinned),
        ),
        _Action(
          label: 'Delete',
          icon: Icons.delete_outline,
          destructive: true,
          onTap: (p) => ctrl.delete(p.id),
        ),
      ],
    );
  }
}

// ── Experiences section ───────────────────────────────────────────────────────

class PortfolioExperiencesSection extends StatelessWidget {
  final PortfolioExperienceController ctrl;

  const PortfolioExperiencesSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _CmsListSection<PortfolioExperience>(
      title: 'Experiences',
      ctrl: ctrl,
      onRefresh: ctrl.load,
      titleOf: (e) => '${e.position} @ ${e.companyName}',
      subtitleOf: (e) =>
          '${e.jobType} · ${e.employmentType} · ${e.durationStart}${e.durationEnd != null && e.durationEnd!.isNotEmpty ? " – ${e.durationEnd}" : " – Present"}',
      isDraft: (e) => e.draft,
      actions: [
        _Action(
          label: 'Toggle Draft',
          icon: Icons.edit_outlined,
          onTap: (e) => ctrl.toggleDraft(e.id, !e.draft),
        ),
        _Action(
          label: 'Delete',
          icon: Icons.delete_outline,
          destructive: true,
          onTap: (e) => ctrl.delete(e.id),
        ),
      ],
    );
  }
}

// ── Posts section ─────────────────────────────────────────────────────────────

class PortfolioPostsSection extends StatelessWidget {
  final PortfolioPostController ctrl;

  const PortfolioPostsSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _CmsListSection<PortfolioPost>(
      title: 'Posts',
      ctrl: ctrl,
      onRefresh: ctrl.load,
      titleOf: (p) => p.content.length > 120 ? '${p.content.substring(0, 120)}…' : p.content,
      subtitleOf: (p) {
        final parts = <String>[];
        if (p.tags.isNotEmpty) parts.add(p.tags.join(', '));
        if (p.pinned) parts.add('📌 pinned');
        return parts.isNotEmpty ? parts.join(' · ') : null;
      },
      isDraft: (p) => p.draft,
      actions: [
        _Action(
          label: 'Toggle Draft',
          icon: Icons.edit_outlined,
          onTap: (p) => ctrl.toggleDraft(p.id, !p.draft),
        ),
        _Action(
          label: 'Toggle Pinned',
          icon: Icons.push_pin_outlined,
          onTap: (p) => ctrl.togglePinned(p.id, !p.pinned),
        ),
        _Action(
          label: 'Delete',
          icon: Icons.delete_outline,
          destructive: true,
          onTap: (p) => ctrl.delete(p.id),
        ),
      ],
    );
  }
}
