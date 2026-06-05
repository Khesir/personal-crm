class PortfolioHomeConfig {
  final String name;
  final String role;
  final String description;
  final String contactEmail;
  final bool available;
  final String bannerTitle;
  final String bannerSubtitle;
  final String? profileImageUrl;
  final String? bannerImageUrl;
  final List<PortfolioLanguage> languages;

  const PortfolioHomeConfig({
    required this.name,
    required this.role,
    required this.description,
    required this.contactEmail,
    required this.available,
    required this.bannerTitle,
    required this.bannerSubtitle,
    this.profileImageUrl,
    this.bannerImageUrl,
    required this.languages,
  });

  factory PortfolioHomeConfig.fromJson(Map<String, dynamic> json) =>
      PortfolioHomeConfig(
        name: (json['name'] ?? '') as String,
        role: (json['role'] ?? '') as String,
        description: (json['description'] ?? '') as String,
        contactEmail: (json['contactEmail'] ?? '') as String,
        available: (json['available'] as bool?) ?? false,
        bannerTitle: (json['bannerTitle'] ?? '') as String,
        bannerSubtitle: (json['bannerSubtitle'] ?? '') as String,
        profileImageUrl: json['profileImageUrl'] as String?,
        bannerImageUrl: json['bannerImageUrl'] as String?,
        languages: (json['languages'] as List<dynamic>?)
                ?.map((e) => PortfolioLanguage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class PortfolioLanguage {
  final String icon;
  final String? label;
  const PortfolioLanguage({required this.icon, this.label});
  factory PortfolioLanguage.fromJson(Map<String, dynamic> json) =>
      PortfolioLanguage(
        icon: (json['icon'] ?? '') as String,
        label: json['label'] as String?,
      );
}

class PortfolioAboutConfig {
  final String professionalSummary;
  final List<SkillCategory> technicalSkills;
  final List<String> coreCompetencies;
  final String lastUpdatedAt;
  final String location;

  const PortfolioAboutConfig({
    required this.professionalSummary,
    required this.technicalSkills,
    required this.coreCompetencies,
    required this.lastUpdatedAt,
    required this.location,
  });

  factory PortfolioAboutConfig.fromJson(Map<String, dynamic> json) =>
      PortfolioAboutConfig(
        professionalSummary: (json['professionalSummary'] ?? '') as String,
        technicalSkills: (json['technicalSkills'] as List<dynamic>?)
                ?.map((e) => SkillCategory.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        coreCompetencies:
            (json['coreCompetencies'] as List<dynamic>?)?.cast<String>() ?? [],
        lastUpdatedAt: (json['lastUpdatedAt'] ?? '') as String,
        location: (json['location'] ?? '') as String,
      );
}

class SkillCategory {
  final String category;
  final List<String> items;
  const SkillCategory({required this.category, required this.items});
  factory SkillCategory.fromJson(Map<String, dynamic> json) => SkillCategory(
        category: (json['category'] ?? '') as String,
        items: (json['items'] as List<dynamic>?)?.cast<String>() ?? [],
      );
}

class PortfolioServicesConfig {
  final List<PortfolioService> services;
  const PortfolioServicesConfig({required this.services});
  factory PortfolioServicesConfig.fromJson(Map<String, dynamic> json) =>
      PortfolioServicesConfig(
        services: (json['services'] as List<dynamic>?)
                ?.map((e) => PortfolioService.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class PortfolioService {
  final String icon;
  final String title;
  final String mainTag;
  final String description;
  final List<String> tags;
  const PortfolioService({
    required this.icon,
    required this.title,
    required this.mainTag,
    required this.description,
    required this.tags,
  });
  factory PortfolioService.fromJson(Map<String, dynamic> json) =>
      PortfolioService(
        icon: (json['icon'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        mainTag: (json['mainTag'] ?? '') as String,
        description: (json['description'] ?? '') as String,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      );
}
