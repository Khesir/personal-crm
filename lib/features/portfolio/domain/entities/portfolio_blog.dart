class PortfolioBlog {
  final String id;
  final String name;
  final String? releasedDate;
  final String? imageUrl;
  final List<String> tags;
  final int? minRead;
  final bool draft;
  final bool hideViews;
  final bool hideHearts;

  const PortfolioBlog({
    required this.id,
    required this.name,
    this.releasedDate,
    this.imageUrl,
    required this.tags,
    this.minRead,
    required this.draft,
    required this.hideViews,
    required this.hideHearts,
  });

  factory PortfolioBlog.fromJson(Map<String, dynamic> json) => PortfolioBlog(
        id: (json['id'] ?? json['_id'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        releasedDate: json['releasedDate'] as String?,
        imageUrl: json['imageUrl'] as String?,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        minRead: json['minRead'] as int?,
        draft: (json['draft'] as bool?) ?? false,
        hideViews: (json['hideViews'] as bool?) ?? false,
        hideHearts: (json['hideHearts'] as bool?) ?? false,
      );
}
