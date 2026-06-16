import 'dart:async';

import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';

const double _dotSize = 8;
const double _pillRadius = 999;
const _tickInterval = Duration(seconds: 1);

class WatchPill extends StatefulWidget {
  final bool watching;
  final DateTime? lastSyncedAt;

  const WatchPill({super.key, required this.watching, this.lastSyncedAt});

  @override
  State<WatchPill> createState() => _WatchPillState();
}

class _WatchPillState extends State<WatchPill> {
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _tickTimer = Timer.periodic(_tickInterval, (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  String get _label =>
      widget.watching ? 'Watching issues/' : 'Watching unavailable';

  String? get _syncTime {
    final lastSyncedAt = widget.lastSyncedAt;
    if (lastSyncedAt == null) return null;
    final seconds = DateTime.now().difference(lastSyncedAt).inSeconds;
    if (seconds < 1) return 'synced just now';
    if (seconds < 60) return 'synced ${seconds}s ago';
    final minutes = seconds ~/ 60;
    return 'synced ${minutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    final syncTime = _syncTime;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppStyling.spaceSm,
        AppStyling.spaceXs,
        AppStyling.spaceMd,
        AppStyling.spaceXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(_pillRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WatchDot(active: widget.watching),
          const SizedBox(width: AppStyling.spaceXs),
          Text(
            _label,
            style: AppStyling.label.copyWith(color: AppColors.textPrimary),
          ),
          if (syncTime != null) ...[
            const SizedBox(width: AppStyling.spaceXs),
            Text(
              '· $syncTime',
              style: AppStyling.monoSm.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class _WatchDot extends StatelessWidget {
  final bool active;

  const _WatchDot({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.statusDone : AppColors.textFaint;
    if (!active) {
      return Container(
        width: _dotSize,
        height: _dotSize,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }
    return _PulsingDot(color: color);
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _dotSize * 2,
      height: _dotSize * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = _controller.value;
              return Container(
                width: _dotSize + (_dotSize * progress),
                height: _dotSize + (_dotSize * progress),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.45 * (1 - progress)),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          Container(
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
