import 'package:crm/core/state/state.dart';
import '../../presentation/state/shell_state.dart';

class ShellController extends StreamState<ShellStateData> {
  ShellController()
      : super(const ShellStateData(
          selectedTab: AppTab.home,
          selectedSettingsSection: SettingsSection.projects,
        ));

  void selectTab(AppTab tab) {
    emit(state.copyWith(selectedTab: tab));
  }

  void selectProject(String projectId) {
    emit(state.copyWith(selectedProjectId: projectId));
  }

  void selectSettingsSection(SettingsSection section) {
    emit(state.copyWith(selectedSettingsSection: section));
  }
}
