class DriverLocationResponse {
  DriverLocationResponse({
    required this.success,
    required this.data,
  });

  final bool success;
  final DriverLocationData data;

  factory DriverLocationResponse.fromJson(Map<String, dynamic> json) {
    return DriverLocationResponse(
      success: json['success'] as bool? ?? false,
      data: DriverLocationData.fromJson(
        json['data'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class DriverLocationData {
  DriverLocationData({
    required this.ticketId,
    required this.driver,
  });

  final int ticketId;
  final DriverLocation driver;

  factory DriverLocationData.fromJson(Map<String, dynamic> json) {
    return DriverLocationData(
      ticketId: (json['ticket_id'] as num?)?.toInt() ?? 0,
      driver: DriverLocation.fromJson(
        json['driver'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class DriverLocation {
  DriverLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.lastLocationUpdatedAt,
  });

  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final DateTime? lastLocationUpdatedAt;

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    double lat = 0;
    double lng = 0;
    
    // Handle latitude - can be string or number
    if (json['latitude'] != null) {
      if (json['latitude'] is num) {
        lat = (json['latitude'] as num).toDouble();
      } else if (json['latitude'] is String) {
        lat = double.tryParse(json['latitude'] as String) ?? 0;
      }
    }
    
    // Handle longitude - can be string or number
    if (json['longitude'] != null) {
      if (json['longitude'] is num) {
        lng = (json['longitude'] as num).toDouble();
      } else if (json['longitude'] is String) {
        lng = double.tryParse(json['longitude'] as String) ?? 0;
      }
    }

    return DriverLocation(
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

