import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';

class MinecraftScreen extends StatelessWidget {
  const MinecraftScreen({super.key});

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
                  color: AppColors.accentMinecraft.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppStyling.radiusSm),
                ),
                child: Text(
                  'IN DEVELOPMENT',
                  style: AppStyling.monoSm
                      .copyWith(color: AppColors.accentMinecraft),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyling.spaceLg),
          Text('Minecraft Server', style: AppStyling.displayMd),
          const SizedBox(height: AppStyling.spaceXs),
          Text(
            'Personal Minecraft server project — currently in development.',
            style: AppStyling.bodySm,
          ),
          const SizedBox(height: AppStyling.spaceXxl),
          Container(
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
                Text('Status', style: AppStyling.label),
                const SizedBox(height: AppStyling.spaceSm),
                Text(
                  'In Development',
                  style: AppStyling.headingMd
                      .copyWith(color: AppColors.warning),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
