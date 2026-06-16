import 'package:flutter/material.dart';
import 'package:crm/features/kanban/api.dart';

/// Renders [content] filling the available space with [BoardDockSection] as
/// a bottom overlay on top of it. The dock is omitted entirely when
/// [showDock] is false (e.g. a read-only/archived Kanban board), and
/// [content]'s size is unaffected by the dock's height, collapse, or reopen
/// state.
class ProjectContentDockOverlay extends StatelessWidget {
  final Widget content;
  final DockController dockController;
  final String projectName;
  final bool showDock;
  final TerminalSessionController? terminalSessionController;

  const ProjectContentDockOverlay({
    super.key,
    required this.content,
    required this.dockController,
    required this.projectName,
    this.showDock = true,
    this.terminalSessionController,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: content),
        if (showDock)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BoardDockSection(
              controller: dockController,
              projectName: projectName,
              terminalSessionController: terminalSessionController,
            ),
          ),
      ],
    );
  }
}
