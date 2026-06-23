enum AppTab {
  home,
  projects,
  settings;

  String get label => switch (this) {
        AppTab.home => 'Home',
        AppTab.projects => 'Projects',
        AppTab.settings => 'Settings',
      };
}

enum SettingsSection {
  projects,
  services,
  brain,
  agent,
  about;

  String get label => switch (this) {
        SettingsSection.projects => 'Projects',
        SettingsSection.services => 'Services',
        SettingsSection.brain => 'Brain',
        SettingsSection.agent => 'Agent',
        SettingsSection.about => 'About',
      };
}

class ShellStateData {
  final AppTab selectedTab;
  final String? selectedProjectId;
  final SettingsSection selectedSettingsSection;

  const ShellStateData({
    required this.selectedTab,
    this.selectedProjectId,
    required this.selectedSettingsSection,
  });

  ShellStateData copyWith({
    AppTab? selectedTab,
    String? selectedProjectId,
    SettingsSection? selectedSettingsSection,
  }) {
    return ShellStateData(
      selectedTab: selectedTab ?? this.selectedTab,
      selectedProjectId: selectedProjectId ?? this.selectedProjectId,
      selectedSettingsSection: selectedSettingsSection ?? this.selectedSettingsSection,
    );
  }
}
