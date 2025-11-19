class LocationResponse {
  final bool success;
  final String? message;
  final LocationData? data;

  LocationResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory LocationResponse.fromJson(Map<String, dynamic> json) {
    return LocationResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null
          ? LocationData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class LocationData {
  final int? userId;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final int? id;

  LocationData({
    this.userId,
    required this.latitude,
    required this.longitude,
    this.address,
    this.updatedAt,
    this.createdAt,
    this.id,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      userId: json['user_id'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      address: json['address'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      id: json['id'] as int?,
    );
  }
}


