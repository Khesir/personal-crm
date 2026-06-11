import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/agent_run_controller.dart';
import '../state/agent_run_state.dart';

class AgentRunIndicator extends StatelessWidget {
  final AgentRunController controller;
  final VoidCallback onTap;

  const AgentRunIndicator({super.key, required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AgentRunStateData>(
      stream: controller.stream,
      initialData: controller.state,
      builder: (context, snapshot) {
        final state = snapshot.data!;
        final skill = state.skill;
        if (skill == null || !state.isBackgrounded) return const SizedBox.shrink();

        return Positioned(
          right: AppStyling.spaceXl,
          bottom: AppStyling.spaceXl,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyling.spaceLg,
                vertical: AppStyling.spaceMd,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppStyling.radiusXl),
                border: Border.all(color: AppColors.accentLine),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusDot(status: state.status),
                  const SizedBox(width: AppStyling.spaceSm),
                  Text('${skill.label} running…', style: AppStyling.bodySm),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusDot extends StatelessWidget {
  final AgentRunStatus status;

  const _StatusDot({required this.status});

  Color get _color => switch (status) {
        AgentRunStatus.running => AppColors.statusInProgress,
        AgentRunStatus.done => AppColors.success,
        AgentRunStatus.error => AppColors.error,
        AgentRunStatus.stopped => AppColors.textTertiary,
        AgentRunStatus.idle => AppColors.textTertiary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
    );
  }
}
