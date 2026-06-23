import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/shell/domain/controller/shell_controller.dart';
import 'package:crm/features/shell/presentation/state/shell_state.dart';

void main() {
  group('ShellController', () {
    test('initial state is home tab', () {
      final controller = ShellController();

      expect(controller.state.selectedTab, AppTab.home);
      expect(controller.state.selectedProjectId, isNull);

      controller.dispose();
    });

    test('selectTab switches the active tab', () {
      final controller = ShellController();

      controller.selectTab(AppTab.projects);

      expect(controller.state.selectedTab, AppTab.projects);

      controller.dispose();
    });

    test('selectProject sets selectedProjectId', () {
      final controller = ShellController();

      controller.selectProject('keep-track');

      expect(controller.state.selectedProjectId, 'keep-track');

      controller.dispose();
    });
  });
}
