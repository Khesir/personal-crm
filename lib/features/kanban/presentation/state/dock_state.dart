import 'package:crm/core/state/state.dart';
import 'package:crm/features/agent_run/api.dart';

enum DockPane { terminal, agent, chat }

const double dockMinHeight = 120;
const double dockDefaultHeight = 336;
const double dockMaxHeight = 800;
const double dockCollapsedHeight = 10;

const double dockMinPaneWidth = 240;

const Set<DockPane> _defaultActivePanes = {DockPane.terminal};

class DockStateData {
  final double heightPx;
  final bool collapsed;
  final Set<DockPane> activePanes;
  final Map<DockPane, double> paneWidthOverrides;
  final AgentRunController? agentRunController;

  const DockStateData({
    this.heightPx = dockDefaultHeight,
    this.collapsed = false,
    this.activePanes = _defaultActivePanes,
    this.paneWidthOverrides = const {},
    this.agentRunController,
  });

  DockStateData copyWith({
    double? heightPx,
    bool? collapsed,
    Set<DockPane>? activePanes,
    Map<DockPane, double>? paneWidthOverrides,
    AgentRunController? agentRunController,
    bool clearAgentRunController = false,
  }) {
    return DockStateData(
      heightPx: heightPx ?? this.heightPx,
      collapsed: collapsed ?? this.collapsed,
      activePanes: activePanes ?? this.activePanes,
      paneWidthOverrides: paneWidthOverrides ?? this.paneWidthOverrides,
      agentRunController: clearAgentRunController
          ? null
          : (agentRunController ?? this.agentRunController),
    );
  }
}

class DockController extends StreamState<DockStateData> {
  DockController() : super(const DockStateData());

  void setHeight(double heightPx) {
    final clamped = heightPx.clamp(dockMinHeight, dockMaxHeight);
    update((current) => current.copyWith(heightPx: clamped));
  }

  void collapse() {
    update((current) => current.copyWith(collapsed: true));
  }

  void reopen() {
    update((current) => current.copyWith(collapsed: false));
  }

  /// Toggles [pane]'s membership in [DockStateData.activePanes]. No-op if
  /// [pane] is the only active pane — at least one pane must stay visible.
  void togglePane(DockPane pane) {
    update((current) {
      final active = current.activePanes;
      if (active.contains(pane)) {
        if (active.length == 1) return current;
        return current.copyWith(activePanes: {...active}..remove(pane));
      }
      return current.copyWith(activePanes: {...active, pane});
    });
  }

  /// Sets a fixed pixel width for [pane], clamping so every currently
  /// visible pane keeps at least [dockMinPaneWidth].
  void setPaneWidth(DockPane pane, double widthPx, {required double totalWidthPx}) {
    update((current) {
      final visibleCount = current.activePanes.length;
      final maxWidth = totalWidthPx - (dockMinPaneWidth * (visibleCount - 1));
      final clamped = widthPx.clamp(
        dockMinPaneWidth,
        maxWidth < dockMinPaneWidth ? dockMinPaneWidth : maxWidth,
      );
      return current.copyWith(
        paneWidthOverrides: {...current.paneWidthOverrides, pane: clamped},
      );
    });
  }

  /// Routes an [AgentRunController] into the dock, adding the Agent pane to
  /// the visible set (without removing other active panes) and expanding the
  /// dock if collapsed.
  void setAgentRunController(AgentRunController controller) {
    update((current) {
      return current.copyWith(
        agentRunController: controller,
        collapsed: false,
        activePanes: {...current.activePanes, DockPane.agent},
      );
    });
  }

  void clearAgentRunController() {
    update((current) => current.copyWith(clearAgentRunController: true));
  }
}
