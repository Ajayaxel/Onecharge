class TicketResponse {
  TicketResponse({
    required this.success,
    required this.message,
    required this.ticket,
    this.paymentRequired,
    this.paymentUrl,
    this.intentionId,
    this.clientSecret,
    this.paymentBreakdown,
  });

  final bool success;
  final String message;
  final Ticket ticket;
  final bool? paymentRequired;
  final String? paymentUrl;
  final String? intentionId;
  final String? clientSecret;
  final PaymentBreakdown? paymentBreakdown;

  factory TicketResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final paymentData = data?['payment_required'] == true ? data : null;
    
    PaymentBreakdown? paymentBreakdown;
    if (paymentData != null && paymentData['payment_breakdown'] != null) {
      paymentBreakdown = PaymentBreakdown.fromJson(
        paymentData['payment_breakdown'] as Map<String, dynamic>,
      );
    }
    
    return TicketResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      ticket: Ticket.fromJson(
        data?['ticket'] as Map<String, dynamic>? ?? {},
      ),
      paymentRequired: paymentData?['payment_required'] as bool?,
      paymentUrl: paymentData?['payment_url'] as String?,
      intentionId: paymentData?['intention_id'] as String?,
      clientSecret: paymentData?['client_secret'] as String?,
      paymentBreakdown: paymentBreakdown,
    );
  }
}

class PaymentBreakdown {
  PaymentBreakdown({
    required this.baseAmount,
    required this.vatAmount,
    required this.totalAmount,
    required this.currency,
    required this.discountApplied,
    required this.discountAmount,
    this.redeemCode,
  });

  final double baseAmount;
  final double vatAmount;
  final double totalAmount;
  final String currency;
  final bool discountApplied;
  final double discountAmount;
  final String? redeemCode;

  factory PaymentBreakdown.fromJson(Map<String, dynamic> json) {
    return PaymentBreakdown(
      baseAmount: (json['base_amount'] as num?)?.toDouble() ?? 0.0,
      vatAmount: (json['vat_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'AED',
      discountApplied: json['discount_applied'] as bool? ?? false,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      redeemCode: json['redeem_code'] as String?,
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
    this.driver,
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
  final DriverInfo? driver;

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

    // Parse driver information
    DriverInfo? driverInfo;
    if (json['driver'] != null && json['driver'] is Map) {
      driverInfo = DriverInfo.fromJson(json['driver'] as Map<String, dynamic>);
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
      driver: driverInfo,
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

class DriverInfo {
  const DriverInfo({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.lastLocationUpdatedAt,
  });

  final int id;
  final String name;
  final double? latitude;
  final double? longitude;
  final DateTime? lastLocationUpdatedAt;

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    double? lat;
    double? lng;
    
    // Handle latitude - can be string or number
    if (json['latitude'] != null) {
      if (json['latitude'] is num) {
        lat = (json['latitude'] as num).toDouble();
      } else if (json['latitude'] is String) {
        lat = double.tryParse(json['latitude'] as String);
      }
    }
    
    // Handle longitude - can be string or number
    if (json['longitude'] != null) {
      if (json['longitude'] is num) {
        lng = (json['longitude'] as num).toDouble();
      } else if (json['longitude'] is String) {
        lng = double.tryParse(json['longitude'] as String);
      }
    }

    return DriverInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      latitude: lat,
      longitude: lng,
      lastLocationUpdatedAt: json['last_location_updated_at'] != null
          ? DateTime.tryParse(json['last_location_updated_at'] as String)
          : null,
    );
  }
}

