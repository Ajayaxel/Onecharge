class TicketResponse {
  TicketResponse({
    required this.success,
    required this.message,
    required this.ticket,
  });

  final bool success;
  final String message;
  final Ticket ticket;

  factory TicketResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return TicketResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      ticket: Ticket.fromJson(
        data?['ticket'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class Ticket {
  const Ticket({
    required this.id,
    required this.ticketId,
    required this.customerId,
    required this.issueCategory,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String ticketId;
  final int customerId;
  final IssueCategoryInfo issueCategory;
  final String location;
  final String latitude;
  final String longitude;
  final String status;
  final List<String> attachments;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Ticket.fromJson(Map<String, dynamic> json) {
    // Parse issue_category
    IssueCategoryInfo? issueCategoryInfo;
    if (json['issue_category'] != null && json['issue_category'] is Map) {
      final categoryJson = json['issue_category'] as Map<String, dynamic>;
      issueCategoryInfo = IssueCategoryInfo(
        id: (categoryJson['id'] as num?)?.toInt() ?? 0,
        name: categoryJson['name'] as String? ?? '',
      );
    } else {
      issueCategoryInfo = const IssueCategoryInfo(id: 0, name: '');
    }

    // Parse attachments array
    List<String> attachmentsList = [];
    if (json['attachments'] != null && json['attachments'] is List) {
      attachmentsList = (json['attachments'] as List)
          .map((item) => item.toString())
          .toList();
    }

    return Ticket(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ticketId: json['ticket_id'] as String? ?? '',
      customerId: (json['customer_id'] as num?)?.toInt() ?? 0,
      issueCategory: issueCategoryInfo,
      location: json['location'] as String? ?? '',
      latitude: json['latitude'] as String? ?? '0',
      longitude: json['longitude'] as String? ?? '0',
      status: json['status'] as String? ?? 'pending',
      attachments: attachmentsList,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class IssueCategoryInfo {
  const IssueCategoryInfo({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;
}

