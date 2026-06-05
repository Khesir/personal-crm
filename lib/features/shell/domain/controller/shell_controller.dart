import 'package:crm/core/state/state.dart';
import '../../presentation/state/shell_state.dart';

class ShellController extends StreamState<ShellStateData> {
  ShellController()
      : super(const ShellStateData(
          selectedTab: AppTab.portfolio,
          selectedSection: AppSection.overview,
        ));

  void selectTab(AppTab tab) {
    final sections = kTabSections[tab]!;
    final section = sections.first;
    emit(state.copyWith(selectedTab: tab, selectedSection: section));
  }

  void selectSection(AppSection section) {
    emit(state.copyWith(selectedSection: section));
  }
}
