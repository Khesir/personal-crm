import 'dart:async';

import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../../agent_run/presentation/state/agent_run_state.dart';
import '../state/dock_state.dart';
import '../state/terminal_session_controller.dart';
import '../widget/agent_pane.dart';
import '../widget/chat_pane.dart';
import '../widget/terminal_pane.dart';

const double _dockResizeHandleHeight = 6;
const double _dockTabbarHeight = 38;
const double _paneDividerWidth = 6;

const List<DockPane> _paneOrder = [DockPane.terminal, DockPane.agent, DockPane.chat];

class BoardDockSection extends StatelessWidget {
  final DockController controller;
  final String projectName;
  final TerminalSessionController? terminalSessionController;

  const BoardDockSection({
    super.key,
    required this.controller,
    required this.projectName,
    this.terminalSessionController,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DockStateData>(
      stream: controller.stream,
      initialData: controller.state,
      builder: (context, snapshot) {
        final state = snapshot.data!;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _Dock(
              controller: controller,
              state: state,
              projectName: projectName,
              terminalSessionController: terminalSessionController,
            ),
            if (state.collapsed) _DockReopenPill(controller: controller, state: state),
          ],
        );
      },
    );
  }
}

class _Dock extends StatelessWidget {
  final DockController controller;
  final DockStateData state;
  final String projectName;
  final TerminalSessionController? terminalSessionController;

  const _Dock({
    required this.controller,
    required this.state,
    required this.projectName,
    this.terminalSessionController,
  });

  void _onResizeDrag(DragUpdateDetails details) {
    if (state.collapsed) return;
    controller.setHeight(state.heightPx - details.delta.dy * 2.0);
  }

  @override
  Widget build(BuildContext context) {
    if (state.collapsed) return const SizedBox.shrink();

    return Container(
      height: state.heightPx,
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _onResizeDrag,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeUpDown,
              child: Container(
                height: _dockResizeHandleHeight,
                alignment: Alignment.center,
                child: Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(AppStyling.radiusSm),
                  ),
                ),
              ),
            ),
          ),
          _DockTabbar(controller: controller, state: state),
          Expanded(
            child: _DockBody(
              controller: controller,
              state: state,
              projectName: projectName,
              terminalSessionController: terminalSessionController,
            ),
          ),
        ],
      ),
    );
  }
}

class _DockTabbar extends StatelessWidget {
  final DockController controller;
  final DockStateData state;

  const _DockTabbar({required this.controller, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _dockTabbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceMd),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(child: SizedBox.shrink()),
          _PaneToggleGroup(controller: controller, activePanes: state.activePanes),
          const SizedBox(width: AppStyling.spaceSm),
          Container(width: 1, height: 18, color: AppColors.border),
          const SizedBox(width: AppStyling.spaceSm),
          _CollapseButton(onTap: controller.collapse),
        ],
      ),
    );
  }
}

class _PaneToggleGroup extends StatelessWidget {
  final DockController controller;
  final Set<DockPane> activePanes;

  const _PaneToggleGroup({required this.controller, required this.activePanes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PaneToggleButton(
            icon: Icons.terminal,
            tooltip: 'Terminal',
            selected: activePanes.contains(DockPane.terminal),
            onTap: () => controller.togglePane(DockPane.terminal),
          ),
          _PaneToggleButton(
            icon: Icons.smart_toy_outlined,
            tooltip: 'Agent',
            selected: activePanes.contains(DockPane.agent),
            onTap: () => controller.togglePane(DockPane.agent),
          ),
          _PaneToggleButton(
            icon: Icons.chat_bubble_outline,
            tooltip: 'Chat',
            selected: activePanes.contains(DockPane.chat),
            onTap: () => controller.togglePane(DockPane.chat),
          ),
        ],
      ),
    );
  }
}

class _PaneToggleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _PaneToggleButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.accentBg : Colors.transparent,
            borderRadius: BorderRadius.circular(AppStyling.radiusSm),
          ),
          child: Icon(
            icon,
            size: 16,
            color: selected ? AppColors.accentLight : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _CollapseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CollapseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Collapse panel',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppStyling.radiusSm),
          ),
          child: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DockBody extends StatelessWidget {
  final DockController controller;
  final DockStateData state;
  final String projectName;
  final TerminalSessionController? terminalSessionController;

  const _DockBody({
    required this.controller,
    required this.state,
    required this.projectName,
    this.terminalSessionController,
  });

  Widget _buildPane(DockPane pane) {
    return switch (pane) {
      DockPane.terminal => TerminalPane(
          projectName: projectName,
          sessionController: terminalSessionController,
        ),
      DockPane.agent => AgentPane(
          agentRunController: state.agentRunController,
          projectName: projectName,
        ),
      DockPane.chat => const ChatPane(),
    };
  }

  void _onDividerDrag(DragUpdateDetails details, DockPane leftPane, double currentWidth, double totalWidth) {
    controller.setPaneWidth(leftPane, currentWidth + details.delta.dx * 2.0, totalWidthPx: totalWidth);
  }

  @override
  Widget build(BuildContext context) {
    final visiblePanes = _paneOrder.where(state.activePanes.contains).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final dividerCount = visiblePanes.length - 1;
        final totalWidth = constraints.maxWidth - (dividerCount * _paneDividerWidth);

        final overrides = <DockPane, double>{};
        var overrideTotal = 0.0;
        for (final pane in visiblePanes) {
          final override = state.paneWidthOverrides[pane];
          if (override != null) {
            overrides[pane] = override;
            overrideTotal += override;
          }
        }
        final remainingPanes = visiblePanes.length - overrides.length;
        final remainingWidth = (totalWidth - overrideTotal).clamp(0.0, totalWidth);
        final sharedWidth = remainingPanes > 0 ? remainingWidth / remainingPanes : 0.0;

        final children = <Widget>[];
        for (var i = 0; i < visiblePanes.length; i++) {
          final pane = visiblePanes[i];
          final width = overrides[pane] ?? sharedWidth;
          children.add(SizedBox(width: width, child: _buildPane(pane)));

          if (i < visiblePanes.length - 1) {
            children.add(
              MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) =>
                      _onDividerDrag(details, pane, width, totalWidth),
                  child: Container(
                    width: _paneDividerWidth,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(width: 1, color: AppColors.border),
                    ),
                  ),
                ),
              ),
            );
          }
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }
}

const _kPillTickInterval = Duration(seconds: 1);
const String _kNoActiveTaskLabel = 'No active task · 0:00';

class _DockReopenPill extends StatefulWidget {
  final DockController controller;
  final DockStateData state;

  const _DockReopenPill({required this.controller, required this.state});

  @override
  State<_DockReopenPill> createState() => _DockReopenPillState();
}

class _DockReopenPillState extends State<_DockReopenPill> {
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _tickTimer = Timer.periodic(_kPillTickInterval, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  String _label(AgentRunStateData? runState) {
    if (runState == null || runState.status != AgentRunStatus.running) {
      return _kNoActiveTaskLabel;
    }
    final skill = runState.skill;
    final startedAt = runState.startedAt;
    final elapsed = startedAt == null ? Duration.zero : DateTime.now().difference(startedAt);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    final elapsedLabel = '$minutes:${seconds.toString().padLeft(2, '0')}';
    return '${skill?.label ?? 'Agent'} · $elapsedLabel';
  }

  Widget _buildPill(AgentRunStateData? runState) {
    final isRunning = runState?.status == AgentRunStatus.running;
    return Tooltip(
      message: 'Open panel',
      child: GestureDetector(
        onTap: widget.controller.reopen,
        child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isRunning ? AppStyling.spaceLg : AppStyling.spaceSm,
          vertical: AppStyling.spaceSm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          border: Border.all(color: AppColors.borderStrong),
          borderRadius: BorderRadius.circular(AppStyling.radiusXl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRunning) ...[
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.statusInProgress,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppStyling.spaceSm),
              Text(_label(runState), style: AppStyling.bodySm),
              const SizedBox(width: AppStyling.spaceSm),
            ],
            const Icon(Icons.keyboard_arrow_up, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final runController = widget.state.agentRunController;
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(AppStyling.spaceLg),
        child: runController == null
            ? _buildPill(null)
            : StreamBuilder<AgentRunStateData>(
                stream: runController.stream,
                initialData: runController.state,
                builder: (context, snapshot) => _buildPill(snapshot.data),
              ),
      ),
    );
  }
}
