import 'dart:async';

import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/agent_run_controller.dart';
import '../../domain/model/agent_event.dart';
import '../state/agent_run_state.dart';
import '../widget/ev_thinking.dart';
import '../widget/ev_tool.dart';
import '../widget/writing_indicator.dart';

const _kElapsedTickInterval = Duration(seconds: 1);

class AgentRunScreen extends StatefulWidget {
  final AgentRunController controller;
  final VoidCallback onRunInBackground;
  final VoidCallback onViewBoard;

  const AgentRunScreen({
    super.key,
    required this.controller,
    required this.onRunInBackground,
    required this.onViewBoard,
  });

  @override
  State<AgentRunScreen> createState() => _AgentRunScreenState();
}

class _AgentRunScreenState extends State<AgentRunScreen> {
  final _scrollController = ScrollController();
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    _elapsedTimer = Timer.periodic(_kElapsedTickInterval, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  String _formatElapsed(DateTime? startedAt) {
    if (startedAt == null) return '0:00';
    final elapsed = DateTime.now().difference(startedAt);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: StreamBuilder<AgentRunStateData>(
        stream: widget.controller.stream,
        initialData: widget.controller.state,
        builder: (context, snapshot) {
          final state = snapshot.data!;
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
          return Column(
            children: [
              _Header(
                state: state,
                elapsedLabel: _formatElapsed(state.startedAt),
                onStop: widget.controller.stop,
              ),
              Container(height: 1, color: AppColors.border),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppStyling.spaceXl),
                  itemCount: state.events.length + (state.status == AgentRunStatus.running ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.events.length) {
                      return const WritingIndicator();
                    }
                    return _EventTile(event: state.events[index]);
                  },
                ),
              ),
              Container(height: 1, color: AppColors.border),
              _Footer(
                state: state,
                onRunInBackground: widget.onRunInBackground,
                onViewBoard: widget.onViewBoard,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final AgentEvent event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return switch (event) {
      AgentThinking(text: final text) => EvThinking(text: text),
      AgentToolUse(tool: final tool, input: final input) =>
        EvTool(tool: tool, detail: input),
      AgentToolResult(tool: final tool, output: final output) =>
        EvTool(tool: tool, detail: output, isResult: true),
      AgentResult(summary: final summary, success: final success) =>
        _ResultTile(summary: summary, success: success),
    };
  }
}

class _ResultTile extends StatelessWidget {
  final String summary;
  final bool success;

  const _ResultTile({required this.summary, required this.success});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppStyling.spaceSm),
      child: Container(
        padding: const EdgeInsets.all(AppStyling.spaceMd),
        decoration: BoxDecoration(
          color: success ? AppColors.surfaceRaised : AppColors.severityError.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
          border: Border.all(color: success ? AppColors.border : AppColors.severityError),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              size: 16,
              color: success ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: AppStyling.spaceSm),
            Expanded(child: Text(summary, style: AppStyling.bodyLg)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AgentRunStateData state;
  final String elapsedLabel;
  final VoidCallback onStop;

  const _Header({required this.state, required this.elapsedLabel, required this.onStop});

  @override
  Widget build(BuildContext context) {
    final skill = state.skill;
    return Padding(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(skill?.label ?? 'Agent run', style: AppStyling.pageTitle),
              const SizedBox(height: AppStyling.spaceXs),
              Text(
                '${state.projectName ?? ''} · $elapsedLabel · ${state.status.name}',
                style: AppStyling.pageSub,
              ),
            ],
          ),
          const Spacer(),
          if (state.status == AgentRunStatus.running)
            _StopButton(onTap: onStop),
        ],
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StopButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceLg,
          vertical: AppStyling.spaceSm,
        ),
        decoration: BoxDecoration(
          color: AppColors.severityError.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
          border: Border.all(color: AppColors.severityError),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stop_circle_outlined, size: 16, color: AppColors.severityError),
            const SizedBox(width: AppStyling.spaceXs),
            Text('Stop', style: AppStyling.bodySm.copyWith(color: AppColors.severityError)),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final AgentRunStateData state;
  final VoidCallback onRunInBackground;
  final VoidCallback onViewBoard;

  const _Footer({
    required this.state,
    required this.onRunInBackground,
    required this.onViewBoard,
  });

  @override
  Widget build(BuildContext context) {
    final isFinished = state.status == AgentRunStatus.done ||
        state.status == AgentRunStatus.error ||
        state.status == AgentRunStatus.stopped;

    return Padding(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!isFinished)
            _FooterButton(label: 'Run in background', onTap: onRunInBackground),
          if (isFinished) ...[
            const SizedBox(width: AppStyling.spaceLg),
            _FooterButton(label: 'View board', onTap: onViewBoard, primary: true),
          ],
        ],
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _FooterButton({required this.label, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceLg,
          vertical: AppStyling.spaceSm,
        ),
        decoration: BoxDecoration(
          color: primary ? AppColors.accent : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
          border: Border.all(color: primary ? AppColors.accent : AppColors.border),
        ),
        child: Text(
          label,
          style: AppStyling.bodySm.copyWith(
            color: primary ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: primary ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
