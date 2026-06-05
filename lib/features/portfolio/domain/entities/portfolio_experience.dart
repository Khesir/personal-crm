class PortfolioExperience {
  final String id;
  final String position;
  final String companyName;
  final String jobType;
  final String employmentType;
  final String durationStart;
  final String? durationEnd;
  final bool draft;

  const PortfolioExperience({
    required this.id,
    required this.position,
    required this.companyName,
    required this.jobType,
    required this.employmentType,
    required this.durationStart,
    this.durationEnd,
    required this.draft,
  });

  factory PortfolioExperience.fromJson(Map<String, dynamic> json) => PortfolioExperience(
        id: (json['id'] ?? json['_id'] ?? '') as String,
        position: (json['position'] ?? '') as String,
        companyName: (json['companyName'] ?? '') as String,
        jobType: (json['jobType'] ?? 'Remote') as String,
        employmentType: (json['employmentType'] ?? 'Full-time') as String,
        durationStart: (json['durationStart'] ?? '') as String,
        durationEnd: json['durationEnd'] as String?,
        draft: (json['draft'] as bool?) ?? false,
      );
}
