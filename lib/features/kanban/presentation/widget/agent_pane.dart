import 'dart:async';

import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/agent_run/api.dart';

const _kCursorBlinkInterval = Duration(milliseconds: 500);
const _kElapsedTickInterval = Duration(seconds: 1);
const double _kPaneHeaderHeight = 32;
const double _kRunDotSize = 8;

/// Terminal-styled pane for the Kanban dock. Renders the live [AgentEvent]
/// transcript of [agentRunController] when present, otherwise shows an idle
/// prompt (if a run has happened before) or an empty-state message.
class AgentPane extends StatefulWidget {
  final AgentRunController? agentRunController;
  final String projectName;

  const AgentPane({
    super.key,
    required this.agentRunController,
    required this.projectName,
  });

  @override
  State<AgentPane> createState() => _AgentPaneState();
}

class _AgentPaneState extends State<AgentPane> {
  final _scrollController = ScrollController();
  Timer? _cursorTimer;
  bool _cursorVisible = true;

  @override
  void initState() {
    super.initState();
    _cursorTimer = Timer.periodic(_kCursorBlinkInterval, (_) {
      if (mounted) setState(() => _cursorVisible = !_cursorVisible);
    });
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.agentRunController;

    return Container(
      color: AppColors.termBackground,
      child: Column(
        children: [
          _PaneHeader(agentRunController: controller),
          Expanded(
            child: controller == null
                ? _EmptyState(projectName: widget.projectName)
                : StreamBuilder<AgentRunStateData>(
                    stream: controller.stream,
                    initialData: controller.state,
                    builder: (context, snapshot) {
                      final state = snapshot.data!;
                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());

                      if (state.events.isEmpty && state.status != AgentRunStatus.running) {
                        return _IdlePrompt(
                          projectName: widget.projectName,
                          cursorVisible: _cursorVisible,
                        );
                      }

                      return _Transcript(
                        scrollController: _scrollController,
                        state: state,
                        projectName: widget.projectName,
                        cursorVisible: _cursorVisible,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PaneHeader extends StatelessWidget {
  final AgentRunController? agentRunController;

  const _PaneHeader({required this.agentRunController});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kPaneHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceMd),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text('Agent', style: AppStyling.label),
          const Spacer(),
          if (agentRunController != null)
            StreamBuilder<AgentRunStateData>(
              stream: agentRunController!.stream,
              initialData: agentRunController!.state,
              builder: (context, snapshot) {
                final state = snapshot.data!;
                if (state.status != AgentRunStatus.running) return const SizedBox.shrink();
                return _RunIndicator(state: state);
              },
            ),
        ],
      ),
    );
  }
}

class _RunIndicator extends StatefulWidget {
  final AgentRunStateData state;

  const _RunIndicator({required this.state});

  @override
  State<_RunIndicator> createState() => _RunIndicatorState();
}

class _RunIndicatorState extends State<_RunIndicator> {
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _tickTimer = Timer.periodic(_kElapsedTickInterval, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  String get _elapsedLabel {
    final startedAt = widget.state.startedAt;
    if (startedAt == null) return '0:00';
    final elapsed = DateTime.now().difference(startedAt);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final skill = widget.state.skill;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _PulsingDot(),
        const SizedBox(width: AppStyling.spaceXs),
        Text(
          '${skill?.label ?? 'Agent'} · $_elapsedLabel',
          style: AppStyling.monoSm.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kRunDotSize * 2,
      height: _kRunDotSize * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = _controller.value;
              return Container(
                width: _kRunDotSize + (_kRunDotSize * progress),
                height: _kRunDotSize + (_kRunDotSize * progress),
                decoration: BoxDecoration(
                  color: AppColors.statusInProgress.withValues(alpha: 0.45 * (1 - progress)),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          Container(
            width: _kRunDotSize,
            height: _kRunDotSize,
            decoration: const BoxDecoration(color: AppColors.statusInProgress, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

class _Transcript extends StatelessWidget {
  final ScrollController scrollController;
  final AgentRunStateData state;
  final String projectName;
  final bool cursorVisible;

  const _Transcript({
    required this.scrollController,
    required this.state,
    required this.projectName,
    required this.cursorVisible,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = state.status == AgentRunStatus.running;
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyling.spaceMd,
        vertical: AppStyling.spaceSm,
      ),
      itemCount: state.events.length + 1,
      itemBuilder: (context, index) {
        if (index == state.events.length) {
          return isRunning
              ? const _TermLine(child: Text('…', style: TextStyle(color: AppColors.textTertiary)))
              : _TermPromptLine(projectName: projectName, cursorVisible: cursorVisible);
        }
        return _TermEventLine(event: state.events[index]);
      },
    );
  }
}

class _IdlePrompt extends StatelessWidget {
  final String projectName;
  final bool cursorVisible;

  const _IdlePrompt({required this.projectName, required this.cursorVisible});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppStyling.spaceMd),
      child: _TermPromptLine(projectName: projectName, cursorVisible: cursorVisible),
    );
  }
}

class _TermPromptLine extends StatelessWidget {
  final String projectName;
  final bool cursorVisible;

  const _TermPromptLine({required this.projectName, required this.cursorVisible});

  @override
  Widget build(BuildContext context) {
    return _TermLine(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('➜ ', style: _termStyle.copyWith(color: AppColors.termGreen, fontWeight: FontWeight.w600)),
          Text(projectName, style: _termStyle.copyWith(color: AppColors.termCyan)),
          const SizedBox(width: AppStyling.spaceXs),
          _Cursor(visible: cursorVisible),
        ],
      ),
    );
  }
}

class _Cursor extends StatelessWidget {
  final bool visible;

  const _Cursor({required this.visible});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: visible ? 1 : 0,
      child: Container(width: 7, height: 14, color: AppColors.termForeground),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String projectName;

  const _EmptyState({required this.projectName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyling.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No agent runs yet for $projectName.',
              style: _termStyle.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyling.spaceXs),
            Text(
              'Run a skill from the board to see its transcript here.',
              style: _termStyle.copyWith(color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TermEventLine extends StatelessWidget {
  final AgentEvent event;

  const _TermEventLine({required this.event});

  @override
  Widget build(BuildContext context) {
    return switch (event) {
      AgentThinking(text: final text) => _ThinkingLine(text: text),
      AgentToolUse(tool: final tool, input: final input) =>
        _ToolLine(tool: tool, detail: input, isResult: false),
      AgentToolResult(tool: final tool, output: final output) =>
        _ToolLine(tool: tool, detail: output, isResult: true),
      AgentResult(summary: final summary, success: final success) =>
        _ResultLine(summary: summary, success: success),
    };
  }
}

class _ThinkingLine extends StatelessWidget {
  final String text;

  const _ThinkingLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return _TermLine(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '✻ ', style: _termStyle.copyWith(color: AppColors.textTertiary)),
            TextSpan(text: text, style: _termStyle.copyWith(color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

class _ToolLine extends StatelessWidget {
  final String tool;
  final String detail;
  final bool isResult;

  const _ToolLine({required this.tool, required this.detail, required this.isResult});

  @override
  Widget build(BuildContext context) {
    if (isResult) {
      return _TermLine(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '⎿ ', style: _termStyle.copyWith(color: AppColors.textSecondary)),
              TextSpan(text: '$tool result ', style: _termStyle.copyWith(color: AppColors.textSecondary)),
              if (detail.isNotEmpty)
                TextSpan(text: detail, style: _termStyle.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }
    return _TermLine(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '⏺ ', style: _termStyle.copyWith(color: AppColors.accentLight)),
            TextSpan(text: '$tool ', style: _termStyle.copyWith(color: AppColors.accentLight)),
            if (detail.isNotEmpty)
              TextSpan(text: detail, style: _termStyle.copyWith(color: AppColors.termCyan)),
          ],
        ),
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  final String summary;
  final bool success;

  const _ResultLine({required this.summary, required this.success});

  @override
  Widget build(BuildContext context) {
    return _TermLine(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: success ? '✓ ' : '✗ ',
              style: _termStyle.copyWith(color: success ? AppColors.termGreen : AppColors.termRed),
            ),
            TextSpan(
              text: summary,
              style: _termStyle.copyWith(color: success ? AppColors.termGreen : AppColors.termRed),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermLine extends StatelessWidget {
  final Widget child;

  const _TermLine({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: child,
    );
  }
}

final _termStyle = AppStyling.mono.copyWith(fontSize: 12, color: AppColors.termForeground);
