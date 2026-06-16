import 'dart:io';

import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/kanban/data/repository/pty_terminal_session.dart';
import 'package:crm/features/kanban/domain/repository/terminal_session.dart';
import '../state/terminal_session_controller.dart';

const double _kPaneHeaderHeight = 32;
const double _kSessionTabHeight = 24;

const TerminalTheme _kTerminalTheme = TerminalTheme(
  cursor: AppColors.termForeground,
  selection: AppColors.borderStrong,
  foreground: AppColors.termForeground,
  background: AppColors.termBackground,
  black: Color(0xFF000000),
  white: AppColors.termForeground,
  red: AppColors.termRed,
  green: AppColors.termGreen,
  yellow: AppColors.termYellow,
  blue: AppColors.termCyan,
  magenta: AppColors.termCyan,
  cyan: AppColors.termCyan,
  brightBlack: AppColors.textTertiary,
  brightRed: AppColors.termRed,
  brightGreen: AppColors.termGreen,
  brightYellow: AppColors.termYellow,
  brightBlue: AppColors.termCyan,
  brightMagenta: AppColors.termCyan,
  brightCyan: AppColors.termCyan,
  brightWhite: AppColors.termForeground,
  searchHitBackground: AppColors.accentBg,
  searchHitBackgroundCurrent: AppColors.accent,
  searchHitForeground: AppColors.termForeground,
);

bool isPtySupported() {
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

/// The Kanban dock's Terminal pane: a real interactive shell (via
/// `flutter_pty` + `xterm`) scoped to the project's working directory, with
/// session tabs. On platforms without PTY support, shows an "unavailable"
/// state instead.
class TerminalPane extends StatefulWidget {
  final String projectName;
  final TerminalSessionController? sessionController;

  const TerminalPane({
    super.key,
    required this.projectName,
    required this.sessionController,
  });

  @override
  State<TerminalPane> createState() => _TerminalPaneState();
}

class _TerminalPaneState extends State<TerminalPane> {
  late final List<ShellOption> _availableShells;

  @override
  void initState() {
    super.initState();
    _availableShells = isPtySupported() ? PtyTerminalSession.availableShells() : [];
    final controller = widget.sessionController;
    if (controller != null && controller.state.tabs.isEmpty) {
      controller.createSession(shell: _availableShells.isNotEmpty ? _availableShells.first : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.sessionController;
    return Container(
      color: AppColors.termBackground,
      child: Column(
        children: [
          _TerminalPaneHeader(controller: controller, availableShells: _availableShells),
          Expanded(
            child: controller == null
                ? _UnavailableState(projectName: widget.projectName)
                : _TerminalBody(controller: controller),
          ),
        ],
      ),
    );
  }
}

class _TerminalPaneHeader extends StatelessWidget {
  final TerminalSessionController? controller;
  final List<ShellOption> availableShells;

  const _TerminalPaneHeader({required this.controller, required this.availableShells});

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
          Text('Terminal', style: AppStyling.label),
          const Spacer(),
          if (controller != null)
            StreamBuilder<TerminalSessionStateData>(
              stream: controller!.stream,
              initialData: controller!.state,
              builder: (context, snapshot) {
                final state = snapshot.data!;
                return _SessionTabs(
                  controller: controller!,
                  state: state,
                  availableShells: availableShells,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SessionTabs extends StatelessWidget {
  final TerminalSessionController controller;
  final TerminalSessionStateData state;
  final List<ShellOption> availableShells;

  const _SessionTabs({
    required this.controller,
    required this.state,
    required this.availableShells,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final tab in state.tabs)
          _SessionTab(
            label: tab.label,
            shellLabel: tab.shellLabel,
            active: tab.id == state.activeTabId,
            onTap: () => controller.switchTab(tab.id),
            onClose: state.tabs.length > 1 ? () => controller.closeSession(tab.id) : null,
          ),
        _NewTabButton(
          availableShells: availableShells,
          onSelect: (shell) => controller.createSession(shell: shell),
        ),
      ],
    );
  }
}

class _SessionTab extends StatelessWidget {
  final String label;
  final String shellLabel;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  const _SessionTab({
    required this.label,
    required this.shellLabel,
    required this.active,
    required this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final displayLabel = shellLabel.isNotEmpty ? '$shellLabel $label' : label;
    final labelColor = active ? AppColors.textPrimary : AppColors.textTertiary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _kSessionTabHeight,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.only(
          left: AppStyling.spaceSm,
          right: AppStyling.spaceXs,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.surfaceRaised : Colors.transparent,
          border: Border.all(color: active ? AppColors.border : Colors.transparent),
          borderRadius: BorderRadius.circular(AppStyling.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal, size: 12, color: labelColor),
            const SizedBox(width: AppStyling.spaceXs),
            Text(displayLabel, style: AppStyling.label.copyWith(color: labelColor)),
            if (onClose != null) ...[
              const SizedBox(width: AppStyling.spaceXs),
              GestureDetector(
                onTap: onClose,
                child: Icon(Icons.close, size: 12, color: AppColors.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewTabButton extends StatelessWidget {
  final List<ShellOption> availableShells;
  final void Function(ShellOption shell) onSelect;

  const _NewTabButton({required this.availableShells, required this.onSelect});

  Future<void> _showPicker(BuildContext context) async {
    if (availableShells.length == 1) {
      onSelect(availableShells.first);
      return;
    }
    final box = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset(0, box.size.height), ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final selected = await showMenu<ShellOption>(
      context: context,
      position: position,
      color: AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      items: [
        for (final shell in availableShells)
          PopupMenuItem<ShellOption>(
            value: shell,
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: AppStyling.spaceSm),
                Text(shell.label, style: AppStyling.bodySm),
              ],
            ),
          ),
      ],
    );
    if (selected != null) onSelect(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'New terminal session',
      child: GestureDetector(
        onTap: () => _showPicker(context),
        child: Container(
          width: _kSessionTabHeight,
          height: _kSessionTabHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppStyling.radiusSm),
          ),
          child: const Icon(Icons.add, size: 14, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}

class _TerminalBody extends StatefulWidget {
  final TerminalSessionController controller;

  const _TerminalBody({required this.controller});

  @override
  State<_TerminalBody> createState() => _TerminalBodyState();
}

class _TerminalBodyState extends State<_TerminalBody> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TerminalSessionStateData>(
      stream: widget.controller.stream,
      initialData: widget.controller.state,
      builder: (context, snapshot) {
        final activeTab = snapshot.data!.activeTab;
        if (activeTab == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: _focusNode.requestFocus,
          child: TerminalView(
            activeTab.terminal,
            theme: _kTerminalTheme,
            focusNode: _focusNode,
            autofocus: true,
            hardwareKeyboardOnly: true,
          ),
        );
      },
    );
  }
}

class _UnavailableState extends StatelessWidget {
  final String projectName;

  const _UnavailableState({required this.projectName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyling.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyling.spaceMd,
                vertical: AppStyling.spaceXs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Terminal unavailable',
                style: AppStyling.label.copyWith(color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: AppStyling.spaceMd),
            Text(
              'A real terminal isn\'t supported on this platform for $projectName.',
              style: AppStyling.bodySm.copyWith(color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
