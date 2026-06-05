import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';

class TimeTrackerScreen extends StatelessWidget {
  const TimeTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyling.spaceSm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentTimeTracker.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppStyling.radiusSm),
                ),
                child: Text(
                  'IN DEVELOPMENT',
                  style: AppStyling.monoSm
                      .copyWith(color: AppColors.accentTimeTracker),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyling.spaceLg),
          Text('Time Tracker', style: AppStyling.displayMd),
          const SizedBox(height: AppStyling.spaceXs),
          Text(
            'Personal time tracking app — currently in development.',
            style: AppStyling.bodySm,
          ),
          const SizedBox(height: AppStyling.spaceXxl),
          _InfoCard(
            title: 'Status',
            value: 'In Development',
            accent: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(AppStyling.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyling.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyling.label),
          const SizedBox(height: AppStyling.spaceSm),
          Text(value, style: AppStyling.headingMd.copyWith(color: accent)),
        ],
      ),
    );
  }
}
