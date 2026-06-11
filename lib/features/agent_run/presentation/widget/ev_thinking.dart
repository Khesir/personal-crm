import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';

class EvThinking extends StatelessWidget {
  final String text;

  const EvThinking({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppStyling.spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.psychology_outlined, size: 16, color: AppColors.accentLight),
          const SizedBox(width: AppStyling.spaceSm),
          Expanded(
            child: Text(text, style: AppStyling.bodySm),
          ),
        ],
      ),
    );
  }
}
