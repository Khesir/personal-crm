import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/shell/presentation/state/shell_state.dart';

class AriConnectScreen extends StatelessWidget {
  final AppSection section;

  const AriConnectScreen({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: switch (section) {
        AppSection.overview => const _AriConnectOverview(),
        AppSection.analytics => const _AriConnectAnalytics(),
        _ => const _AriConnectOverview(),
      },
    );
  }
}

class _AriConnectOverview extends StatelessWidget {
  const _AriConnectOverview();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ari Connect', style: AppStyling.displayMd),
          const SizedBox(height: AppStyling.spaceXs),
          Text('Discord bot overview', style: AppStyling.bodySm),
          const SizedBox(height: AppStyling.spaceXxl),
          Row(
            children: [
              _StatCard(label: 'Bot Status', value: '—'),
              const SizedBox(width: AppStyling.spaceLg),
              _StatCard(label: 'Servers', value: '—'),
              const SizedBox(width: AppStyling.spaceLg),
              _StatCard(label: 'Commands Used', value: '—'),
              const SizedBox(width: AppStyling.spaceLg),
              _StatCard(label: 'Active Users', value: '—'),
            ],
          ),
          const SizedBox(height: AppStyling.spaceXxl),
          Container(
            padding: const EdgeInsets.all(AppStyling.spaceLg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppStyling.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: AppColors.accentAriConnect),
                const SizedBox(width: AppStyling.spaceSm),
                Text(
                  'Connect the Ari Connect API to populate live data.',
                  style: AppStyling.bodySm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AriConnectAnalytics extends StatelessWidget {
  const _AriConnectAnalytics();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analytics', style: AppStyling.displayMd),
          const SizedBox(height: AppStyling.spaceXs),
          Text('Bot usage metrics', style: AppStyling.bodySm),
          const SizedBox(height: AppStyling.spaceXxl),
          Container(
            padding: const EdgeInsets.all(AppStyling.spaceLg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppStyling.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Analytics will be available once the Ari Connect API is connected.',
              style: AppStyling.bodySm,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppStyling.spaceLg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyling.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppStyling.label),
            const SizedBox(height: AppStyling.spaceSm),
            Text(
              value,
              style: AppStyling.displayMd
                  .copyWith(color: AppColors.accentAriConnect),
            ),
          ],
        ),
      ),
    );
  }
}
