import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/model/bug_report.dart';

const _kDialogWidth = 360.0;

/// Modal offering the two "Convert to issue" paths for a [BugReport]:
/// writing the `.md` file directly, or generating it with Claude Code.
class BugConvertDialog extends StatelessWidget {
  final BugReport report;
  final VoidCallback onWriteDirectly;
  final VoidCallback onGenerateWithClaudeCode;

  const BugConvertDialog({
    super.key,
    required this.report,
    required this.onWriteDirectly,
    required this.onGenerateWithClaudeCode,
  });

  static Future<void> show(
    BuildContext context, {
    required BugReport report,
    required VoidCallback onWriteDirectly,
    required VoidCallback onGenerateWithClaudeCode,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => BugConvertDialog(
        report: report,
        onWriteDirectly: onWriteDirectly,
        onGenerateWithClaudeCode: onGenerateWithClaudeCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyling.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: SizedBox(
        width: _kDialogWidth,
        child: Padding(
          padding: const EdgeInsets.all(AppStyling.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Convert to issue', style: AppStyling.headingMd),
              const SizedBox(height: AppStyling.spaceLg),
              _ConvertOptionTile(
                icon: Icons.description_outlined,
                label: 'Write .md directly',
                onTap: () {
                  Navigator.of(context).pop();
                  onWriteDirectly();
                },
              ),
              _ConvertOptionTile(
                icon: Icons.smart_toy_outlined,
                label: 'Generate with Claude Code',
                onTap: () {
                  Navigator.of(context).pop();
                  onGenerateWithClaudeCode();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConvertOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ConvertOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppStyling.spaceSm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceLg,
          vertical: AppStyling.spaceMd,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.accentLight),
            const SizedBox(width: AppStyling.spaceSm),
            Text(label, style: AppStyling.bodyLg),
          ],
        ),
      ),
    );
  }
}
