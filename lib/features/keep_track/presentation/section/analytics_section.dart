import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/core/state/stream_builder_widget.dart';
import '../../domain/controller/analytics_controller.dart';
import '../state/analytics_state.dart';

class AnalyticsSection extends StatelessWidget {
  final AnalyticsController controller;

  const AnalyticsSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      child: StreamStateBuilder<AnalyticsState>(
        state: controller,
        builder: (_, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Analytics', style: AppStyling.headingLg),
                    Text('Users, visits & revenue at a glance', style: AppStyling.bodySm),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: controller.load,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppStyling.spaceLg,
                      vertical: AppStyling.spaceSm,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: AppStyling.spaceSm),
                        Text('Refresh', style: AppStyling.bodySm.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyling.spaceXxl),

            // ── Users ──────────────────────────────────────────
            _Label('Users'),
            const SizedBox(height: AppStyling.spaceMd),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero card
                Expanded(
                  flex: 2,
                  child: _HeroCard(
                    label: 'Total Users',
                    state: state.users,
                    value: (d) => '${d.total}',
                    sub: (d) {
                      if (d.total == 0) return null;
                      final pct = (d.plus / d.total * 100).toStringAsFixed(1);
                      return '$pct% converted to Plus';
                    },
                    color: AppColors.accentKeepTrack,
                  ),
                ),
                const SizedBox(width: AppStyling.spaceMd),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StripCard(
                              label: 'Plus Users',
                              state: state.users,
                              value: (d) => '${d.plus}',
                              strip: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: AppStyling.spaceMd),
                          Expanded(
                            child: _StripCard(
                              label: 'Conversion Rate',
                              state: state.users,
                              value: (d) => d.total == 0
                                  ? '0%'
                                  : '${(d.plus / d.total * 100).toStringAsFixed(1)}%',
                              strip: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppStyling.spaceMd),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniCard(
                              label: 'New users · week',
                              state: state.users,
                              value: (d) => '+${d.newThisWeek}',
                            ),
                          ),
                          const SizedBox(width: AppStyling.spaceMd),
                          Expanded(
                            child: _MiniCard(
                              label: 'New users · month',
                              state: state.users,
                              value: (d) => '+${d.newThisMonth}',
                            ),
                          ),
                          const SizedBox(width: AppStyling.spaceMd),
                          Expanded(
                            child: _MiniCard(
                              label: 'New Plus · week',
                              state: state.users,
                              value: (d) => '+${d.newPlusThisWeek}',
                            ),
                          ),
                          const SizedBox(width: AppStyling.spaceMd),
                          Expanded(
                            child: _MiniCard(
                              label: 'New Plus · month',
                              state: state.users,
                              value: (d) => '+${d.newPlusThisMonth}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppStyling.spaceXxl),

            // ── Landing visits ─────────────────────────────────
            _Label('Landing Visits — last 30 days'),
            const SizedBox(height: AppStyling.spaceMd),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _HeroCard(
                    label: 'Total Visits',
                    state: state.visits,
                    value: (d) => '${d.total}',
                    sub: (d) => '${d.today} today',
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: AppStyling.spaceMd),
                Expanded(
                  child: _StripCard(
                    label: 'This Week',
                    state: state.visits,
                    value: (d) => '${d.thisWeek}',
                    strip: AppColors.info,
                  ),
                ),
                const SizedBox(width: AppStyling.spaceMd),
                Expanded(
                  child: _StripCard(
                    label: 'This Month',
                    state: state.visits,
                    value: (d) => '${d.thisMonth}',
                    strip: AppColors.info,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppStyling.spaceXxl),

            // ── Revenue ────────────────────────────────────────
            _Label('Revenue & Subscriptions'),
            const SizedBox(height: AppStyling.spaceMd),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _HeroCard(
                    label: 'Total Revenue',
                    state: state.revenue,
                    value: (d) => '\$${d.totalRevenueDollars.toStringAsFixed(2)}',
                    sub: (d) => '${d.active} active subscriptions',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppStyling.spaceMd),
                Expanded(
                  child: _StripCard(
                    label: 'Active Subs',
                    state: state.revenue,
                    value: (d) => '${d.active}',
                    strip: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppStyling.spaceMd),
                Expanded(
                  child: _StripCard(
                    label: 'Cancelled',
                    state: state.revenue,
                    value: (d) => '${d.cancelled}',
                    strip: AppColors.error,
                  ),
                ),
                const SizedBox(width: AppStyling.spaceMd),
                Expanded(
                  child: _StripCard(
                    label: 'Trials',
                    state: state.revenue,
                    value: (d) => '${d.trials}',
                    strip: AppColors.warning,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppStyling.spaceXxl),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: AppColors.accentKeepTrack,
            margin: const EdgeInsets.only(right: AppStyling.spaceSm)),
        Text(text.toUpperCase(),
            style: AppStyling.monoSm.copyWith(
              fontSize: 10,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            )),
      ],
    );
  }
}

class _HeroCard<T> extends StatelessWidget {
  final String label;
  final AsyncState<T> state;
  final String Function(T) value;
  final String? Function(T)? sub;
  final Color color;

  const _HeroCard({
    required this.label,
    required this.state,
    required this.value,
    required this.color,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppStyling.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppStyling.label.copyWith(color: color)),
          const SizedBox(height: AppStyling.spaceMd),
          switch (state) {
            AsyncLoading() => Text('...', style: AppStyling.mono.copyWith(fontSize: 32, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
            AsyncError() => Text('—', style: AppStyling.mono.copyWith(fontSize: 32, color: AppColors.error, fontWeight: FontWeight.w700)),
            AsyncData(:final data) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value(data), style: AppStyling.mono.copyWith(fontSize: 32, color: color, fontWeight: FontWeight.w700)),
                  if (sub?.call(data) case final s?) ...[
                    const SizedBox(height: AppStyling.spaceSm),
                    Text(s, style: AppStyling.bodySm.copyWith(color: color.withValues(alpha: 0.7))),
                  ],
                ],
              ),
          },
        ],
      ),
    );
  }
}

class _StripCard<T> extends StatelessWidget {
  final String label;
  final AsyncState<T> state;
  final String Function(T) value;
  final Color strip;

  const _StripCard({
    required this.label,
    required this.state,
    required this.value,
    required this.strip,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: strip,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppStyling.radiusLg),
                bottomLeft: Radius.circular(AppStyling.radiusLg),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppStyling.spaceLg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                  right: BorderSide(color: AppColors.border),
                  bottom: BorderSide(color: AppColors.border),
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(AppStyling.radiusLg),
                  bottomRight: Radius.circular(AppStyling.radiusLg),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppStyling.label),
                  const SizedBox(height: AppStyling.spaceSm),
                  Text(
                    switch (state) {
                      AsyncLoading() => '...',
                      AsyncError() => '—',
                      AsyncData(:final data) => value(data),
                    },
                    style: AppStyling.mono.copyWith(
                      fontSize: 20,
                      color: switch (state) {
                        AsyncError() => AppColors.error,
                        _ => strip,
                      },
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard<T> extends StatelessWidget {
  final String label;
  final AsyncState<T> state;
  final String Function(T) value;

  const _MiniCard({
    required this.label,
    required this.state,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyling.spaceMd,
        vertical: AppStyling.spaceMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppStyling.monoSm.copyWith(color: AppColors.textMuted, fontSize: 10)),
          const SizedBox(height: 6),
          Text(
            switch (state) {
              AsyncLoading() => '...',
              AsyncError() => '—',
              AsyncData(:final data) => value(data),
            },
            style: AppStyling.mono.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: switch (state) {
                AsyncError() => AppColors.error,
                _ => AppColors.textPrimary,
              },
            ),
          ),
        ],
      ),
    );
  }
}
