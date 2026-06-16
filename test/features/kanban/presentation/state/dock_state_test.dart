import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/agent_run/domain/controller/agent_run_controller.dart';
import 'package:crm/features/agent_run/domain/model/agent_event.dart';
import 'package:crm/features/agent_run/domain/repository/agent_run_repository.dart';
import 'package:crm/features/kanban/presentation/state/dock_state.dart';

class FakeAgentRunRepository implements AgentRunRepository {
  @override
  Stream<AgentEvent> run({
    required String skill,
    required String repoPath,
    Map<String, dynamic>? context,
  }) {
    return const Stream<AgentEvent>.empty();
  }
}

void main() {
  group('DockController', () {
    test('starts not collapsed with default height and default active panes', () {
      final controller = DockController();

      expect(controller.state.collapsed, isFalse);
      expect(controller.state.heightPx, dockDefaultHeight);
      expect(controller.state.activePanes, {DockPane.terminal, DockPane.chat});
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

      controller.togglePane(DockPane.agent);

      expect(controller.state.activePanes, {DockPane.terminal, DockPane.chat, DockPane.agent});

      controller.dispose();
    });

    test('togglePane() removes an active pane from activePanes', () {
      final controller = DockController();

      controller.togglePane(DockPane.terminal);

      expect(controller.state.activePanes, {DockPane.chat});

      controller.dispose();
    });

    test('togglePane() is a no-op when pane is the only active pane', () {
      final controller = DockController();

      controller.togglePane(DockPane.terminal);
      expect(controller.state.activePanes, {DockPane.chat});

      controller.togglePane(DockPane.chat);

      expect(controller.state.activePanes, {DockPane.chat});

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

    test('setPaneWidth() clamps so other visible panes keep at least dockMinPaneWidth', () {
      final controller = DockController();
      // Default active panes: terminal, chat. 1000px total, min pane width
      // 240px => terminal can be at most 1000 - 240 = 760px.
      controller.setPaneWidth(DockPane.terminal, 900, totalWidthPx: 1000);

      expect(controller.state.paneWidthOverrides[DockPane.terminal], 1000 - dockMinPaneWidth);

      controller.dispose();
    });

    test('setPaneWidth() clamps against all visible panes with three active', () {
      final controller = DockController();
      controller.togglePane(DockPane.agent);
      // Three panes visible; terminal can be at most
      // 1000 - (240 * 2) = 520px.
      controller.setPaneWidth(DockPane.terminal, 900, totalWidthPx: 1000);

      expect(controller.state.paneWidthOverrides[DockPane.terminal], 1000 - (dockMinPaneWidth * 2));

      controller.dispose();
    });

    test('collapse()/reopen() preserve activePanes, paneWidthOverrides, and heightPx', () {
      final controller = DockController();

      controller.togglePane(DockPane.agent);
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

    test('setAgentRunController() adds DockPane.agent without removing other active panes', () {
      final controller = DockController();
      final runController = AgentRunController(FakeAgentRunRepository());

      controller.togglePane(DockPane.terminal); // -> only chat active
      expect(controller.state.activePanes, {DockPane.chat});

      controller.setAgentRunController(runController);

      expect(controller.state.activePanes, {DockPane.chat, DockPane.agent});
      expect(controller.state.agentRunController, runController);

      controller.dispose();
      runController.dispose();
    });

    test('setAgentRunController() clears collapsed', () {
      final controller = DockController();
      final runController = AgentRunController(FakeAgentRunRepository());

      controller.collapse();
      expect(controller.state.collapsed, isTrue);

      controller.setAgentRunController(runController);

      expect(controller.state.collapsed, isFalse);

      controller.dispose();
      runController.dispose();
    });

    test('clearAgentRunController() clears the controller reference', () {
      final controller = DockController();
      final runController = AgentRunController(FakeAgentRunRepository());

      controller.setAgentRunController(runController);
      expect(controller.state.agentRunController, runController);

      controller.clearAgentRunController();

      expect(controller.state.agentRunController, isNull);

      controller.dispose();
      runController.dispose();
    });
  });
}
