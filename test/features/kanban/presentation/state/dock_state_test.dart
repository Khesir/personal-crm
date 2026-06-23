import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/kanban/presentation/state/dock_state.dart';

void main() {
  group('DockController', () {
    test('DockPane has exactly two values: terminal and chat', () {
      expect(DockPane.values.length, 2);
      expect(DockPane.values, containsAll([DockPane.terminal, DockPane.chat]));
    });

    test('starts not collapsed with default height and default active panes', () {
      final controller = DockController();

      expect(controller.state.collapsed, isFalse);
      expect(controller.state.heightPx, dockDefaultHeight);
      expect(controller.state.activePanes, {DockPane.terminal});
      expect(controller.state.paneWidthOverrides, isEmpty);

      controller.dispose();
    });

    test('collapse() sets collapsed to true', () {
      final controller = DockController();

      controller.collapse();

      expect(controller.state.collapsed, isTrue);

      controller.dispose();
    });

    test('reopen() sets collapsed back to false', () {
      final controller = DockController();

      controller.collapse();
      controller.reopen();

      expect(controller.state.collapsed, isFalse);

      controller.dispose();
    });

    test('setHeight() updates heightPx within range', () {
      final controller = DockController();

      controller.setHeight(400);

      expect(controller.state.heightPx, 400);

      controller.dispose();
    });

    test('setHeight() clamps to dockMinHeight when below minimum', () {
      final controller = DockController();

      controller.setHeight(10);

      expect(controller.state.heightPx, dockMinHeight);

      controller.dispose();
    });

    test('setHeight() clamps to dockMaxHeight when above maximum', () {
      final controller = DockController();

      controller.setHeight(5000);

      expect(controller.state.heightPx, dockMaxHeight);

      controller.dispose();
    });

    test('togglePane() adds an inactive pane to activePanes', () {
      final controller = DockController();

      controller.togglePane(DockPane.chat);

      expect(controller.state.activePanes, {DockPane.terminal, DockPane.chat});

      controller.dispose();
    });

    test('togglePane() removes an active pane from activePanes', () {
      final controller = DockController();

      controller.togglePane(DockPane.chat);
      controller.togglePane(DockPane.terminal);

      expect(controller.state.activePanes, {DockPane.chat});

      controller.dispose();
    });

    test('togglePane() is a no-op when pane is the only active pane', () {
      final controller = DockController();

      controller.togglePane(DockPane.terminal);

      expect(controller.state.activePanes, {DockPane.terminal});

      controller.dispose();
    });

    test('setPaneWidth() sets a fixed width for a pane', () {
      final controller = DockController();

      controller.setPaneWidth(DockPane.terminal, 400, totalWidthPx: 1000);

      expect(controller.state.paneWidthOverrides[DockPane.terminal], 400);

      controller.dispose();
    });

    test('setPaneWidth() clamps to dockMinPaneWidth when below minimum', () {
      final controller = DockController();

      controller.setPaneWidth(DockPane.terminal, 50, totalWidthPx: 1000);

      expect(controller.state.paneWidthOverrides[DockPane.terminal], dockMinPaneWidth);

      controller.dispose();
    });

    test('setPaneWidth() clamps so other visible pane keeps at least dockMinPaneWidth', () {
      final controller = DockController();
      controller.togglePane(DockPane.chat);
      // Two panes visible; terminal can be at most 1000 - 240 = 760px.
      controller.setPaneWidth(DockPane.terminal, 900, totalWidthPx: 1000);

      expect(controller.state.paneWidthOverrides[DockPane.terminal], 1000 - dockMinPaneWidth);

      controller.dispose();
    });

    test('collapse()/reopen() preserve activePanes, paneWidthOverrides, and heightPx', () {
      final controller = DockController();

      controller.togglePane(DockPane.chat);
      controller.setPaneWidth(DockPane.terminal, 300, totalWidthPx: 1000);
      controller.setHeight(450);

      final activePanesBefore = controller.state.activePanes;
      final overridesBefore = controller.state.paneWidthOverrides;
      final heightBefore = controller.state.heightPx;

      controller.collapse();
      expect(controller.state.collapsed, isTrue);
      expect(controller.state.activePanes, activePanesBefore);
      expect(controller.state.paneWidthOverrides, overridesBefore);
      expect(controller.state.heightPx, heightBefore);

      controller.reopen();
      expect(controller.state.collapsed, isFalse);
      expect(controller.state.activePanes, activePanesBefore);
      expect(controller.state.paneWidthOverrides, overridesBefore);
      expect(controller.state.heightPx, heightBefore);

      controller.dispose();
    });
  });
}
