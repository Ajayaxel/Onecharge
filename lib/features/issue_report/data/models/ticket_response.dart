class TicketResponse {
  TicketResponse({
    required this.message,
    required this.ticket,
  });

  final String message;
  final Ticket ticket;

  factory TicketResponse.fromJson(Map<String, dynamic> json) => TicketResponse(
        message: json['message'] as String? ?? '',
        ticket: Ticket.fromJson(
          json['ticket'] as Map<String, dynamic>? ?? {},
        ),
      );
}

class Ticket {
  const Ticket({
    required this.id,
    required this.category,
    required this.otherText,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.mediaPath,
  });

  final int id;
  final String category;
  final String? otherText;
  final String? mediaPath;
  final int userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as int? ?? 0,
      category: json['category'] as String? ?? '',
      otherText: json['other_text'] as String?,
      mediaPath: json['media_path'] as String?,
      userId: json['user_id'] as int? ?? 0,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

