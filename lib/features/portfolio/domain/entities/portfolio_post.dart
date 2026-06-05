class PortfolioPost {
  final String id;
  final String content;
  final List<String> tags;
  final bool draft;
  final bool pinned;
  final String createdAt;

  const PortfolioPost({
    required this.id,
    required this.content,
    required this.tags,
    required this.draft,
    required this.pinned,
    required this.createdAt,
  });

  factory PortfolioPost.fromJson(Map<String, dynamic> json) => PortfolioPost(
        id: (json['id'] ?? json['_id'] ?? '') as String,
        content: (json['content'] ?? '') as String,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        draft: (json['draft'] as bool?) ?? false,
        pinned: (json['pinned'] as bool?) ?? false,
        createdAt: (json['createdAt'] ?? '') as String,
      );
}
