import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/core/state/state.dart';
import '../../domain/controller/keep_track_controller.dart';
import '../state/keep_track_state.dart';

class KeepTrackOverviewSection extends StatelessWidget {
  final ReleasesController releasesCtrl;
  final AnnouncementsController announcementsCtrl;

  const KeepTrackOverviewSection({
    super.key,
    required this.releasesCtrl,
    required this.announcementsCtrl,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyling.spaceSm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppStyling.radiusSm),
                ),
                child: Text(
                  'LIVE',
                  style: AppStyling.monoSm.copyWith(color: AppColors.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyling.spaceLg),
          Text('Keep Track', style: AppStyling.displayMd),
          const SizedBox(height: AppStyling.spaceXs),
          Text('Personal finance and productivity app',
              style: AppStyling.bodySm),
          const SizedBox(height: AppStyling.spaceXxl),
          Row(
            children: [
              _LatestVersionCard(releasesCtrl: releasesCtrl),
              const SizedBox(width: AppStyling.spaceLg),
              _TotalReleasesCard(releasesCtrl: releasesCtrl),
              const SizedBox(width: AppStyling.spaceLg),
              _TotalAnnouncementsCard(announcementsCtrl: announcementsCtrl),
              const SizedBox(width: AppStyling.spaceLg),
              _LastReleasedCard(releasesCtrl: releasesCtrl),
            ],
          ),
        ],
      ),
    );
  }
}

class _LatestVersionCard extends StatelessWidget {
  final ReleasesController releasesCtrl;
  const _LatestVersionCard({required this.releasesCtrl});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamStateBuilder<AsyncState<List<AppRelease>>>(
        state: releasesCtrl,
        builder: (_, state) => _StatCard(
          label: 'Latest Version',
          value: switch (state) {
            AsyncLoading() => '...',
            AsyncData(data: final list) =>
              list.isNotEmpty ? 'v${list.first.version}' : '—',
            AsyncError() => 'Error',
          },
          accent: switch (state) {
            AsyncError() => AppColors.error,
            _ => AppColors.accentKeepTrack,
          },
        ),
      ),
    );
  }
}

class _TotalReleasesCard extends StatelessWidget {
  final ReleasesController releasesCtrl;
  const _TotalReleasesCard({required this.releasesCtrl});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamStateBuilder<AsyncState<List<AppRelease>>>(
        state: releasesCtrl,
        builder: (_, state) => _StatCard(
          label: 'Total Releases',
          value: switch (state) {
            AsyncLoading() => '...',
            AsyncData(data: final list) => '${list.length}',
            AsyncError() => 'Error',
          },
          accent: switch (state) {
            AsyncError() => AppColors.error,
            _ => AppColors.accentKeepTrack,
          },
        ),
      ),
    );
  }
}

class _TotalAnnouncementsCard extends StatelessWidget {
  final AnnouncementsController announcementsCtrl;
  const _TotalAnnouncementsCard({required this.announcementsCtrl});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamStateBuilder<AsyncState<List<Announcement>>>(
        state: announcementsCtrl,
        builder: (_, state) => _StatCard(
          label: 'Announcements',
          value: switch (state) {
            AsyncLoading() => '...',
            AsyncData(data: final list) => '${list.length}',
            AsyncError() => 'Error',
          },
          accent: switch (state) {
            AsyncError() => AppColors.error,
            _ => AppColors.accentKeepTrack,
          },
        ),
      ),
    );
  }
}

class _LastReleasedCard extends StatelessWidget {
  final ReleasesController releasesCtrl;
  const _LastReleasedCard({required this.releasesCtrl});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamStateBuilder<AsyncState<List<AppRelease>>>(
        state: releasesCtrl,
        builder: (_, state) => _StatCard(
          label: 'Last Released',
          value: switch (state) {
            AsyncLoading() => '...',
            AsyncData(data: final list) => list.isNotEmpty &&
                    list.first.publishedAt != null
                ? _formatDate(list.first.publishedAt!)
                : '—',
            AsyncError() => 'Error',
          },
          accent: switch (state) {
            AsyncError() => AppColors.error,
            _ => AppColors.textSecondary,
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _StatCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            style: AppStyling.mono.copyWith(
              fontSize: 22,
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
