import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';

/// A labeled, monospaced block of text — used inside step cards for tool
/// arguments, output, and before/after diff previews.
class LabeledTextBlock extends StatelessWidget {
  final String label;
  final String content;
  final Color? backgroundColor;

  const LabeledTextBlock({
    super.key,
    required this.label,
    required this.content,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppStyling.label),
        const SizedBox(height: AppStyling.spaceXs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppStyling.spaceMd),
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.surface,
            borderRadius: BorderRadius.circular(AppStyling.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: SelectableText(
            content.isEmpty ? '(empty)' : content,
            style: AppStyling.monoSm,
          ),
        ),
      ],
    );
  }
}
