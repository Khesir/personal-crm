import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/model/agent_skill.dart';

const _kDialogWidth = 360.0;

class SkillPickerDialog extends StatelessWidget {
  const SkillPickerDialog({super.key});

  static Future<AgentSkill?> show(BuildContext context) {
    return showDialog<AgentSkill>(
      context: context,
      builder: (_) => const SkillPickerDialog(),
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
              Text('Run skill', style: AppStyling.headingMd),
              const SizedBox(height: AppStyling.spaceLg),
              for (final skill in AgentSkill.values)
                _SkillTile(
                  skill: skill,
                  onTap: () => Navigator.of(context).pop(skill),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  final AgentSkill skill;
  final VoidCallback onTap;

  const _SkillTile({required this.skill, required this.onTap});

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
            const Icon(Icons.smart_toy_outlined, size: 16, color: AppColors.accentLight),
            const SizedBox(width: AppStyling.spaceSm),
            Text(skill.label, style: AppStyling.bodyLg),
          ],
        ),
      ),
    );
  }
}
