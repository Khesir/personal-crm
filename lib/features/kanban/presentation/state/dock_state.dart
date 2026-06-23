import 'package:crm/core/state/state.dart';

enum DockPane { terminal, chat }

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

  const DockStateData({
    this.heightPx = dockDefaultHeight,
    this.collapsed = false,
    this.activePanes = _defaultActivePanes,
    this.paneWidthOverrides = const {},
  });

  DockStateData copyWith({
    double? heightPx,
    bool? collapsed,
    Set<DockPane>? activePanes,
    Map<DockPane, double>? paneWidthOverrides,
  }) {
    return DockStateData(
      heightPx: heightPx ?? this.heightPx,
      collapsed: collapsed ?? this.collapsed,
      activePanes: activePanes ?? this.activePanes,
      paneWidthOverrides: paneWidthOverrides ?? this.paneWidthOverrides,
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
}
