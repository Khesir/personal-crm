import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';

const _kDialogWidth = 420.0;

/// Confirmation dialog shown before a project is unregistered (rail
/// context-menu "Remove" and Settings > Projects' delete button both use
/// this). Deliberately a dumb confirm/cancel widget — it never touches
/// [ProjectsController] itself, it just pops `true` on Confirm and
/// `false` on Cancel; the call site decides whether to actually call
/// `ProjectsController.removeProject`.
class RemoveProjectConfirmDialog extends StatelessWidget {
  final String projectName;

  const RemoveProjectConfirmDialog({super.key, required this.projectName});

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
              Text('Remove project', style: AppStyling.headingMd),
              const SizedBox(height: AppStyling.spaceLg),
              Text(
                'Remove "$projectName" from Avyn? This only unregisters it — '
                'files on disk are untouched.',
                style: AppStyling.bodySm,
              ),
              const SizedBox(height: AppStyling.spaceXl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Text('Cancel', style: AppStyling.bodySm),
                  ),
                  const SizedBox(width: AppStyling.spaceLg),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyling.spaceLg,
                        vertical: AppStyling.spaceSm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                      ),
                      child: Text(
                        'Remove',
                        style: AppStyling.bodySm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
