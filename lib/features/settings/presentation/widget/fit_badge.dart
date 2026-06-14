import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/model/model_fit_result.dart';

/// Small color-coded badge summarizing a [ModelFitResult.fit] value.
///
/// Shared by the Hugging Face search dialog and the Home chat model
/// switcher so both surfaces use identical colors/labels.
class FitBadge extends StatelessWidget {
  final Fit fit;

  const FitBadge({super.key, required this.fit});

  Color get _color => switch (fit) {
        Fit.perfect => AppColors.success,
        Fit.good => AppColors.info,
        Fit.cpuOnly => AppColors.warning,
        Fit.tooBig => AppColors.error,
      };

  String get _label => switch (fit) {
        Fit.perfect => 'PERFECT',
        Fit.good => 'GOOD',
        Fit.cpuOnly => 'CPU ONLY',
        Fit.tooBig => 'TOO BIG',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceSm, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withAlpha(0x29),
        borderRadius: BorderRadius.circular(AppStyling.radiusSm),
      ),
      child: Text(
        _label,
        style: AppStyling.monoSm.copyWith(color: _color),
      ),
    );
  }
}
