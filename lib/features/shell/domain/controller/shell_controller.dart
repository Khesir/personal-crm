import 'package:crm/core/state/state.dart';
import '../../presentation/state/shell_state.dart';

class ShellController extends StreamState<ShellStateData> {
  ShellController()
      : super(const ShellStateData(
          selectedTab: AppTab.home,
          selectedProjectSection: ProjectSection.kanban,
          selectedSettingsSection: SettingsSection.projects,
        ));

  void selectTab(AppTab tab) {
    emit(state.copyWith(selectedTab: tab));
  }

  void selectProject(String projectId) {
    emit(state.copyWith(
      selectedProjectId: projectId,
      selectedProjectSection: ProjectSection.kanban,
    ));
  }

  void selectProjectSection(
    ProjectSection section, {
    Set<ProjectSection>? enabledSections,
  }) {
    if (enabledSections != null && !enabledSections.contains(section)) return;
    emit(state.copyWith(selectedProjectSection: section));
  }

  void selectSettingsSection(SettingsSection section) {
    emit(state.copyWith(selectedSettingsSection: section));
  }
}
