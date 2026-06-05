import 'package:flutter/material.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/portfolio/domain/controller/portfolio_content_controller.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_config.dart';

// ── Home Config ───────────────────────────────────────────────────────────────

class PortfolioHomeConfigSection extends StatelessWidget {
  final PortfolioHomeConfigController ctrl;
  const PortfolioHomeConfigSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _ConfigShell(
      title: 'Home Config',
      subtitle: 'Portfolio homepage configuration',
      ctrl: ctrl,
      onRefresh: ctrl.load,
      builder: (config) => _HomeConfigBody(config: config),
    );
  }
}

class _HomeConfigBody extends StatelessWidget {
  final PortfolioHomeConfig config;
  const _HomeConfigBody({required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow('Name', config.name),
        _InfoRow('Role', config.role),
        _InfoRow(
          'Status',
          config.available ? 'Available' : 'Not Available',
          valueColor: config.available ? AppColors.success : AppColors.textMuted,
        ),
        _InfoRow('Contact', config.contactEmail),
        _InfoRow('Banner Title', config.bannerTitle),
        _InfoRow('Banner Subtitle', config.bannerSubtitle),
        if (config.description.isNotEmpty) ...[
          const SizedBox(height: AppStyling.spaceXl),
          Text('Description', style: AppStyling.label),
          const SizedBox(height: AppStyling.spaceSm),
          Container(
            padding: const EdgeInsets.all(AppStyling.spaceMd),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppStyling.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(config.description, style: AppStyling.bodySm),
          ),
        ],
        if (config.languages.isNotEmpty) ...[
          const SizedBox(height: AppStyling.spaceXl),
          Text('Languages', style: AppStyling.label),
          const SizedBox(height: AppStyling.spaceSm),
          Wrap(
            spacing: AppStyling.spaceSm,
            runSpacing: AppStyling.spaceSm,
            children: config.languages
                .map((l) => _Chip(l.label ?? l.icon))
                .toList(),
          ),
        ],
      ],
    );
  }
}

// ── About Config ──────────────────────────────────────────────────────────────

class PortfolioAboutConfigSection extends StatelessWidget {
  final PortfolioAboutConfigController ctrl;
  const PortfolioAboutConfigSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _ConfigShell(
      title: 'About Config',
      subtitle: 'About page configuration',
      ctrl: ctrl,
      onRefresh: ctrl.load,
      builder: (config) => _AboutConfigBody(config: config),
    );
  }
}

class _AboutConfigBody extends StatelessWidget {
  final PortfolioAboutConfig config;
  const _AboutConfigBody({required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow('Location', config.location),
        _InfoRow('Last Updated', config.lastUpdatedAt),
        const SizedBox(height: AppStyling.spaceXl),
        Text('Professional Summary', style: AppStyling.label),
        const SizedBox(height: AppStyling.spaceSm),
        Container(
          padding: const EdgeInsets.all(AppStyling.spaceMd),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppStyling.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(config.professionalSummary, style: AppStyling.bodySm),
        ),
        if (config.technicalSkills.isNotEmpty) ...[
          const SizedBox(height: AppStyling.spaceXl),
          Text('Technical Skills', style: AppStyling.label),
          const SizedBox(height: AppStyling.spaceSm),
          for (final skill in config.technicalSkills) ...[
            const SizedBox(height: AppStyling.spaceSm),
            Text(skill.category,
                style: AppStyling.bodySm
                    .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppStyling.spaceXs),
            Wrap(
              spacing: AppStyling.spaceXs,
              runSpacing: AppStyling.spaceXs,
              children: skill.items.map((i) => _Chip(i)).toList(),
            ),
          ],
        ],
        if (config.coreCompetencies.isNotEmpty) ...[
          const SizedBox(height: AppStyling.spaceXl),
          Text('Core Competencies', style: AppStyling.label),
          const SizedBox(height: AppStyling.spaceSm),
          Wrap(
            spacing: AppStyling.spaceSm,
            runSpacing: AppStyling.spaceSm,
            children: config.coreCompetencies.map((c) => _Chip(c)).toList(),
          ),
        ],
      ],
    );
  }
}

// ── Services Config ───────────────────────────────────────────────────────────

class PortfolioServicesConfigSection extends StatelessWidget {
  final PortfolioServicesConfigController ctrl;
  const PortfolioServicesConfigSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _ConfigShell(
      title: 'Services Config',
      subtitle: 'Services page configuration',
      ctrl: ctrl,
      onRefresh: ctrl.load,
      builder: (config) => _ServicesConfigBody(config: config),
    );
  }
}

class _ServicesConfigBody extends StatelessWidget {
  final PortfolioServicesConfig config;
  const _ServicesConfigBody({required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final service in config.services) ...[
          Container(
            padding: const EdgeInsets.all(AppStyling.spaceLg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppStyling.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(service.title,
                        style: AppStyling.bodyLg
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: AppStyling.spaceSm),
                    _Chip(service.mainTag,
                        color: AppColors.accentPortfolio),
                  ],
                ),
                const SizedBox(height: AppStyling.spaceSm),
                Text(service.description.trim(), style: AppStyling.bodySm),
                if (service.tags.isNotEmpty) ...[
                  const SizedBox(height: AppStyling.spaceMd),
                  Wrap(
                    spacing: AppStyling.spaceXs,
                    runSpacing: AppStyling.spaceXs,
                    children: service.tags.map((t) => _Chip(t)).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppStyling.spaceMd),
        ],
      ],
    );
  }
}

// ── Shared shell ─────────────────────────────────────────────────────────────

class _ConfigShell<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final StreamState<AsyncState<T>> ctrl;
  final VoidCallback onRefresh;
  final Widget Function(T data) builder;

  const _ConfigShell({
    required this.title,
    required this.subtitle,
    required this.ctrl,
    required this.onRefresh,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                    Text(title, style: AppStyling.displayMd),
                    const SizedBox(height: AppStyling.spaceXs),
                    Text(subtitle, style: AppStyling.bodySm),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 18, color: AppColors.textSecondary),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: AppStyling.spaceXxl),
          StreamBuilder<AsyncState<T>>(
            stream: ctrl.stream,
            initialData: ctrl.state,
            builder: (context, snap) {
              final state = snap.data!;
              if (state is AsyncLoading<T>) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              if (state is AsyncError<T>) {
                return Center(
                  child: Column(
                    children: [
                      Text(state.message,
                          style: AppStyling.bodySm.copyWith(color: AppColors.error)),
                      const SizedBox(height: AppStyling.spaceLg),
                      TextButton(onPressed: onRefresh, child: const Text('Retry')),
                    ],
                  ),
                );
              }
              return builder((state as AsyncData<T>).data);
            },
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyling.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppStyling.label),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: AppStyling.bodySm.copyWith(
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color? color;
  const _Chip(this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppStyling.radiusSm),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppStyling.monoSm.copyWith(color: c),
      ),
    );
  }
}
