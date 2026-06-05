import 'package:flutter/material.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/portfolio/domain/controller/portfolio_content_controller.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_blog.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_experience.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_post.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_project.dart';

class PortfolioOverviewSection extends StatelessWidget {
  final PortfolioBlogController blogsCtrl;
  final PortfolioProjectController projectsCtrl;
  final PortfolioExperienceController experiencesCtrl;
  final PortfolioPostController postsCtrl;

  const PortfolioOverviewSection({
    super.key,
    required this.blogsCtrl,
    required this.projectsCtrl,
    required this.experiencesCtrl,
    required this.postsCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceSm, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accentPortfolio.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppStyling.radiusSm),
            ),
            child: Text('CMS', style: AppStyling.monoSm.copyWith(color: AppColors.accentPortfolio)),
          ),
          const SizedBox(height: AppStyling.spaceLg),
          Text('Portfolio', style: AppStyling.displayMd),
          const SizedBox(height: AppStyling.spaceXs),
          Text('Personal site content management', style: AppStyling.bodySm),
          const SizedBox(height: AppStyling.spaceXxl),
          Wrap(
            spacing: AppStyling.spaceLg,
            runSpacing: AppStyling.spaceLg,
            children: [
              _StatCard<PortfolioBlog>(
                label: 'Blogs',
                ctrl: blogsCtrl,
                count: (l) => l.length,
                drafts: (l) => l.where((b) => b.draft).length,
              ),
              _StatCard<PortfolioProject>(
                label: 'Projects',
                ctrl: projectsCtrl,
                count: (l) => l.length,
                drafts: (l) => l.where((p) => p.draft).length,
              ),
              _StatCard<PortfolioExperience>(
                label: 'Experiences',
                ctrl: experiencesCtrl,
                count: (l) => l.length,
                drafts: (l) => l.where((e) => e.draft).length,
              ),
              _StatCard<PortfolioPost>(
                label: 'Posts',
                ctrl: postsCtrl,
                count: (l) => l.length,
                drafts: (l) => l.where((p) => p.draft).length,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard<T> extends StatelessWidget {
  final String label;
  final StreamState<AsyncState<List<T>>> ctrl;
  final int Function(List<T>) count;
  final int Function(List<T>) drafts;

  const _StatCard({
    required this.label,
    required this.ctrl,
    required this.count,
    required this.drafts,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AsyncState<List<T>>>(
      stream: ctrl.stream,
      initialData: ctrl.state,
      builder: (context, snap) {
        final state = snap.data!;
        final total = state is AsyncData<List<T>> ? count(state.data) : 0;
        final draftCount = state is AsyncData<List<T>> ? drafts(state.data) : 0;

        return Container(
          width: 160,
          padding: const EdgeInsets.all(AppStyling.spaceLg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppStyling.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state is AsyncLoading ? '—' : '$total',
                style: AppStyling.displayMd,
              ),
              const SizedBox(height: AppStyling.spaceXs),
              Text(label, style: AppStyling.bodySm),
              if (draftCount > 0) ...[
                const SizedBox(height: AppStyling.spaceSm),
                Text(
                  '$draftCount draft${draftCount > 1 ? 's' : ''}',
                  style: AppStyling.monoSm.copyWith(color: AppColors.warning),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
