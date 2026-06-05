enum TicketType { bug, question, feature, other;
  String get label => switch (this) {
    TicketType.bug => 'Bug',
    TicketType.question => 'Question',
    TicketType.feature => 'Feature',
    TicketType.other => 'Other',
  };
  static TicketType fromValue(String v) => switch (v) {
    'bug' => TicketType.bug,
    'question' => TicketType.question,
    'feature' => TicketType.feature,
    _ => TicketType.other,
  };
}

enum TicketStatus { open, inReview, resolved;
  String get value => switch (this) {
    TicketStatus.open => 'open',
    TicketStatus.inReview => 'in-review',
    TicketStatus.resolved => 'resolved',
  };
  String get label => switch (this) {
    TicketStatus.open => 'Open',
    TicketStatus.inReview => 'In Review',
    TicketStatus.resolved => 'Resolved',
  };
  static TicketStatus fromValue(String v) => switch (v) {
    'in-review' => TicketStatus.inReview,
    'resolved' => TicketStatus.resolved,
    _ => TicketStatus.open,
  };
}

class SupportTicket {
  final String id;
  final String name;
  final String email;
  final String subject;
  final String message;
  final TicketType type;
  final TicketStatus status;
  final String? adminNote;
  final List<String> imageUrls;
  final DateTime createdAt;

  const SupportTicket({
    required this.id,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    required this.type,
    required this.status,
    this.adminNote,
    this.imageUrls = const [],
    required this.createdAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: (json['id'] ?? json['_id']) as String,
        name: json['name'] as String,
        email: json['email'] as String,
        subject: json['subject'] as String,
        message: json['message'] as String,
        type: TicketType.fromValue(json['type'] as String? ?? ''),
        status: TicketStatus.fromValue(json['status'] as String? ?? ''),
        adminNote: json['adminNote'] as String?,
        imageUrls: (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
