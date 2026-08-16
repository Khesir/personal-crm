enum SettingsSection {
  projects,
  about;

  String get label => switch (this) {
        SettingsSection.projects => 'Projects',
        SettingsSection.about => 'About',
      };
}

class ShellStateData {
  final bool showingSettings;
  final String? selectedProjectId;
  final SettingsSection selectedSettingsSection;

  const ShellStateData({
    required this.showingSettings,
    this.selectedProjectId,
    required this.selectedSettingsSection,
  });

  ShellStateData copyWith({
    bool? showingSettings,
    String? selectedProjectId,
    SettingsSection? selectedSettingsSection,
  }) {
    return ShellStateData(
      showingSettings: showingSettings ?? this.showingSettings,
      selectedProjectId: selectedProjectId ?? this.selectedProjectId,
      selectedSettingsSection: selectedSettingsSection ?? this.selectedSettingsSection,
    );
  }
}
