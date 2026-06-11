import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';

const _kAppName = 'Codex';
const _kAppVersion = '1.0.0';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About', style: AppStyling.pageTitle),
          const SizedBox(height: AppStyling.spaceXs),
          Text('Application information.', style: AppStyling.pageSub),
          const SizedBox(height: AppStyling.spaceXxl),
          Text(_kAppName, style: AppStyling.headingMd),
          const SizedBox(height: AppStyling.spaceXs),
          Text('Version $_kAppVersion', style: AppStyling.bodySm),
        ],
      ),
    );
  }
}
