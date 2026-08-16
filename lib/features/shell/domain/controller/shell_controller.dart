import 'package:crm/core/state/state.dart';
import '../../presentation/state/shell_state.dart';

class ShellController extends StreamState<ShellStateData> {
  ShellController()
      : super(const ShellStateData(
          showingSettings: false,
          selectedSettingsSection: SettingsSection.projects,
        ));

  void selectProject(String projectId) {
    emit(state.copyWith(selectedProjectId: projectId, showingSettings: false));
  }

  void openSettings() {
    emit(state.copyWith(showingSettings: true));
  }

  void selectSettingsSection(SettingsSection section) {
    emit(state.copyWith(selectedSettingsSection: section, showingSettings: true));
  }
}
