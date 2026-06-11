import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/shell/domain/controller/shell_controller.dart';
import 'package:crm/features/shell/presentation/state/shell_state.dart';

void main() {
  group('ShellController', () {
    test('initial state is home tab and kanban section', () {
      final controller = ShellController();

      expect(controller.state.selectedTab, AppTab.home);
      expect(controller.state.selectedProjectId, isNull);
      expect(controller.state.selectedProjectSection, ProjectSection.kanban);

      controller.dispose();
    });

    test('selectTab switches the active tab', () {
      final controller = ShellController();

      controller.selectTab(AppTab.projects);

      expect(controller.state.selectedTab, AppTab.projects);

      controller.dispose();
    });

    test('selectProject sets selectedProjectId and resets section to kanban', () {
      final controller = ShellController();

      controller.selectProjectSection(ProjectSection.announcements);
      controller.selectProject('keep-track');

      expect(controller.state.selectedProjectId, 'keep-track');
      expect(controller.state.selectedProjectSection, ProjectSection.kanban);

      controller.dispose();
    });

    test('selectProjectSection updates the section', () {
      final controller = ShellController();

      controller.selectProjectSection(ProjectSection.bugReports);

      expect(controller.state.selectedProjectSection, ProjectSection.bugReports);

      controller.dispose();
    });

    test('selectProjectSection updates the section when enabled', () {
      final controller = ShellController();

      controller.selectProjectSection(
        ProjectSection.bugReports,
        enabledSections: {ProjectSection.kanban, ProjectSection.bugReports},
      );

      expect(controller.state.selectedProjectSection, ProjectSection.bugReports);

      controller.dispose();
    });

    test('selectProjectSection is a no-op when section is not enabled', () {
      final controller = ShellController();

      controller.selectProjectSection(
        ProjectSection.bugReports,
        enabledSections: {ProjectSection.kanban},
      );

      expect(controller.state.selectedProjectSection, ProjectSection.kanban);

      controller.dispose();
    });
  });
}
