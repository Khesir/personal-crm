/// The contents of a project's `.avyn/project.json` — the authoritative
/// record of its name/icon/settings, portable with the project folder. See
/// `docs/adr/0004-avyn-folder-project-metadata.md`.
class ProjectMetadata {
  final String id;
  final String name;
  final String? iconFileName;
  final Map<String, dynamic> settings;

  const ProjectMetadata({
    required this.id,
    required this.name,
    this.iconFileName,
    this.settings = const {},
  });

  ProjectMetadata copyWith({
    String? name,
    // Tri-state: omit to leave iconFileName untouched, or pass a callback
    // (even one that returns null) to explicitly set/clear it.
    String? Function()? iconFileName,
  }) {
    return ProjectMetadata(
      id: id,
      name: name ?? this.name,
      iconFileName: iconFileName != null ? iconFileName() : this.iconFileName,
      settings: settings,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': iconFileName,
        'settings': settings,
      };

  factory ProjectMetadata.fromJson(Map<String, dynamic> json) => ProjectMetadata(
        id: json['id'] as String,
        name: json['name'] as String,
        iconFileName: json['icon'] as String?,
        settings: (json['settings'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}
