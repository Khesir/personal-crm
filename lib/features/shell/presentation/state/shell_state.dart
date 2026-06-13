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

enum ProjectSection {
  kanban,
  bugReports,
  announcements;

  String get label => switch (this) {
        ProjectSection.kanban => 'Kanban',
        ProjectSection.bugReports => 'Bug Reports',
        ProjectSection.announcements => 'Announcements',
      };
}

enum SettingsSection {
  projects,
  services,
  brain,
  about;

  String get label => switch (this) {
        SettingsSection.projects => 'Projects',
        SettingsSection.services => 'Services',
        SettingsSection.brain => 'Brain',
        SettingsSection.about => 'About',
      };
}

class ShellStateData {
  final AppTab selectedTab;
  final String? selectedProjectId;
  final ProjectSection selectedProjectSection;
  final SettingsSection selectedSettingsSection;

  const ShellStateData({
    required this.selectedTab,
    this.selectedProjectId,
    required this.selectedProjectSection,
    required this.selectedSettingsSection,
  });

  ShellStateData copyWith({
    AppTab? selectedTab,
    String? selectedProjectId,
    ProjectSection? selectedProjectSection,
    SettingsSection? selectedSettingsSection,
  }) {
    return ShellStateData(
      selectedTab: selectedTab ?? this.selectedTab,
      selectedProjectId: selectedProjectId ?? this.selectedProjectId,
      selectedProjectSection: selectedProjectSection ?? this.selectedProjectSection,
      selectedSettingsSection: selectedSettingsSection ?? this.selectedSettingsSection,
    );
  }
}
