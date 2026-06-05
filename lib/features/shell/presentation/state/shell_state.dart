enum AppTab {
  portfolio,
  keepTrack,
  timeTracker,
  ariConnect,
  minecraft;

  String get label => switch (this) {
        AppTab.portfolio => 'Portfolio',
        AppTab.keepTrack => 'Keep Track',
        AppTab.timeTracker => 'Time Tracker',
        AppTab.ariConnect => 'Ari Connect',
        AppTab.minecraft => 'Minecraft',
      };
}

enum AppSection {
  overview,
  announcements,
  releases,
  analytics,
  support,
  blogs,
  projects,
  experiences,
  posts,
  home,
  about,
  services,
  settings;

  String get label => switch (this) {
        AppSection.overview => 'Overview',
        AppSection.announcements => 'Announcements',
        AppSection.releases => 'Releases',
        AppSection.analytics => 'Analytics',
        AppSection.support => 'Support',
        AppSection.blogs => 'Blogs',
        AppSection.projects => 'Projects',
        AppSection.experiences => 'Experiences',
        AppSection.posts => 'Posts',
        AppSection.home => 'Home',
        AppSection.about => 'About',
        AppSection.services => 'Services',
        AppSection.settings => 'Settings',
      };
}

const Map<AppTab, List<AppSection>> kTabSections = {
  AppTab.portfolio: [
    AppSection.overview,
    AppSection.blogs,
    AppSection.projects,
    AppSection.experiences,
    AppSection.posts,
    AppSection.home,
    AppSection.about,
    AppSection.services,
    AppSection.settings,
  ],
  AppTab.keepTrack: [
    AppSection.overview,
    AppSection.announcements,
    AppSection.releases,
    AppSection.analytics,
    AppSection.support,
    AppSection.settings,
  ],
  AppTab.timeTracker: [AppSection.overview, AppSection.settings],
  AppTab.ariConnect: [AppSection.overview, AppSection.analytics, AppSection.settings],
  AppTab.minecraft: [AppSection.overview, AppSection.settings],
};

typedef SectionGroup = ({String? label, List<AppSection> sections});

const Map<AppTab, List<SectionGroup>> kTabSectionGroups = {
  AppTab.portfolio: [
    (label: null, sections: [AppSection.overview]),
    (label: 'Data', sections: [AppSection.blogs, AppSection.projects, AppSection.experiences, AppSection.posts]),
    (label: 'Pages', sections: [AppSection.home, AppSection.about, AppSection.services]),
  ],
};

class ShellStateData {
  final AppTab selectedTab;
  final AppSection selectedSection;

  const ShellStateData({
    required this.selectedTab,
    required this.selectedSection,
  });

  ShellStateData copyWith({AppTab? selectedTab, AppSection? selectedSection}) {
    return ShellStateData(
      selectedTab: selectedTab ?? this.selectedTab,
      selectedSection: selectedSection ?? this.selectedSection,
    );
  }
}
