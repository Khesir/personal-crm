class PortfolioProject {
  final String id;
  final String name;
  final String? releasedDate;
  final String? imageUrl;
  final List<String> languages;
  final String? url;
  final String? deployment;
  final bool draft;
  final bool pinned;

  const PortfolioProject({
    required this.id,
    required this.name,
    this.releasedDate,
    this.imageUrl,
    required this.languages,
    this.url,
    this.deployment,
    required this.draft,
    required this.pinned,
  });

  factory PortfolioProject.fromJson(Map<String, dynamic> json) => PortfolioProject(
        id: (json['id'] ?? json['_id'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        releasedDate: json['releasedDate'] as String?,
        imageUrl: json['imageUrl'] as String?,
        languages: (json['languages'] as List<dynamic>?)?.cast<String>() ?? [],
        url: json['url'] as String?,
        deployment: json['deployment'] as String?,
        draft: (json['draft'] as bool?) ?? false,
        pinned: (json['pinned'] as bool?) ?? false,
      );
}
