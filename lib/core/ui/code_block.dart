import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';

class CodeBlock extends StatelessWidget {
  final String code;
  final String? language;

  const CodeBlock({super.key, required this.code, this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppStyling.spaceXs),
      padding: const EdgeInsets.all(AppStyling.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language != null && language!.isNotEmpty) ...[
            Text(language!.toUpperCase(), style: AppStyling.label),
            const SizedBox(height: AppStyling.spaceSm),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(code, style: AppStyling.mono),
          ),
        ],
      ),
    );
  }
}
