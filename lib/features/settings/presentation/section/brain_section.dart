import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/brain/api.dart';
import '../../domain/repository/process_runner.dart';

class BrainSection extends StatelessWidget {
  final ProcessRunner processRunner;

  const BrainSection({super.key, required this.processRunner});

  void _openBrainFolder() {
    processRunner.run(
      'explorer.exe',
      [resolveBrainFolderPath()],
      runInShell: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Brain', style: AppStyling.pageTitle),
          const SizedBox(height: AppStyling.spaceXs),
          Text(
            'The brain is a folder of markdown files (identity, soul, memory, skills) that '
            'shape the Home chat assistant\'s personality and system prompt.',
            style: AppStyling.pageSub,
          ),
          const SizedBox(height: AppStyling.spaceXxl),
          GestureDetector(
            onTap: _openBrainFolder,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyling.spaceLg,
                vertical: AppStyling.spaceSm,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppStyling.radiusMd),
              ),
              child: Text(
                'Open brain folder',
                style: AppStyling.bodySm.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
