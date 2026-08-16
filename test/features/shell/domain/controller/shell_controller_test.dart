import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/shell/domain/controller/shell_controller.dart';
import 'package:crm/features/shell/presentation/state/shell_state.dart';

void main() {
  group('ShellController', () {
    test('initial state has no project selected and settings not showing', () {
      final controller = ShellController();

      expect(controller.state.showingSettings, isFalse);
      expect(controller.state.selectedProjectId, isNull);
      expect(controller.state.selectedSettingsSection, SettingsSection.projects);

      controller.dispose();
    });

    test('selectProject sets selectedProjectId and hides settings', () {
      final controller = ShellController();
      controller.openSettings();

      controller.selectProject('keep-track');

      expect(controller.state.selectedProjectId, 'keep-track');
      expect(controller.state.showingSettings, isFalse);

      controller.dispose();
    });

    test('openSettings shows settings without changing the section', () {
      final controller = ShellController();
      controller.selectSettingsSection(SettingsSection.about);

      controller.openSettings();

      expect(controller.state.showingSettings, isTrue);
      expect(controller.state.selectedSettingsSection, SettingsSection.about);

      controller.dispose();
    });

    test('selectSettingsSection switches the active section and shows settings', () {
      final controller = ShellController();

      controller.selectSettingsSection(SettingsSection.about);

      expect(controller.state.selectedSettingsSection, SettingsSection.about);
      expect(controller.state.showingSettings, isTrue);

      controller.dispose();
    });
  });
}
